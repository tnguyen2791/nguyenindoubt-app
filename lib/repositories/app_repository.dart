import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/seed_data.dart';
import '../models/app_models.dart';
import '../services/health_data_provider.dart';

abstract class AppRepository {
  Future<List<ResourceCard>> getResourceCards();

  Future<List<JournalEntry>> getJournalEntries(String userId);

  Future<void> addJournalEntry(JournalEntry entry);

  Future<void> saveImportedSleep({
    required String userId,
    required List<HealthSample> samples,
  });

  Future<List<DailySummary>> getDailySummaries(String userId);
}

abstract class ClinicianRepository {
  Future<List<AppUser>> getLinkedPatients(String clinicianId);

  Future<PatientSleepBundle> getPatientSleepSummary({
    required String clinicianId,
    required String patientId,
  });

  Future<List<JournalEntry>> getPatientJournalEntries({
    required String clinicianId,
    required String patientId,
  });
}

class PrivacyException implements Exception {
  const PrivacyException(this.message);

  final String message;

  @override
  String toString() => message;
}

class InMemoryAppRepository implements AppRepository, ClinicianRepository {
  InMemoryAppRepository({
    this.preferences,
    this.storageKey = _defaultStorageKey,
  }) {
    final savedJson = preferences?.getString(storageKey);
    if (savedJson != null && _restore(savedJson)) {
      _resources.addAll(seedResources);
      return;
    }

    _seedDemoData();
  }

  static const _defaultStorageKey = 'nguyenindoubt.local_demo.v1';

  final SharedPreferences? preferences;
  final String storageKey;

  final List<AppUser> _users = [];
  final List<ClinicianLink> _links = [];
  final List<HealthSample> _samples = [];
  final List<DailySummary> _summaries = [];
  final List<JournalEntry> _entries = [];
  final List<ResourceCard> _resources = [];

  void _seedDemoData() {
    _users
      ..clear()
      ..addAll([demoPatient, linkedPatient, demoClinician]);
    _links
      ..clear()
      ..addAll(seedClinicianLinks());
    _samples
      ..clear()
      ..addAll(seedLinkedSleepSamples());
    _summaries
      ..clear()
      ..addAll(summarizeSleepSamples(_samples));
    _entries
      ..clear()
      ..addAll(seedJournalEntries());
    _resources
      ..clear()
      ..addAll(seedResources);
  }

  bool _restore(String savedJson) {
    try {
      final decoded = jsonDecode(savedJson) as Map<String, Object?>;
      _users
        ..clear()
        ..addAll(
          (decoded['users'] as List<dynamic>).map(
            (json) => _userFromJson(json as Map<String, Object?>),
          ),
        );
      _links
        ..clear()
        ..addAll(
          (decoded['links'] as List<dynamic>).map(
            (json) => _linkFromJson(json as Map<String, Object?>),
          ),
        );
      _samples
        ..clear()
        ..addAll(
          (decoded['samples'] as List<dynamic>).map(
            (json) => _sampleFromJson(json as Map<String, Object?>),
          ),
        );
      _summaries
        ..clear()
        ..addAll(summarizeSleepSamples(_samples));
      _entries
        ..clear()
        ..addAll(
          (decoded['entries'] as List<dynamic>).map(
            (json) => _entryFromJson(json as Map<String, Object?>),
          ),
        );
      return _users.isNotEmpty;
    } on Object {
      _users.clear();
      _links.clear();
      _samples.clear();
      _summaries.clear();
      _entries.clear();
      return false;
    }
  }

  Future<void> _persist() async {
    final localPreferences = preferences;
    if (localPreferences == null) {
      return;
    }

    await localPreferences.setString(
      storageKey,
      jsonEncode({
        'schemaVersion': 1,
        'users': _users.map(_userToJson).toList(),
        'links': _links.map(_linkToJson).toList(),
        'samples': _samples.map(_sampleToJson).toList(),
        'entries': _entries.map(_entryToJson).toList(),
      }),
    );
  }

  AppUser get patientDemo =>
      _users.firstWhere((user) => user.id == demoPatient.id);

  AppUser get clinicianDemo =>
      _users.firstWhere((user) => user.id == demoClinician.id);

  Future<AppUser> grantPatientConsent(
    String patientId,
    String inviteCode,
  ) async {
    final index = _users.indexWhere((user) => user.id == patientId);
    final updated = _users[index].copyWith(
      consentStatus: ConsentStatus.granted,
      clinicCode: inviteCode,
    );
    _users[index] = updated;

    final linkIndex = _links.indexWhere(
      (link) =>
          link.patientUserId == patientId && link.inviteCode == inviteCode,
    );
    final now = DateTime.now();
    if (linkIndex >= 0) {
      final existing = _links[linkIndex];
      _links[linkIndex] = ClinicianLink(
        inviteCode: existing.inviteCode,
        clinicianUserId: existing.clinicianUserId,
        patientUserId: existing.patientUserId,
        status: LinkStatus.accepted,
        createdAt: existing.createdAt,
        updatedAt: now,
      );
    }
    await _persist();
    return updated;
  }

  @override
  Future<void> addJournalEntry(JournalEntry entry) async {
    _entries.insert(0, entry);
    await _persist();
  }

  @override
  Future<List<DailySummary>> getDailySummaries(String userId) async {
    return _summaries.where((summary) => summary.userId == userId).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  @override
  Future<List<JournalEntry>> getJournalEntries(String userId) async {
    return _entries.where((entry) => entry.userId == userId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<List<ResourceCard>> getResourceCards() async {
    return _resources.toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  @override
  Future<void> saveImportedSleep({
    required String userId,
    required List<HealthSample> samples,
  }) async {
    _samples.removeWhere((sample) => sample.userId == userId);
    _summaries.removeWhere((summary) => summary.userId == userId);
    _samples.addAll(samples);
    _summaries.addAll(summarizeSleepSamples(samples));
    await _persist();
  }

  @override
  Future<List<AppUser>> getLinkedPatients(String clinicianId) async {
    final patientIds = _links
        .where(
          (link) =>
              link.clinicianUserId == clinicianId &&
              link.status == LinkStatus.accepted,
        )
        .map((link) => link.patientUserId)
        .toSet();

    return _users
        .where(
          (user) =>
              patientIds.contains(user.id) &&
              user.role == UserRole.patient &&
              user.consentStatus == ConsentStatus.granted,
        )
        .toList();
  }

  @override
  Future<PatientSleepBundle> getPatientSleepSummary({
    required String clinicianId,
    required String patientId,
  }) async {
    if (!_hasAcceptedLink(clinicianId, patientId)) {
      throw const PrivacyException(
        'No accepted clinician link for this patient.',
      );
    }

    final patient = _users.firstWhere((user) => user.id == patientId);
    final summaries = await getDailySummaries(patientId);
    final samples = _samples
        .where((sample) => sample.userId == patientId)
        .toList();
    return PatientSleepBundle(
      patient: patient,
      summaries: summaries,
      samples: samples,
    );
  }

  @override
  Future<List<JournalEntry>> getPatientJournalEntries({
    required String clinicianId,
    required String patientId,
  }) async {
    throw const PrivacyException('Journal entries are private in v1.');
  }

  bool _hasAcceptedLink(String clinicianId, String patientId) {
    return _links.any(
      (link) =>
          link.clinicianUserId == clinicianId &&
          link.patientUserId == patientId &&
          link.status == LinkStatus.accepted,
    );
  }
}

Map<String, Object?> _userToJson(AppUser user) {
  return {
    'id': user.id,
    'displayName': user.displayName,
    'role': user.role.name,
    'consentStatus': user.consentStatus.name,
    'clinicCode': user.clinicCode,
  };
}

AppUser _userFromJson(Map<String, Object?> json) {
  return AppUser(
    id: json['id'] as String,
    displayName: json['displayName'] as String,
    role: UserRole.values.byName(json['role'] as String),
    consentStatus: ConsentStatus.values.byName(json['consentStatus'] as String),
    clinicCode: json['clinicCode'] as String?,
  );
}

Map<String, Object?> _linkToJson(ClinicianLink link) {
  return {
    'inviteCode': link.inviteCode,
    'clinicianUserId': link.clinicianUserId,
    'patientUserId': link.patientUserId,
    'status': link.status.name,
    'createdAt': link.createdAt.toIso8601String(),
    'updatedAt': link.updatedAt.toIso8601String(),
  };
}

ClinicianLink _linkFromJson(Map<String, Object?> json) {
  return ClinicianLink(
    inviteCode: json['inviteCode'] as String,
    clinicianUserId: json['clinicianUserId'] as String,
    patientUserId: json['patientUserId'] as String,
    status: LinkStatus.values.byName(json['status'] as String),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
}

Map<String, Object?> _sampleToJson(HealthSample sample) {
  return {
    'userId': sample.userId,
    'source': sample.source,
    'metricType': sample.metricType.name,
    'start': sample.start.toIso8601String(),
    'end': sample.end.toIso8601String(),
    'value': sample.value,
    'unit': sample.unit,
    'createdAt': sample.createdAt.toIso8601String(),
  };
}

HealthSample _sampleFromJson(Map<String, Object?> json) {
  return HealthSample(
    userId: json['userId'] as String,
    source: json['source'] as String,
    metricType: MetricType.values.byName(json['metricType'] as String),
    start: DateTime.parse(json['start'] as String),
    end: DateTime.parse(json['end'] as String),
    value: (json['value'] as num).toDouble(),
    unit: json['unit'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

Map<String, Object?> _entryToJson(JournalEntry entry) {
  return {
    'id': entry.id,
    'userId': entry.userId,
    'title': entry.title,
    'body': entry.body,
    'moodTag': entry.moodTag,
    'createdAt': entry.createdAt.toIso8601String(),
    'privateByDefault': entry.privateByDefault,
  };
}

JournalEntry _entryFromJson(Map<String, Object?> json) {
  return JournalEntry(
    id: json['id'] as String,
    userId: json['userId'] as String,
    title: json['title'] as String,
    body: json['body'] as String,
    moodTag: json['moodTag'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    privateByDefault: json['privateByDefault'] as bool? ?? true,
  );
}
