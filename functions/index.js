// Trusted backend for NguyenInDoubt.
//
// ⚠️ SCAFFOLD — NOT YET VERIFIED. This was authored without a Node/Firebase
// toolchain available. It must be run against the Firebase emulator
// (`npm run serve`) and reviewed before any deploy. It also depends on the
// compliance-gated production Firebase project and an executed Google Cloud BAA
// (see docs/legal/hipaa_baa_analysis.md and .planning/GO-LIVE.md, Stage 3).
//
// These functions implement the operations the Firestore client cannot be
// trusted to do:
//   - acceptInvite:  atomically grant a clinician link only after server-side
//                    invite validation (the client cannot self-accept).
//   - deleteAccount: cascade-delete the caller's personal data, retain the
//                    consent audit trail, and remove the auth user.
//   - retentionSweep: scheduled purge of aged records per the retention policy.
//
// Collections mirror lib/repositories/firebase_app_repository.dart:
//   users, clinicianLinks, healthSamples, dailySummaries, journalEntries,
//   consentEvents. Link doc id = `${clinicianId}_${patientId}`.

import { initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { FieldValue, getFirestore } from 'firebase-admin/firestore';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { logger } from 'firebase-functions';

initializeApp();
const db = getFirestore();

const INVITE_PATTERN = /^NID-\d{4}$/;

function normalizeInviteCode(code) {
  return String(code ?? '').trim().toUpperCase();
}

function requireAuth(request) {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError('unauthenticated', 'Sign in required.');
  }
  return uid;
}

/**
 * Accept a clinician invite on behalf of the signed-in patient.
 * Validates the invite server-side, then atomically flips the link to
 * `accepted`, sets the patient's consent, and appends a consent event.
 *
 * data: { inviteCode: string }
 */
export const acceptInvite = onCall(async (request) => {
  const patientId = requireAuth(request);
  const inviteCode = normalizeInviteCode(request.data?.inviteCode);

  if (!INVITE_PATTERN.test(inviteCode)) {
    throw new HttpsError('invalid-argument', 'Invite codes use the format NID-1234.');
  }

  const linkSnap = await db
    .collection('clinicianLinks')
    .where('inviteCode', '==', inviteCode)
    .limit(1)
    .get();
  if (linkSnap.empty) {
    throw new HttpsError('not-found', 'No invite with that code was found.');
  }

  const linkRef = linkSnap.docs[0].ref;
  const userRef = db.collection('users').doc(patientId);
  const now = FieldValue.serverTimestamp();

  await db.runTransaction(async (tx) => {
    const [linkDoc, userDoc] = await Promise.all([tx.get(linkRef), tx.get(userRef)]);
    const link = linkDoc.data();

    if (!link || link.patientUserId !== patientId) {
      throw new HttpsError('permission-denied', 'This invite is for a different patient account.');
    }
    if (link.status !== 'pending') {
      throw new HttpsError('failed-precondition', `Invite is ${link.status}, not pending.`);
    }

    const previousStatus = userDoc.data()?.consentStatus ?? 'notAsked';

    tx.update(linkRef, { status: 'accepted', updatedAt: now });
    tx.set(
      userRef,
      { consentStatus: 'granted', clinicCode: inviteCode, updatedAt: now },
      { merge: true },
    );
    tx.set(db.collection('consentEvents').doc(), {
      patientUserId: patientId,
      clinicianUserId: link.clinicianUserId,
      inviteCode,
      previousStatus,
      nextStatus: 'granted',
      action: 'accepted',
      actorUserId: patientId,
      occurredAt: now,
    });
  });

  logger.info('Invite accepted', { patientId });
  return { status: 'accepted' };
});

/**
 * Delete the signed-in patient's account: cascade-delete personal data, end
 * active clinician sharing (retaining a consent audit event), remove the
 * profile, and delete the auth user. Consent history is intentionally retained.
 */
export const deleteAccount = onCall(async (request) => {
  const patientId = requireAuth(request);
  const now = FieldValue.serverTimestamp();

  const deleted = { journalEntries: 0, healthSamples: 0, dailySummaries: 0 };

  // Cascade-delete owned personal data. TODO: page in batches of <=500 for
  // accounts with large datasets (Firestore batch limit).
  for (const collection of ['journalEntries', 'healthSamples', 'dailySummaries']) {
    const snap = await db.collection(collection).where('userId', '==', patientId).get();
    const batch = db.batch();
    snap.docs.forEach((d) => batch.delete(d.ref));
    await batch.commit();
    deleted[collection] = snap.size;
  }

  // End active sharing; retain the audit trail with a revocation event.
  const acceptedLinks = await db
    .collection('clinicianLinks')
    .where('patientUserId', '==', patientId)
    .where('status', '==', 'accepted')
    .get();
  const linkBatch = db.batch();
  acceptedLinks.docs.forEach((d) => {
    linkBatch.update(d.ref, { status: 'revoked', updatedAt: now });
    linkBatch.set(db.collection('consentEvents').doc(), {
      patientUserId: patientId,
      clinicianUserId: d.data().clinicianUserId,
      inviteCode: d.data().inviteCode,
      previousStatus: 'granted',
      nextStatus: 'revoked',
      action: 'revoked',
      actorUserId: patientId,
      occurredAt: now,
    });
  });
  await linkBatch.commit();

  // Remove the profile and the auth user. Consent events are NOT deleted.
  await db.collection('users').doc(patientId).delete();
  await getAuth().deleteUser(patientId);

  logger.info('Account deleted', { patientId, deleted });
  // TODO: propagate deletion to backups per the retention policy / DPA.
  return { patientId, deleted, consentHistoryRetained: true };
});

/**
 * Scheduled retention sweep. Purges records older than each category's window.
 *
 * TODO: replace the placeholder windows with the finalized, counsel-approved
 * retention periods (see docs/legal/privacy_policy.md and
 * docs/production_posture.md). A null window means "retain indefinitely".
 */
const RETENTION_DAYS = {
  healthSamples: null, // e.g. 365 — TO CONFIRM
  dailySummaries: null, // e.g. 365 — TO CONFIRM
  journalEntries: null, // journals are the patient's; default: retain
};

export const retentionSweep = onSchedule('every 24 hours', async () => {
  const dateField = { healthSamples: 'createdAt', dailySummaries: 'date', journalEntries: 'createdAt' };
  let purged = 0;

  for (const [collection, days] of Object.entries(RETENTION_DAYS)) {
    if (days == null) continue;
    const cutoff = new Date(Date.now() - days * 24 * 60 * 60 * 1000);
    const snap = await db
      .collection(collection)
      .where(dateField[collection], '<', cutoff)
      .limit(500)
      .get();
    const batch = db.batch();
    snap.docs.forEach((d) => batch.delete(d.ref));
    await batch.commit();
    purged += snap.size;
  }

  logger.info('Retention sweep complete', { purged });
});
