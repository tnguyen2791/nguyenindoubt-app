import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/seed_data.dart';
import '../models/app_models.dart';
import '../services/health_data_provider.dart';

abstract class AppRepository {
  /// Reads the profile for [uid], or null when no profile exists yet.
  ///
  /// InMemory: returns the seeded demo user when [uid] matches, else null.
  /// Firebase: reads `users/{uid}` and maps it to an [AppUser], or null when
  /// the document is absent (a freshly signed-in account before bootstrap).
  Future<AppUser?> getUser(String uid);

  /// Ensures a profile exists for [uid], creating a minimal patient profile
  /// (role=patient, consentStatus=notAsked) when absent, and returns it.
  ///
  /// InMemory: a no-op that returns the seeded demo user (tests never create
  /// real accounts). Firebase: creates `users/{uid}` if missing, then returns
  /// the current profile. Idempotent — safe to call on every signed-in boot.
  Future<AppUser> ensureUser({
    required String uid,
    required String displayName,
    required UserRole role,
  });

  Future<List<ResourceCard>> getResourceCards();

  Future<List<JournalEntry>> getJournalEntriesForPatient({
    required String requesterUserId,
    required String patientId,
  });

  Future<void> addJournalEntry({
    required String requesterUserId,
    required JournalEntry entry,
  });

  Future<void> deleteJournalEntry({
    required String requesterUserId,
    required String entryId,
  });

  Future<void> saveImportedSleep({
    required String requesterUserId,
    required String patientId,
    required List<HealthSample> samples,
  });

  Future<List<DailySummary>> getDailySummariesForPatient({
    required String requesterUserId,
    required String patientId,
  });

  /// Persists the patient's multi-signal readiness summaries (Phase 13).
  /// Patient-owned only — the clinician surface never reads readiness, keeping
  /// the sleep-summaries-only contract intact. Idempotent per (patient, date).
  Future<void> saveReadinessSummaries({
    required String requesterUserId,
    required String patientId,
    required List<ReadinessSummary> summaries,
  });

  /// Reads the patient's readiness summaries, date ascending. Patient-owned.
  Future<List<ReadinessSummary>> getReadinessSummariesForPatient({
    required String requesterUserId,
    required String patientId,
  });
}

abstract class ClinicianRepository {
  Future<List<AppUser>> getLinkedPatients(String clinicianId);

  Future<List<ClinicianLinkStatusView>> getClinicianLinkStatuses(
    String clinicianId,
  );

  Future<PatientSleepBundle> getPatientSleepSummary({
    required String clinicianId,
    required String patientId,
  });
}

abstract class ConsentRepository {
  Future<InviteValidationResult> validateInviteCode({
    required String patientId,
    required String inviteCode,
  });

  Future<AppUser> acceptInvite({
    required String patientId,
    required String inviteCode,
  });

  Future<AppUser> revokeConsent({required String patientId});

  Future<List<ConsentHistoryEvent>> getConsentHistory({
    required String patientId,
  });
}

/// The full repository surface the app talks to: patient data, clinician
/// reads, and consent writes. Both [InMemoryAppRepository] (demo/tests) and
/// [FirebaseAppRepository] (live) satisfy it, so [NguyenInDoubtState] can hold
/// one field and swap backends behind auth without changing call sites.
abstract class NidRepository
    implements AppRepository, ClinicianRepository, ConsentRepository {}

class PrivacyException implements Exception {
  const PrivacyException(this.message);

  final String message;

  @override
  String toString() => message;
}

class InMemoryAppRepository implements NidRepository {
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
  final List<ReadinessSummary> _readiness = [];
  final List<JournalEntry> _entries = [];
  final List<ResourceCard> _resources = [];
  final List<ConsentHistoryEvent> _consentEvents = [];
  AppSession _session = const AppSession.signedOut();

  void _seedDemoData() {
    _users
      ..clear()
      ..addAll([
        demoPatient,
        linkedPatient,
        expiredInvitePatient,
        demoClinician,
      ]);
    _links
      ..clear()
      ..addAll(seedClinicianLinks());
    _samples
      ..clear()
      ..addAll(seedLinkedSleepSamples());
    _summaries
      ..clear()
      ..addAll(summarizeSleepSamples(_samples));
    _readiness.clear();
    _entries
      ..clear()
      ..addAll(seedJournalEntries());
    _resources
      ..clear()
      ..addAll(seedResources);
    _consentEvents.clear();
    _session = const AppSession.signedOut();
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
      _readiness
        ..clear()
        ..addAll(
          ((decoded['readiness'] as List<dynamic>?) ?? []).map(
            (json) => _readinessFromJson(json as Map<String, Object?>),
          ),
        );
      _entries
        ..clear()
        ..addAll(
          (decoded['entries'] as List<dynamic>).map(
            (json) => _entryFromJson(json as Map<String, Object?>),
          ),
        );
      _consentEvents
        ..clear()
        ..addAll(
          ((decoded['consentEvents'] as List<dynamic>?) ?? []).map(
            (json) => _consentEventFromJson(json as Map<String, Object?>),
          ),
        );
      _session = _sessionFromJson(decoded['session'] as Map<String, Object?>?);
      return _users.isNotEmpty;
    } on Object {
      _users.clear();
      _links.clear();
      _samples.clear();
      _summaries.clear();
      _readiness.clear();
      _entries.clear();
      _consentEvents.clear();
      _session = const AppSession.signedOut();
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
        'schemaVersion': 3,
        'users': _users.map(_userToJson).toList(),
        'links': _links.map(_linkToJson).toList(),
        'samples': _samples.map(_sampleToJson).toList(),
        'readiness': _readiness.map(_readinessToJson).toList(),
        'entries': _entries.map(_entryToJson).toList(),
        'consentEvents': _consentEvents.map(_consentEventToJson).toList(),
        'session': _sessionToJson(_session),
      }),
    );
  }

  Future<void> resetDemoData() async {
    await preferences?.remove(storageKey);
    _seedDemoData();
  }

  AppSession get currentSession => _session;

  AppUser get patientDemo =>
      _users.firstWhere((user) => user.id == demoPatient.id);

  AppUser get clinicianDemo =>
      _users.firstWhere((user) => user.id == demoClinician.id);

  Future<void> saveSession(AppSession session) async {
    _session = session;
    await _persist();
  }

  Future<AppUser> updateDemoPatientProfile({
    required String displayName,
  }) async {
    final index = _users.indexWhere((user) => user.id == demoPatient.id);
    final updated = _users[index].copyWith(displayName: displayName);
    _users[index] = updated;
    await _persist();
    return updated;
  }

  @override
  Future<AppUser?> getUser(String uid) async {
    return _findUser(uid);
  }

  @override
  Future<AppUser> ensureUser({
    required String uid,
    required String displayName,
    required UserRole role,
  }) async {
    // Demo/in-memory: never mints real accounts. Return the existing seeded
    // user when it matches; otherwise fall back to the demo patient so the
    // demo path stays entirely offline and deterministic (tests rely on this).
    return _findUser(uid) ?? patientDemo;
  }

  @override
  Future<InviteValidationResult> validateInviteCode({
    required String patientId,
    required String inviteCode,
  }) async {
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

    final matches = _links.where((link) => link.inviteCode == normalized);
    if (matches.isEmpty) {
      return InviteValidationResult(
        status: InviteValidationStatus.missing,
        normalizedCode: normalized,
        message: 'No invite with that code was found.',
      );
    }

    final link = matches.first;
    final clinician = _findUser(link.clinicianUserId);
    if (link.patientUserId != patientId) {
      return InviteValidationResult(
        status: InviteValidationStatus.wrongPatient,
        normalizedCode: normalized,
        patientUserId: link.patientUserId,
        clinicianUserId: link.clinicianUserId,
        clinicianDisplayName: clinician?.displayName,
        message: 'This invite is for a different patient account.',
      );
    }

    return switch (link.status) {
      LinkStatus.pending => InviteValidationResult(
        status: InviteValidationStatus.valid,
        normalizedCode: normalized,
        patientUserId: link.patientUserId,
        clinicianUserId: link.clinicianUserId,
        clinicianDisplayName: clinician?.displayName,
        message: 'Invite validated. Review sharing before accepting.',
      ),
      LinkStatus.accepted => InviteValidationResult(
        status: InviteValidationStatus.alreadyAccepted,
        normalizedCode: normalized,
        patientUserId: link.patientUserId,
        clinicianUserId: link.clinicianUserId,
        clinicianDisplayName: clinician?.displayName,
        message: 'This invite is already accepted.',
      ),
      LinkStatus.revoked => InviteValidationResult(
        status: InviteValidationStatus.revoked,
        normalizedCode: normalized,
        patientUserId: link.patientUserId,
        clinicianUserId: link.clinicianUserId,
        clinicianDisplayName: clinician?.displayName,
        message: 'This invite was revoked and cannot be reused.',
      ),
      LinkStatus.expired => InviteValidationResult(
        status: InviteValidationStatus.expired,
        normalizedCode: normalized,
        patientUserId: link.patientUserId,
        clinicianUserId: link.clinicianUserId,
        clinicianDisplayName: clinician?.displayName,
        message: 'This invite has expired. Ask for a new code.',
      ),
    };
  }

  @override
  Future<AppUser> acceptInvite({
    required String patientId,
    required String inviteCode,
  }) async {
    final validation = await validateInviteCode(
      patientId: patientId,
      inviteCode: inviteCode,
    );
    if (!validation.canAccept) {
      throw PrivacyException(validation.message);
    }

    final normalized = validation.normalizedCode;
    final index = _users.indexWhere((user) => user.id == patientId);
    final previous = _users[index];
    final updated = _users[index].copyWith(
      consentStatus: ConsentStatus.granted,
      clinicCode: normalized,
    );

    final linkIndex = _links.indexWhere(
      (link) =>
          link.patientUserId == patientId && link.inviteCode == normalized,
    );
    final now = DateTime.now();
    final existing = _links[linkIndex];
    _users[index] = updated;
    _links[linkIndex] = ClinicianLink(
      inviteCode: existing.inviteCode,
      clinicianUserId: existing.clinicianUserId,
      patientUserId: existing.patientUserId,
      status: LinkStatus.accepted,
      createdAt: existing.createdAt,
      updatedAt: now,
    );
    _addConsentEvent(
      patientUserId: patientId,
      clinicianUserId: existing.clinicianUserId,
      inviteCode: normalized,
      previousStatus: previous.consentStatus,
      nextStatus: ConsentStatus.granted,
      action: ConsentEventAction.accepted,
      actorUserId: patientId,
      occurredAt: now,
    );
    await _persist();
    return updated;
  }

  @override
  Future<AppUser> revokeConsent({required String patientId}) async {
    final linkIndex = _links.indexWhere(
      (link) =>
          link.patientUserId == patientId && link.status == LinkStatus.accepted,
    );
    if (linkIndex < 0) {
      throw const PrivacyException('No active clinician link to revoke.');
    }

    final userIndex = _users.indexWhere((user) => user.id == patientId);
    final previous = _users[userIndex];
    final existing = _links[linkIndex];
    final now = DateTime.now();
    final updated = previous.copyWith(
      consentStatus: ConsentStatus.revoked,
      clearClinicCode: true,
    );
    _users[userIndex] = updated;
    _links[linkIndex] = ClinicianLink(
      inviteCode: existing.inviteCode,
      clinicianUserId: existing.clinicianUserId,
      patientUserId: existing.patientUserId,
      status: LinkStatus.revoked,
      createdAt: existing.createdAt,
      updatedAt: now,
    );
    _addConsentEvent(
      patientUserId: patientId,
      clinicianUserId: existing.clinicianUserId,
      inviteCode: existing.inviteCode,
      previousStatus: previous.consentStatus,
      nextStatus: ConsentStatus.revoked,
      action: ConsentEventAction.revoked,
      actorUserId: patientId,
      occurredAt: now,
    );
    await _persist();
    return updated;
  }

  @override
  Future<List<ConsentHistoryEvent>> getConsentHistory({
    required String patientId,
  }) async {
    return _consentEvents
        .where((event) => event.patientUserId == patientId)
        .toList()
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
  }

  @override
  Future<void> addJournalEntry({
    required String requesterUserId,
    required JournalEntry entry,
  }) async {
    _ensurePatientOwnsData(
      requesterUserId: requesterUserId,
      patientId: entry.userId,
      resourceName: 'journal entries',
    );
    _entries.insert(0, entry);
    await _persist();
  }

  @override
  Future<void> deleteJournalEntry({
    required String requesterUserId,
    required String entryId,
  }) async {
    final index = _entries.indexWhere((entry) => entry.id == entryId);
    if (index < 0) {
      // Idempotent no-op: nothing to delete, so there is nothing to own.
      return;
    }
    _ensurePatientOwnsData(
      requesterUserId: requesterUserId,
      patientId: _entries[index].userId,
      resourceName: 'journal entries',
    );
    _entries.removeAt(index);
    await _persist();
  }

  @override
  Future<List<DailySummary>> getDailySummariesForPatient({
    required String requesterUserId,
    required String patientId,
  }) async {
    _ensurePatientOwnsData(
      requesterUserId: requesterUserId,
      patientId: patientId,
      resourceName: 'daily summaries',
    );
    return _dailySummariesFor(patientId);
  }

  @override
  Future<void> saveReadinessSummaries({
    required String requesterUserId,
    required String patientId,
    required List<ReadinessSummary> summaries,
  }) async {
    _ensurePatientOwnsData(
      requesterUserId: requesterUserId,
      patientId: patientId,
      resourceName: 'readiness summaries',
    );
    if (summaries.any((summary) => summary.userId != patientId)) {
      throw const PrivacyException(
        'Readiness summaries must belong to the patient.',
      );
    }
    // Upsert per (patient, date): drop any existing rows for the patient's
    // affected days, then insert the new ones.
    final affectedDays = summaries
        .map((summary) => _dayKey(summary.userId, summary.date))
        .toSet();
    _readiness.removeWhere(
      (summary) => affectedDays.contains(_dayKey(summary.userId, summary.date)),
    );
    _readiness.addAll(summaries);
    await _persist();
  }

  @override
  Future<List<ReadinessSummary>> getReadinessSummariesForPatient({
    required String requesterUserId,
    required String patientId,
  }) async {
    _ensurePatientOwnsData(
      requesterUserId: requesterUserId,
      patientId: patientId,
      resourceName: 'readiness summaries',
    );
    return _readiness.where((summary) => summary.userId == patientId).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  @override
  Future<List<JournalEntry>> getJournalEntriesForPatient({
    required String requesterUserId,
    required String patientId,
  }) async {
    _ensurePatientOwnsData(
      requesterUserId: requesterUserId,
      patientId: patientId,
      resourceName: 'journal entries',
    );
    return _journalEntriesFor(patientId);
  }

  @override
  Future<List<ResourceCard>> getResourceCards() async {
    return _resources.toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  @override
  Future<void> saveImportedSleep({
    required String requesterUserId,
    required String patientId,
    required List<HealthSample> samples,
  }) async {
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
    final mergedSamples = dedupeSleepSamples([
      ..._samples.where(
        (sample) =>
            sample.userId == patientId && sample.metricType == MetricType.sleep,
      ),
      ...samples,
    ]);
    _samples.removeWhere(
      (sample) =>
          sample.userId == patientId && sample.metricType == MetricType.sleep,
    );
    _summaries.removeWhere((summary) => summary.userId == patientId);
    _samples.addAll(mergedSamples);
    _summaries.addAll(summarizeSleepSamples(mergedSamples));
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
  Future<List<ClinicianLinkStatusView>> getClinicianLinkStatuses(
    String clinicianId,
  ) async {
    final statuses = _links
        .where((link) => link.clinicianUserId == clinicianId)
        .map((link) {
          final patient = _findUser(link.patientUserId);
          return ClinicianLinkStatusView(
            patientUserId: link.patientUserId,
            patientDisplayName: patient?.displayName,
            inviteCode: link.inviteCode,
            status: link.status,
            updatedAt: link.updatedAt,
          );
        })
        .toList();
    statuses.sort(_compareClinicianLinkStatus);
    return statuses;
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
    if (patient.consentStatus != ConsentStatus.granted) {
      throw const PrivacyException(
        'Patient has not granted active sleep sharing.',
      );
    }
    final summaries = _dailySummariesFor(patientId);
    final samples = _samples
        .where((sample) => sample.userId == patientId)
        .toList();
    return PatientSleepBundle(
      patient: patient,
      summaries: summaries,
      samples: samples,
    );
  }

  Future<void> updateDemoClinicianLinkStatus({
    required String clinicianId,
    required String patientId,
    required LinkStatus status,
  }) async {
    final index = _links.indexWhere(
      (link) =>
          link.clinicianUserId == clinicianId &&
          link.patientUserId == patientId,
    );
    if (index < 0) {
      return;
    }

    final existing = _links[index];
    _links[index] = ClinicianLink(
      inviteCode: existing.inviteCode,
      clinicianUserId: existing.clinicianUserId,
      patientUserId: existing.patientUserId,
      status: status,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
    );
    await _persist();
  }

  bool _hasAcceptedLink(String clinicianId, String patientId) {
    return _links.any(
      (link) =>
          link.clinicianUserId == clinicianId &&
          link.patientUserId == patientId &&
          link.status == LinkStatus.accepted,
    );
  }

  void _addConsentEvent({
    required String patientUserId,
    required String clinicianUserId,
    required String inviteCode,
    required ConsentStatus previousStatus,
    required ConsentStatus nextStatus,
    required ConsentEventAction action,
    required String actorUserId,
    required DateTime occurredAt,
  }) {
    _consentEvents.insert(
      0,
      ConsentHistoryEvent(
        id: 'consent-${occurredAt.microsecondsSinceEpoch}',
        patientUserId: patientUserId,
        clinicianUserId: clinicianUserId,
        inviteCode: inviteCode,
        previousStatus: previousStatus,
        nextStatus: nextStatus,
        action: action,
        actorUserId: actorUserId,
        occurredAt: occurredAt,
      ),
    );
  }

  AppUser? _findUser(String userId) {
    for (final user in _users) {
      if (user.id == userId) {
        return user;
      }
    }
    return null;
  }

  List<DailySummary> _dailySummariesFor(String patientId) {
    return _summaries.where((summary) => summary.userId == patientId).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  String _dayKey(String userId, DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return '$userId|${day.toIso8601String()}';
  }

  List<JournalEntry> _journalEntriesFor(String patientId) {
    return _entries.where((entry) => entry.userId == patientId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
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

Map<String, Object?> _readinessToJson(ReadinessSummary summary) {
  return {
    'userId': summary.userId,
    'date': summary.date.toIso8601String(),
    'readinessScore': summary.readinessScore,
    'state': summary.state,
    'contributors': summary.contributors
        .map(_readinessContributorToJson)
        .toList(),
  };
}

ReadinessSummary _readinessFromJson(Map<String, Object?> json) {
  return ReadinessSummary(
    userId: json['userId'] as String,
    date: DateTime.parse(json['date'] as String),
    readinessScore: json['readinessScore'] as int,
    state: json['state'] as String,
    contributors: ((json['contributors'] as List<dynamic>?) ?? [])
        .map((c) => _readinessContributorFromJson(c as Map<String, Object?>))
        .toList(),
  );
}

Map<String, Object?> _readinessContributorToJson(ReadinessContributor c) {
  return {
    'metric': c.metric.name,
    'name': c.name,
    'word': c.word,
    'fraction': c.fraction,
    'value': c.value,
    'unit': c.unit,
  };
}

ReadinessContributor _readinessContributorFromJson(Map<String, Object?> json) {
  return ReadinessContributor(
    metric: MetricType.values.byName(json['metric'] as String),
    name: json['name'] as String,
    word: json['word'] as String,
    fraction: (json['fraction'] as num).toDouble(),
    value: (json['value'] as num?)?.toDouble(),
    unit: json['unit'] as String?,
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

Map<String, Object?> _consentEventToJson(ConsentHistoryEvent event) {
  return {
    'id': event.id,
    'patientUserId': event.patientUserId,
    'clinicianUserId': event.clinicianUserId,
    'inviteCode': event.inviteCode,
    'previousStatus': event.previousStatus.name,
    'nextStatus': event.nextStatus.name,
    'action': event.action.name,
    'actorUserId': event.actorUserId,
    'occurredAt': event.occurredAt.toIso8601String(),
  };
}

ConsentHistoryEvent _consentEventFromJson(Map<String, Object?> json) {
  return ConsentHistoryEvent(
    id: json['id'] as String,
    patientUserId: json['patientUserId'] as String,
    clinicianUserId: json['clinicianUserId'] as String,
    inviteCode: json['inviteCode'] as String,
    previousStatus: ConsentStatus.values.byName(
      json['previousStatus'] as String,
    ),
    nextStatus: ConsentStatus.values.byName(json['nextStatus'] as String),
    action: ConsentEventAction.values.byName(json['action'] as String),
    actorUserId: json['actorUserId'] as String,
    occurredAt: DateTime.parse(json['occurredAt'] as String),
  );
}

Map<String, Object?> _sessionToJson(AppSession session) {
  return {'stage': session.stage.name, 'userId': session.userId};
}

AppSession _sessionFromJson(Map<String, Object?>? json) {
  if (json == null) {
    return const AppSession.signedOut();
  }

  final stage = SessionStage.values.byName(json['stage'] as String);
  final userId = json['userId'] as String?;
  return AppSession(stage: stage, userId: userId);
}
