import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_models.dart';
import '../services/health_data_provider.dart';
import 'app_repository.dart';

class FirebaseAppRepository implements AppRepository, ClinicianRepository {
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

    final existingSamples = await _samples
        .where('userId', isEqualTo: patientId)
        .get();
    final existingSummaries = await _summaries
        .where('userId', isEqualTo: patientId)
        .get();
    final batch = firestore.batch();
    for (final doc in existingSamples.docs) {
      batch.delete(doc.reference);
    }
    for (final doc in existingSummaries.docs) {
      batch.delete(doc.reference);
    }
    for (final sample in samples) {
      batch.set(_samples.doc(_sampleId(sample)), _sampleToFirestore(sample));
    }
    for (final summary in summarizeSleepSamples(samples)) {
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

    return PatientSleepBundle(
      patient: _userFromDoc(patientDoc),
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

String _sampleId(HealthSample sample) =>
    '${sample.userId}_${sample.start.millisecondsSinceEpoch}';

String _summaryId(DailySummary summary) {
  final date = summary.date;
  final yyyy = date.year.toString().padLeft(4, '0');
  final mm = date.month.toString().padLeft(2, '0');
  final dd = date.day.toString().padLeft(2, '0');
  return '${summary.userId}_$yyyy$mm$dd';
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
