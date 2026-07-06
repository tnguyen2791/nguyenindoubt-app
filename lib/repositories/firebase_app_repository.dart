import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_models.dart';
import '../services/health_data_provider.dart';
import 'app_repository.dart';

class FirebaseAppRepository
    implements AppRepository, ClinicianRepository, ConsentRepository {
  FirebaseAppRepository({required this.firestore, required this.auth});

  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  CollectionReference<Map<String, dynamic>> get _users =>
      firestore.collection('users');
  CollectionReference<Map<String, dynamic>> get _links =>
      firestore.collection('clinicianLinks');
  CollectionReference<Map<String, dynamic>> get _samples =>
      firestore.collection('healthSamples');
  CollectionReference<Map<String, dynamic>> get _summaries =>
      firestore.collection('dailySummaries');
  CollectionReference<Map<String, dynamic>> get _entries =>
      firestore.collection('journalEntries');
  CollectionReference<Map<String, dynamic>> get _resources =>
      firestore.collection('resourceCards');
  CollectionReference<Map<String, dynamic>> get _consentEvents =>
      firestore.collection('consentEvents');

  @override
  Future<List<ResourceCard>> getResourceCards() async {
    final snapshot = await _resources.orderBy('sortOrder').get();
    return snapshot.docs.map((doc) => _resourceFromDoc(doc)).toList();
  }

  @override
  Future<List<JournalEntry>> getJournalEntriesForPatient({
    required String requesterUserId,
    required String patientId,
  }) async {
    _requireSignedInAs(requesterUserId);
    _ensurePatientOwnsData(
      requesterUserId: requesterUserId,
      patientId: patientId,
      resourceName: 'journal entries',
    );

    final snapshot = await _entries
        .where('userId', isEqualTo: patientId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => _journalFromDoc(doc)).toList();
  }

  @override
  Future<void> addJournalEntry({
    required String requesterUserId,
    required JournalEntry entry,
  }) async {
    _requireSignedInAs(requesterUserId);
    _ensurePatientOwnsData(
      requesterUserId: requesterUserId,
      patientId: entry.userId,
      resourceName: 'journal entries',
    );

    await _entries.doc(entry.id).set(_journalToFirestore(entry));
  }

  @override
  Future<void> deleteJournalEntry({
    required String requesterUserId,
    required String entryId,
  }) async {
    _requireSignedInAs(requesterUserId);
    // The server-side `ownsDoc()` rule on journalEntries authoritatively
    // enforces that only the owning patient can delete. Journal stays
    // patient-only (SAFE-03) — there is deliberately no clinician path.
    await _entries.doc(entryId).delete();
  }

  @override
  Future<void> saveImportedSleep({
    required String requesterUserId,
    required String patientId,
    required List<HealthSample> samples,
  }) async {
    _requireSignedInAs(requesterUserId);
    _ensurePatientOwnsData(
      requesterUserId: requesterUserId,
      patientId: patientId,
      resourceName: 'sleep samples',
    );
    if (samples.any((sample) => sample.userId != patientId)) {
      throw const PrivacyException(
        'Imported sleep samples must belong to the patient.',
      );
    }

    final existingSnapshot = await _samples
        .where('userId', isEqualTo: patientId)
        .get();
    final mergedSamples = dedupeSleepSamples([
      ...existingSnapshot.docs
          .map((doc) => _sampleFromDoc(doc))
          .where((sample) => sample.metricType == MetricType.sleep),
      ...samples,
    ]);
    final batch = firestore.batch();
    for (final doc in existingSnapshot.docs) {
      final sample = _sampleFromDoc(doc);
      if (sample.metricType == MetricType.sleep &&
          doc.id != _sampleId(sample)) {
        batch.delete(doc.reference);
      }
    }
    for (final sample in mergedSamples) {
      batch.set(_samples.doc(_sampleId(sample)), _sampleToFirestore(sample));
    }
    for (final summary in summarizeSleepSamples(mergedSamples)) {
      batch.set(
        _summaries.doc(_summaryId(summary)),
        _summaryToFirestore(summary),
      );
    }
    await batch.commit();
  }

  @override
  Future<List<DailySummary>> getDailySummariesForPatient({
    required String requesterUserId,
    required String patientId,
  }) async {
    _requireSignedInAs(requesterUserId);
    _ensurePatientOwnsData(
      requesterUserId: requesterUserId,
      patientId: patientId,
      resourceName: 'daily summaries',
    );

    final snapshot = await _summaries
        .where('userId', isEqualTo: patientId)
        .orderBy('date')
        .get();
    return snapshot.docs.map((doc) => _summaryFromDoc(doc)).toList();
  }

  @override
  Future<InviteValidationResult> validateInviteCode({
    required String patientId,
    required String inviteCode,
  }) async {
    _requireSignedInAs(patientId);
    final normalized = _normalizeInviteCode(inviteCode);
    if (normalized.isEmpty) {
      return const InviteValidationResult(
        status: InviteValidationStatus.empty,
        normalizedCode: '',
        message: 'Enter an invite code before validating.',
      );
    }
    if (!_invitePattern.hasMatch(normalized)) {
      return InviteValidationResult(
        status: InviteValidationStatus.malformed,
        normalizedCode: normalized,
        message: 'Invite codes use the format NID-1234.',
      );
    }

    final snapshot = await _links
        .where('inviteCode', isEqualTo: normalized)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) {
      return InviteValidationResult(
        status: InviteValidationStatus.missing,
        normalizedCode: normalized,
        message: 'No invite with that code was found.',
      );
    }

    final link = snapshot.docs.first.data();
    final linkPatientId = link['patientUserId'] as String;
    final clinicianId = link['clinicianUserId'] as String;
    final clinicianDoc = await _users.doc(clinicianId).get();
    final clinicianName = clinicianDoc.data()?['displayName'] as String?;
    if (linkPatientId != patientId) {
      return InviteValidationResult(
        status: InviteValidationStatus.wrongPatient,
        normalizedCode: normalized,
        patientUserId: linkPatientId,
        clinicianUserId: clinicianId,
        clinicianDisplayName: clinicianName,
        message: 'This invite is for a different patient account.',
      );
    }

    final status = LinkStatus.values.byName(link['status'] as String);
    return switch (status) {
      LinkStatus.pending => InviteValidationResult(
        status: InviteValidationStatus.valid,
        normalizedCode: normalized,
        patientUserId: linkPatientId,
        clinicianUserId: clinicianId,
        clinicianDisplayName: clinicianName,
        message: 'Invite validated. Review sharing before accepting.',
      ),
      LinkStatus.accepted => InviteValidationResult(
        status: InviteValidationStatus.alreadyAccepted,
        normalizedCode: normalized,
        patientUserId: linkPatientId,
        clinicianUserId: clinicianId,
        clinicianDisplayName: clinicianName,
        message: 'This invite is already accepted.',
      ),
      LinkStatus.revoked => InviteValidationResult(
        status: InviteValidationStatus.revoked,
        normalizedCode: normalized,
        patientUserId: linkPatientId,
        clinicianUserId: clinicianId,
        clinicianDisplayName: clinicianName,
        message: 'This invite was revoked and cannot be reused.',
      ),
      LinkStatus.expired => InviteValidationResult(
        status: InviteValidationStatus.expired,
        normalizedCode: normalized,
        patientUserId: linkPatientId,
        clinicianUserId: clinicianId,
        clinicianDisplayName: clinicianName,
        message: 'This invite has expired. Ask for a new code.',
      ),
    };
  }

  @override
  Future<AppUser> acceptInvite({
    required String patientId,
    required String inviteCode,
  }) async {
    _requireSignedInAs(patientId);
    throw const PrivacyException(
      'Invite acceptance requires a trusted backend operation in Firebase mode.',
    );
  }

  @override
  Future<AppUser> revokeConsent({required String patientId}) async {
    _requireSignedInAs(patientId);
    final acceptedLinks = await _links
        .where('patientUserId', isEqualTo: patientId)
        .where('status', isEqualTo: LinkStatus.accepted.name)
        .limit(1)
        .get();
    if (acceptedLinks.docs.isEmpty) {
      throw const PrivacyException('No active clinician link to revoke.');
    }

    final userDoc = await _users.doc(patientId).get();
    if (!userDoc.exists) {
      throw const PrivacyException('Patient profile was not found.');
    }
    final previous = _userFromDoc(userDoc);
    final linkDoc = acceptedLinks.docs.first;
    final link = linkDoc.data();
    final now = DateTime.now();
    final batch = firestore.batch();
    batch.update(userDoc.reference, {
      'consentStatus': ConsentStatus.revoked.name,
      'clinicCode': null,
      'updatedAt': Timestamp.fromDate(now),
    });
    batch.update(linkDoc.reference, {
      'status': LinkStatus.revoked.name,
      'updatedAt': Timestamp.fromDate(now),
    });
    batch.set(
      _consentEvents.doc('consent-${now.microsecondsSinceEpoch}'),
      _consentEventToFirestore(
        ConsentHistoryEvent(
          id: 'consent-${now.microsecondsSinceEpoch}',
          patientUserId: patientId,
          clinicianUserId: link['clinicianUserId'] as String,
          inviteCode: link['inviteCode'] as String,
          previousStatus: previous.consentStatus,
          nextStatus: ConsentStatus.revoked,
          action: ConsentEventAction.revoked,
          actorUserId: patientId,
          occurredAt: now,
        ),
      ),
    );
    await batch.commit();

    return previous.copyWith(
      consentStatus: ConsentStatus.revoked,
      clearClinicCode: true,
    );
  }

  @override
  Future<List<ConsentHistoryEvent>> getConsentHistory({
    required String patientId,
  }) async {
    _requireSignedInAs(patientId);
    final snapshot = await _consentEvents
        .where('patientUserId', isEqualTo: patientId)
        .orderBy('occurredAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => _consentEventFromDoc(doc)).toList();
  }

  @override
  Future<List<AppUser>> getLinkedPatients(String clinicianId) async {
    _requireSignedInAs(clinicianId);
    final linkSnapshot = await _links
        .where('clinicianUserId', isEqualTo: clinicianId)
        .where('status', isEqualTo: LinkStatus.accepted.name)
        .get();

    final patients = <AppUser>[];
    for (final link in linkSnapshot.docs) {
      final patientId = link.data()['patientUserId'] as String;
      final userDoc = await _users.doc(patientId).get();
      if (!userDoc.exists) {
        continue;
      }
      final patient = _userFromDoc(userDoc);
      if (patient.role == UserRole.patient &&
          patient.consentStatus == ConsentStatus.granted) {
        patients.add(patient);
      }
    }
    return patients;
  }

  @override
  Future<List<ClinicianLinkStatusView>> getClinicianLinkStatuses(
    String clinicianId,
  ) async {
    _requireSignedInAs(clinicianId);
    final snapshot = await _links
        .where('clinicianUserId', isEqualTo: clinicianId)
        .get();
    final statuses = <ClinicianLinkStatusView>[];
    for (final link in snapshot.docs) {
      final data = link.data();
      final patientId = data['patientUserId'] as String;
      final patientDoc = await _users.doc(patientId).get();
      statuses.add(
        ClinicianLinkStatusView(
          patientUserId: patientId,
          patientDisplayName: patientDoc.data()?['displayName'] as String?,
          inviteCode: data['inviteCode'] as String,
          status: LinkStatus.values.byName(data['status'] as String),
          updatedAt: _dateTime(data['updatedAt']),
        ),
      );
    }
    statuses.sort(_compareClinicianLinkStatus);
    return statuses;
  }

  @override
  Future<PatientSleepBundle> getPatientSleepSummary({
    required String clinicianId,
    required String patientId,
  }) async {
    _requireSignedInAs(clinicianId);
    final link = await _links.doc(_linkId(clinicianId, patientId)).get();
    if (!link.exists || link.data()?['status'] != LinkStatus.accepted.name) {
      throw const PrivacyException(
        'No accepted clinician link for this patient.',
      );
    }

    final patientDoc = await _users.doc(patientId).get();
    if (!patientDoc.exists) {
      throw const PrivacyException('Linked patient was not found.');
    }

    final summarySnapshot = await _summaries
        .where('userId', isEqualTo: patientId)
        .orderBy('date')
        .get();
    final sampleSnapshot = await _samples
        .where('userId', isEqualTo: patientId)
        .orderBy('start')
        .get();

    final patient = _userFromDoc(patientDoc);
    if (patient.consentStatus != ConsentStatus.granted) {
      throw const PrivacyException(
        'Patient has not granted active sleep sharing.',
      );
    }

    return PatientSleepBundle(
      patient: patient,
      summaries: summarySnapshot.docs
          .map((doc) => _summaryFromDoc(doc))
          .toList(),
      samples: sampleSnapshot.docs.map((doc) => _sampleFromDoc(doc)).toList(),
    );
  }

  void _requireSignedInAs(String userId) {
    final uid = auth.currentUser?.uid;
    if (uid != userId) {
      throw PrivacyException('Expected signed-in user $userId.');
    }
  }

  void _ensurePatientOwnsData({
    required String requesterUserId,
    required String patientId,
    required String resourceName,
  }) {
    if (requesterUserId != patientId) {
      throw PrivacyException(
        'Only the patient can access their own $resourceName.',
      );
    }
  }
}

String _linkId(String clinicianId, String patientId) =>
    '${clinicianId}_$patientId';

String _sampleId(HealthSample sample) {
  return [
    sample.userId,
    sample.metricType.name,
    _docSafe(sample.source),
    sample.start.millisecondsSinceEpoch,
    sample.end.millisecondsSinceEpoch,
  ].join('_');
}

String _docSafe(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}

String _summaryId(DailySummary summary) {
  final date = summary.date;
  final yyyy = date.year.toString().padLeft(4, '0');
  final mm = date.month.toString().padLeft(2, '0');
  final dd = date.day.toString().padLeft(2, '0');
  return '${summary.userId}_$yyyy$mm$dd';
}

final _invitePattern = RegExp(r'^NID-\d{4}$');

String _normalizeInviteCode(String inviteCode) =>
    inviteCode.trim().toUpperCase();

int _compareClinicianLinkStatus(
  ClinicianLinkStatusView a,
  ClinicianLinkStatusView b,
) {
  final byStatus = _linkStatusSortOrder(
    a.status,
  ).compareTo(_linkStatusSortOrder(b.status));
  if (byStatus != 0) {
    return byStatus;
  }
  return b.updatedAt.compareTo(a.updatedAt);
}

int _linkStatusSortOrder(LinkStatus status) {
  return switch (status) {
    LinkStatus.accepted => 0,
    LinkStatus.pending => 1,
    LinkStatus.revoked => 2,
    LinkStatus.expired => 3,
  };
}

AppUser _userFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
  final data = doc.data()!;
  return AppUser(
    id: doc.id,
    displayName: data['displayName'] as String,
    role: UserRole.values.byName(data['role'] as String),
    consentStatus: ConsentStatus.values.byName(data['consentStatus'] as String),
    clinicCode: data['clinicCode'] as String?,
  );
}

JournalEntry _journalFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
  final data = doc.data()!;
  return JournalEntry(
    id: doc.id,
    userId: data['userId'] as String,
    title: data['title'] as String,
    body: data['body'] as String,
    moodTag: data['moodTag'] as String?,
    createdAt: _dateTime(data['createdAt']),
    privateByDefault: data['privateByDefault'] as bool? ?? true,
  );
}

Map<String, Object?> _journalToFirestore(JournalEntry entry) {
  return {
    'userId': entry.userId,
    'title': entry.title,
    'body': entry.body,
    'moodTag': entry.moodTag,
    'createdAt': Timestamp.fromDate(entry.createdAt),
    'privateByDefault': entry.privateByDefault,
  };
}

HealthSample _sampleFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
  final data = doc.data()!;
  return HealthSample(
    userId: data['userId'] as String,
    source: data['source'] as String,
    metricType: MetricType.values.byName(data['metricType'] as String),
    start: _dateTime(data['start']),
    end: _dateTime(data['end']),
    value: (data['value'] as num).toDouble(),
    unit: data['unit'] as String,
    createdAt: _dateTime(data['createdAt']),
  );
}

Map<String, Object?> _sampleToFirestore(HealthSample sample) {
  return {
    'userId': sample.userId,
    'source': sample.source,
    'metricType': sample.metricType.name,
    'start': Timestamp.fromDate(sample.start),
    'end': Timestamp.fromDate(sample.end),
    'value': sample.value,
    'unit': sample.unit,
    'createdAt': Timestamp.fromDate(sample.createdAt),
  };
}

DailySummary _summaryFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
  final data = doc.data()!;
  return DailySummary(
    userId: data['userId'] as String,
    date: _dateTime(data['date']),
    sleepDurationHours: (data['sleepDurationHours'] as num).toDouble(),
    sleepQualityProxy: data['sleepQualityProxy'] as int,
    trendFlag: data['trendFlag'] as String,
  );
}

Map<String, Object?> _summaryToFirestore(DailySummary summary) {
  return {
    'userId': summary.userId,
    'date': Timestamp.fromDate(summary.date),
    'sleepDurationHours': summary.sleepDurationHours,
    'sleepQualityProxy': summary.sleepQualityProxy,
    'trendFlag': summary.trendFlag,
  };
}

ResourceCard _resourceFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
  final data = doc.data()!;
  return ResourceCard(
    id: doc.id,
    title: data['title'] as String,
    category: data['category'] as String,
    body: data['body'] as String,
    disclaimer: data['disclaimer'] as String,
    crisisFlag: data['crisisFlag'] as bool? ?? false,
    sortOrder: data['sortOrder'] as int,
  );
}

ConsentHistoryEvent _consentEventFromDoc(
  DocumentSnapshot<Map<String, dynamic>> doc,
) {
  final data = doc.data()!;
  return ConsentHistoryEvent(
    id: doc.id,
    patientUserId: data['patientUserId'] as String,
    clinicianUserId: data['clinicianUserId'] as String,
    inviteCode: data['inviteCode'] as String,
    previousStatus: ConsentStatus.values.byName(
      data['previousStatus'] as String,
    ),
    nextStatus: ConsentStatus.values.byName(data['nextStatus'] as String),
    action: ConsentEventAction.values.byName(data['action'] as String),
    actorUserId: data['actorUserId'] as String,
    occurredAt: _dateTime(data['occurredAt']),
  );
}

Map<String, Object?> _consentEventToFirestore(ConsentHistoryEvent event) {
  return {
    'patientUserId': event.patientUserId,
    'clinicianUserId': event.clinicianUserId,
    'inviteCode': event.inviteCode,
    'previousStatus': event.previousStatus.name,
    'nextStatus': event.nextStatus.name,
    'action': event.action.name,
    'actorUserId': event.actorUserId,
    'occurredAt': Timestamp.fromDate(event.occurredAt),
  };
}

DateTime _dateTime(Object? value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    return DateTime.parse(value);
  }
  throw StateError('Unsupported timestamp value: $value');
}
