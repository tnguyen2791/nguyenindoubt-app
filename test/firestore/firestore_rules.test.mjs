import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { readFileSync } from 'node:fs';
import {
  deleteDoc,
  doc,
  getDoc,
  setDoc,
  updateDoc,
} from 'firebase/firestore';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';

const projectId = 'nguyenindoubt-demo';

let testEnv;

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId,
    firestore: {
      host: '127.0.0.1',
      port: 8085,
      rules: readFileSync('firestore.rules', 'utf8'),
    },
  });
});

beforeEach(async () => {
  await testEnv.clearFirestore();
});

afterAll(async () => {
  await testEnv.cleanup();
});

describe('firestore privacy rules', () => {
  it('keeps journals patient-owned', async () => {
    await seedBaseData({ linkStatus: 'accepted' });

    const patientDb = authedDb('patient-a');
    const otherPatientDb = authedDb('patient-b');
    const clinicianDb = authedDb('clinician-a', { role: 'clinician' });

    await assertSucceeds(getDoc(doc(patientDb, 'journalEntries/journal-a')));
    await assertFails(getDoc(doc(otherPatientDb, 'journalEntries/journal-a')));
    await assertFails(getDoc(doc(clinicianDb, 'journalEntries/journal-a')));
    await assertSucceeds(
      setDoc(doc(patientDb, 'journalEntries/journal-new'), {
        userId: 'patient-a',
        title: 'New note',
        body: 'Private body.',
        createdAt: new Date('2026-01-02T08:00:00.000Z'),
        privateByDefault: true,
      }),
    );
    await assertFails(
      setDoc(doc(clinicianDb, 'journalEntries/journal-clinician'), {
        userId: 'patient-a',
        title: 'Invalid note',
        body: 'Should not write.',
        createdAt: new Date('2026-01-02T08:00:00.000Z'),
        privateByDefault: true,
      }),
    );
  });

  it('allows clinician sleep reads only for accepted links', async () => {
    const clinicianDb = authedDb('clinician-a', { role: 'clinician' });

    await seedBaseData({ linkStatus: 'accepted' });
    await assertSucceeds(getDoc(doc(clinicianDb, 'users/patient-a')));
    await assertSucceeds(getDoc(doc(clinicianDb, 'healthSamples/sample-a')));
    await assertSucceeds(getDoc(doc(clinicianDb, 'dailySummaries/summary-a')));
    await assertFails(getDoc(doc(clinicianDb, 'journalEntries/journal-a')));

    await seedBaseData({ linkStatus: 'pending' });
    await assertFails(getDoc(doc(clinicianDb, 'healthSamples/sample-a')));
    await assertFails(getDoc(doc(clinicianDb, 'dailySummaries/summary-a')));

    await seedBaseData({ linkStatus: 'revoked' });
    await assertFails(getDoc(doc(clinicianDb, 'healthSamples/sample-a')));
    await assertFails(getDoc(doc(clinicianDb, 'dailySummaries/summary-a')));

    await seedBaseData({ linkStatus: 'expired' });
    await assertFails(getDoc(doc(clinicianDb, 'healthSamples/sample-a')));
    await assertFails(getDoc(doc(clinicianDb, 'dailySummaries/summary-a')));

    await seedBaseData({ linkStatus: null });
    await assertFails(getDoc(doc(clinicianDb, 'healthSamples/sample-a')));
    await assertFails(getDoc(doc(clinicianDb, 'dailySummaries/summary-a')));

    await seedBaseData({ linkStatus: 'accepted', malformedLink: true });
    await assertFails(getDoc(doc(clinicianDb, 'healthSamples/sample-a')));
    await assertFails(getDoc(doc(clinicianDb, 'dailySummaries/summary-a')));
  });

  it('requires a clinician auth claim for accepted-link sleep reads', async () => {
    await seedBaseData({ linkStatus: 'accepted' });

    const unclaimedDb = authedDb('clinician-a');
    await assertFails(getDoc(doc(unclaimedDb, 'healthSamples/sample-a')));
    await assertFails(getDoc(doc(unclaimedDb, 'dailySummaries/summary-a')));
  });

  it('keeps clinician link writes trusted', async () => {
    await seedBaseData({ linkStatus: 'pending' });

    const clinicianDb = authedDb('clinician-a', { role: 'clinician' });
    const patientDb = authedDb('patient-a');
    const adminDb = authedDb('admin-a', { admin: true });

    await assertFails(
      setDoc(doc(clinicianDb, 'clinicianLinks/clinician-a_patient-a'), {
        clinicianUserId: 'clinician-a',
        patientUserId: 'patient-a',
        inviteCode: 'NID-0001',
        status: 'accepted',
        createdAt: new Date('2026-01-01T08:00:00.000Z'),
        updatedAt: new Date('2026-01-01T08:00:00.000Z'),
      }),
    );
    await assertFails(
      updateDoc(doc(patientDb, 'clinicianLinks/clinician-a_patient-a'), {
        status: 'accepted',
        updatedAt: new Date('2026-01-01T09:00:00.000Z'),
      }),
    );
    await assertSucceeds(
      setDoc(doc(adminDb, 'clinicianLinks/clinician-a_patient-a'), {
        clinicianUserId: 'clinician-a',
        patientUserId: 'patient-a',
        inviteCode: 'NID-0001',
        status: 'accepted',
        createdAt: new Date('2026-01-01T08:00:00.000Z'),
        updatedAt: new Date('2026-01-01T09:00:00.000Z'),
      }),
    );

    await seedBaseData({ linkStatus: 'accepted' });
    await assertSucceeds(
      updateDoc(doc(patientDb, 'clinicianLinks/clinician-a_patient-a'), {
        status: 'revoked',
        updatedAt: new Date('2026-01-01T10:00:00.000Z'),
      }),
    );
    await assertFails(getDoc(doc(clinicianDb, 'healthSamples/sample-a')));
  });

  it('keeps consent history append-only and metadata-only', async () => {
    await seedBaseData({ linkStatus: 'accepted' });

    const patientDb = authedDb('patient-a');
    const adminDb = authedDb('admin-a', { admin: true });

    await assertSucceeds(
      setDoc(doc(adminDb, 'consentEvents/event-accepted'), {
        patientUserId: 'patient-a',
        clinicianUserId: 'clinician-a',
        inviteCode: 'NID-0001',
        previousStatus: 'notAsked',
        nextStatus: 'granted',
        action: 'accepted',
        actorUserId: 'admin-a',
        occurredAt: new Date('2026-01-01T09:00:00.000Z'),
      }),
    );
    await assertSucceeds(
      setDoc(doc(patientDb, 'consentEvents/event-revoked'), {
        patientUserId: 'patient-a',
        clinicianUserId: 'clinician-a',
        inviteCode: 'NID-0001',
        previousStatus: 'granted',
        nextStatus: 'revoked',
        action: 'revoked',
        actorUserId: 'patient-a',
        occurredAt: new Date('2026-01-01T10:00:00.000Z'),
      }),
    );
    await assertFails(
      setDoc(doc(patientDb, 'consentEvents/event-raw-journal'), {
        patientUserId: 'patient-a',
        clinicianUserId: 'clinician-a',
        inviteCode: 'NID-0001',
        previousStatus: 'granted',
        nextStatus: 'revoked',
        action: 'revoked',
        actorUserId: 'patient-a',
        occurredAt: new Date('2026-01-01T10:00:00.000Z'),
        journalBody: 'Private reflection.',
      }),
    );
    await assertFails(
      setDoc(doc(patientDb, 'consentEvents/event-raw-sleep'), {
        patientUserId: 'patient-a',
        clinicianUserId: 'clinician-a',
        inviteCode: 'NID-0001',
        previousStatus: 'granted',
        nextStatus: 'revoked',
        action: 'revoked',
        actorUserId: 'patient-a',
        occurredAt: new Date('2026-01-01T10:00:00.000Z'),
        sleepSamples: [{ value: 7 }],
      }),
    );
    await assertFails(
      setDoc(doc(patientDb, 'consentEvents/event-self-accepted'), {
        patientUserId: 'patient-a',
        clinicianUserId: 'clinician-a',
        inviteCode: 'NID-0001',
        previousStatus: 'notAsked',
        nextStatus: 'granted',
        action: 'accepted',
        actorUserId: 'patient-a',
        occurredAt: new Date('2026-01-01T09:00:00.000Z'),
      }),
    );
    await assertFails(
      updateDoc(doc(adminDb, 'consentEvents/event-accepted'), {
        action: 'revoked',
      }),
    );
  });

  it('keeps resource cards public read and admin-only write', async () => {
    await seedBaseData({ linkStatus: 'accepted' });

    const publicDb = testEnv.unauthenticatedContext().firestore();
    const patientDb = authedDb('patient-a');
    const adminDb = authedDb('admin-a', { admin: true });

    await assertSucceeds(getDoc(doc(publicDb, 'resourceCards/sleep-basics')));
    await assertFails(
      setDoc(doc(patientDb, 'resourceCards/new-card'), {
        title: 'Invalid',
        category: 'Sleep',
        body: 'Should not write.',
        disclaimer: 'No.',
        crisisFlag: false,
        sortOrder: 10,
      }),
    );
    await assertSucceeds(
      setDoc(doc(adminDb, 'resourceCards/new-card'), {
        title: 'Admin card',
        category: 'Sleep',
        body: 'Allowed admin write.',
        disclaimer: 'Educational only.',
        crisisFlag: false,
        sortOrder: 10,
      }),
    );
  });

  it('prevents deletes for users, links, and resource cards', async () => {
    await seedBaseData({ linkStatus: 'accepted' });

    const patientDb = authedDb('patient-a');
    const adminDb = authedDb('admin-a', { admin: true });

    await assertFails(deleteDoc(doc(patientDb, 'users/patient-a')));
    await assertFails(deleteDoc(doc(adminDb, 'clinicianLinks/clinician-a_patient-a')));
    await assertFails(deleteDoc(doc(adminDb, 'resourceCards/sleep-basics')));
  });
});

function authedDb(uid, token = {}) {
  return testEnv.authenticatedContext(uid, token).firestore();
}

async function seedBaseData({ linkStatus, malformedLink = false }) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, 'users/patient-a'), {
      displayName: 'Alex Patient',
      role: 'patient',
      consentStatus: 'granted',
      clinicCode: 'NID-0001',
    });
    await setDoc(doc(db, 'users/patient-b'), {
      displayName: 'Blair Patient',
      role: 'patient',
      consentStatus: 'notAsked',
    });
    await setDoc(doc(db, 'users/clinician-a'), {
      displayName: 'Dr. Nguyen',
      role: 'clinician',
      consentStatus: 'notAsked',
    });
    await deleteDoc(doc(db, 'clinicianLinks/clinician-a_patient-a'));
    if (linkStatus != null) {
      await setDoc(doc(db, 'clinicianLinks/clinician-a_patient-a'), {
        clinicianUserId: 'clinician-a',
        patientUserId: malformedLink ? 'patient-b' : 'patient-a',
        inviteCode: 'NID-0001',
        status: linkStatus,
        createdAt: new Date('2026-01-01T08:00:00.000Z'),
        updatedAt: new Date('2026-01-01T08:00:00.000Z'),
      });
    }
    await setDoc(doc(db, 'healthSamples/sample-a'), {
      userId: 'patient-a',
      source: 'Apple Health mock',
      metricType: 'sleep',
      start: new Date('2026-01-01T00:00:00.000Z'),
      end: new Date('2026-01-01T07:00:00.000Z'),
      value: 7,
      unit: 'hours',
      createdAt: new Date('2026-01-01T08:00:00.000Z'),
    });
    await setDoc(doc(db, 'dailySummaries/summary-a'), {
      userId: 'patient-a',
      date: new Date('2026-01-01T00:00:00.000Z'),
      sleepDurationHours: 7,
      sleepQualityProxy: 82,
      trendFlag: 'steady',
    });
    await setDoc(doc(db, 'journalEntries/journal-a'), {
      userId: 'patient-a',
      title: 'Private note',
      body: 'Journal body.',
      moodTag: 'steady',
      createdAt: new Date('2026-01-01T08:00:00.000Z'),
      privateByDefault: true,
    });
    await setDoc(doc(db, 'resourceCards/sleep-basics'), {
      title: 'Sleep is data, not a verdict',
      category: 'Sleep',
      body: 'Look for patterns.',
      disclaimer: 'Educational only.',
      crisisFlag: false,
      sortOrder: 1,
    });
  });
}
