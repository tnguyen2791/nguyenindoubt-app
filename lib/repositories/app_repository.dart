import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/seed_data.dart';
import '../models/app_models.dart';
import '../services/health_data_provider.dart';

abstract class AppRepository {
  Future<List<ResourceCard>> getResourceCards();

  Future<List<JournalEntry>> getJournalEntriesForPatient({
    required String requesterUserId,
    required String patientId,
  });

  Future<void> addJournalEntry({
    required String requesterUserId,
    required JournalEntry entry,
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

/// Data-subject-rights operations: export (portability) and account deletion.
/// Both are patient-owned; a requester may only act on their own data.
abstract class DataRightsRepository {
  Future<PatientDataExport> exportPatientData({
    required String requesterUserId,
    required String patientId,
  });

  Future<AccountDeletionResult> deletePatientData({
    required String requesterUserId,
    required String patientId,
  });
}

class PrivacyException implements Exception {
  const PrivacyException(this.message);

  final String message;

  @override
  String toString() => message;
}

class InMemoryAppRepository
    implements
        AppRepository,
        ClinicianRepository,
        ConsentRepository,
        DataRightsRepository {
  InMemoryAppRepository({
    this.preferences,
    this.storageKey = _defaultStorageKey,
    this.retentionPolicy = RetentionPolicy.pendingReview,
  }) {
    final savedJson = preferences?.getString(storageKey);
    if (savedJson != null && _restore(savedJson)) {
      _resources.addAll(seedResources);
      return;
    }

    _seedDemoData();
  }

  static const _defaultStorageKey = 'nguyenindoubt.local_demo.v1';
  static const _dataExportVersion = 1;

  final SharedPreferences? preferences;
  final String storageKey;
  final RetentionPolicy retentionPolicy;

  final List<AppUser> _users = [];
  final List<ClinicianLink> _links = [];
  final List<HealthSample> _samples = [];
  final List<DailySummary> _summaries = [];
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
        'schemaVersion': 2,
        'users': _users.map(_userToJson).toList(),
        'links': _links.map(_linkToJson).toList(),
        'samples': _samples.map(_sampleToJson).toList(),
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
    return _consentEventsFor(patientId);
  }

  @override
  Future<PatientDataExport> exportPatientData({
    required String requesterUserId,
    required String patientId,
  }) async {
    _ensurePatientOwnsData(
      requesterUserId: requesterUserId,
      patientId: patientId,
      resourceName: 'exported data',
    );
    final profile = _findUser(patientId);
    if (profile == null) {
      throw const PrivacyException('Patient profile was not found.');
    }

    return PatientDataExport(
      exportVersion: _dataExportVersion,
      generatedAt: DateTime.now(),
      patientId: patientId,
      profile: profile,
      journalEntries: _journalEntriesFor(patientId),
      healthSamples: _samples
          .where((sample) => sample.userId == patientId)
          .toList(),
      dailySummaries: _dailySummariesFor(patientId),
      clinicianLinks: _links
          .where((link) => link.patientUserId == patientId)
          .toList(),
      consentHistory: _consentEventsFor(patientId),
    );
  }

  @override
  Future<AccountDeletionResult> deletePatientData({
    required String requesterUserId,
    required String patientId,
  }) async {
    _ensurePatientOwnsData(
      requesterUserId: requesterUserId,
      patientId: patientId,
      resourceName: 'account data',
    );
    final userIndex = _users.indexWhere((user) => user.id == patientId);
    if (userIndex < 0) {
      throw const PrivacyException('Patient profile was not found.');
    }

    final now = DateTime.now();
    final deletedJournalEntries = _entries
        .where((entry) => entry.userId == patientId)
        .length;
    final deletedHealthSamples = _samples
        .where((sample) => sample.userId == patientId)
        .length;
    final deletedDailySummaries = _summaries
        .where((summary) => summary.userId == patientId)
        .length;

    _entries.removeWhere((entry) => entry.userId == patientId);
    _samples.removeWhere((sample) => sample.userId == patientId);
    _summaries.removeWhere((summary) => summary.userId == patientId);

    // End any active sharing and record the consent event so the audit trail
    // survives deletion of the personal data.
    final previous = _users[userIndex];
    var revokedClinicianLinks = 0;
    for (var i = 0; i < _links.length; i++) {
      final link = _links[i];
      if (link.patientUserId != patientId ||
          link.status != LinkStatus.accepted) {
        continue;
      }
      _links[i] = ClinicianLink(
        inviteCode: link.inviteCode,
        clinicianUserId: link.clinicianUserId,
        patientUserId: link.patientUserId,
        status: LinkStatus.revoked,
        createdAt: link.createdAt,
        updatedAt: now,
      );
      _addConsentEvent(
        patientUserId: patientId,
        clinicianUserId: link.clinicianUserId,
        inviteCode: link.inviteCode,
        previousStatus: previous.consentStatus,
        nextStatus: ConsentStatus.revoked,
        action: ConsentEventAction.revoked,
        actorUserId: patientId,
        occurredAt: now,
      );
      revokedClinicianLinks++;
    }

    // Reset the profile to an emptied account shell. In production, deletion
    // also removes the auth user and profile record via a trusted backend;
    // here the demo keeps a shell so the local app stays functional.
    _users[userIndex] = previous.copyWith(
      consentStatus: ConsentStatus.revoked,
      clearClinicCode: true,
    );

    final retainedConsentEvents = _consentEvents
        .where((event) => event.patientUserId == patientId)
        .length;

    await _persist();

    return AccountDeletionResult(
      patientId: patientId,
      deletedAt: now,
      deletedJournalEntries: deletedJournalEntries,
      deletedHealthSamples: deletedHealthSamples,
      deletedDailySummaries: deletedDailySummaries,
      revokedClinicianLinks: revokedClinicianLinks,
      retainedConsentEvents: retainedConsentEvents,
    );
  }

  /// Applies [retentionPolicy], purging records older than each category's
  /// window. Returns the number of records purged. The default policy purges
  /// nothing. In production, this enforcement runs as a scheduled trusted
  /// backend (Cloud Function) job, not on the client.
  Future<int> applyRetention({DateTime? asOf}) async {
    final policy = retentionPolicy;
    if (policy.purgesNothing) {
      return 0;
    }
    final now = asOf ?? DateTime.now();
    var purged = 0;

    final sampleWindow = policy.healthSamples;
    if (sampleWindow != null) {
      final cutoff = now.subtract(sampleWindow);
      final before = _samples.length;
      _samples.removeWhere((sample) => sample.createdAt.isBefore(cutoff));
      purged += before - _samples.length;
    }
    final summaryWindow = policy.dailySummaries;
    if (summaryWindow != null) {
      final cutoff = now.subtract(summaryWindow);
      final before = _summaries.length;
      _summaries.removeWhere((summary) => summary.date.isBefore(cutoff));
      purged += before - _summaries.length;
    }
    final journalWindow = policy.journalEntries;
    if (journalWindow != null) {
      final cutoff = now.subtract(journalWindow);
      final before = _entries.length;
      _entries.removeWhere((entry) => entry.createdAt.isBefore(cutoff));
      purged += before - _entries.length;
    }
    final consentWindow = policy.consentHistory;
    if (consentWindow != null) {
      final cutoff = now.subtract(consentWindow);
      final before = _consentEvents.length;
      _consentEvents.removeWhere((event) => event.occurredAt.isBefore(cutoff));
      purged += before - _consentEvents.length;
    }

    if (purged > 0) {
      await _persist();
    }
    return purged;
  }

  List<ConsentHistoryEvent> _consentEventsFor(String patientId) {
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

Map<String, Object?> _summaryToJson(DailySummary summary) {
  return {
    'userId': summary.userId,
    'date': summary.date.toIso8601String(),
    'sleepDurationHours': summary.sleepDurationHours,
    'sleepQualityProxy': summary.sleepQualityProxy,
    'trendFlag': summary.trendFlag,
  };
}

/// Serializes a [PatientDataExport] to a JSON-encodable map, reusing the same
/// per-model encoders used for local persistence so the export format stays in
/// sync with stored data.
Map<String, Object?> patientDataExportToJson(PatientDataExport export) {
  return {
    'exportVersion': export.exportVersion,
    'generatedAt': export.generatedAt.toIso8601String(),
    'patientId': export.patientId,
    'profile': _userToJson(export.profile),
    'journalEntries': export.journalEntries.map(_entryToJson).toList(),
    'healthSamples': export.healthSamples.map(_sampleToJson).toList(),
    'dailySummaries': export.dailySummaries.map(_summaryToJson).toList(),
    'clinicianLinks': export.clinicianLinks.map(_linkToJson).toList(),
    'consentHistory': export.consentHistory.map(_consentEventToJson).toList(),
  };
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
