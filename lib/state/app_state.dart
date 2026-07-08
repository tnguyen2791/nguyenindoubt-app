import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/app_models.dart';
import '../repositories/app_repository.dart';
import '../services/health_data_provider.dart';

class NguyenInDoubtState extends ChangeNotifier {
  NguyenInDoubtState({
    required this.repository,
    required this.healthDataProvider,
  }) {
    _session = repository.currentSession;
    _currentUser = _userForSession(_session);
    _healthPermissionStatus = healthDataProvider.permissionStatus;
    refresh();
  }

  final InMemoryAppRepository repository;
  final HealthDataProvider healthDataProvider;

  late AppUser _currentUser;
  late AppSession _session;
  List<DailySummary> _summaries = [];
  List<JournalEntry> _journalEntries = [];
  List<ResourceCard> _resources = [];
  List<AppUser> _linkedPatients = [];
  List<ClinicianLinkStatusView> _clinicianLinkStatuses = [];
  List<ConsentHistoryEvent> _consentHistory = [];
  PatientSleepBundle? _selectedPatientBundle;
  InviteValidationResult? _inviteValidation;
  HealthPermissionStatus _healthPermissionStatus =
      HealthPermissionStatus.notRequested;
  bool _isBusy = false;

  AppSession get session => _session;
  SessionStage get sessionStage => _session.stage;
  AppUser get currentUser => _currentUser;
  List<DailySummary> get summaries => _summaries;
  List<JournalEntry> get journalEntries => _journalEntries;
  List<ResourceCard> get resources => _resources;
  List<AppUser> get linkedPatients => _linkedPatients;
  List<ClinicianLinkStatusView> get clinicianLinkStatuses =>
      _clinicianLinkStatuses;
  List<ConsentHistoryEvent> get consentHistory => _consentHistory;
  PatientSleepBundle? get selectedPatientBundle => _selectedPatientBundle;
  InviteValidationResult? get inviteValidation => _inviteValidation;
  HealthPermissionStatus get healthPermissionStatus => _healthPermissionStatus;
  bool get healthPermissionGranted =>
      _healthPermissionStatus == HealthPermissionStatus.ready;
  bool get isBusy => _isBusy;
  bool get isSignedOut => _session.stage == SessionStage.signedOut;
  bool get isOnboarding => _session.stage == SessionStage.onboarding;
  bool get isPatient => _session.stage == SessionStage.patient;
  bool get isClinician => _session.stage == SessionStage.clinician;

  Future<void> refresh() async {
    _resources = await repository.getResourceCards();
    if (isClinician) {
      _summaries = [];
      _journalEntries = [];
      _consentHistory = [];
      _clinicianLinkStatuses = await repository.getClinicianLinkStatuses(
        _currentUser.id,
      );
      _linkedPatients = await repository.getLinkedPatients(_currentUser.id);
      if (_linkedPatients.isNotEmpty) {
        _selectedPatientBundle = await repository.getPatientSleepSummary(
          clinicianId: _currentUser.id,
          patientId: _linkedPatients.first.id,
        );
      } else {
        _selectedPatientBundle = null;
      }
    } else if (isPatient) {
      _linkedPatients = [];
      _clinicianLinkStatuses = [];
      _selectedPatientBundle = null;
      _summaries = await repository.getDailySummariesForPatient(
        requesterUserId: _currentUser.id,
        patientId: _currentUser.id,
      );
      _journalEntries = await repository.getJournalEntriesForPatient(
        requesterUserId: _currentUser.id,
        patientId: _currentUser.id,
      );
      _consentHistory = await repository.getConsentHistory(
        patientId: _currentUser.id,
      );
    } else {
      _summaries = [];
      _journalEntries = [];
      _consentHistory = [];
      _linkedPatients = [];
      _clinicianLinkStatuses = [];
      _selectedPatientBundle = null;
    }
    notifyListeners();
  }

  Future<void> startPatientOnboarding() async {
    _session = const AppSession(stage: SessionStage.onboarding);
    _currentUser = repository.patientDemo;
    await repository.saveSession(_session);
    await refresh();
  }

  Future<void> completePatientOnboarding({required String displayName}) async {
    final normalizedName = displayName.trim().isEmpty
        ? repository.patientDemo.displayName
        : displayName.trim();
    _currentUser = await repository.updateDemoPatientProfile(
      displayName: normalizedName,
    );
    _session = AppSession(stage: SessionStage.patient, userId: _currentUser.id);
    await repository.saveSession(_session);
    await refresh();
  }

  Future<void> continueAsPatient() async {
    _currentUser = repository.patientDemo;
    _session = AppSession(stage: SessionStage.patient, userId: _currentUser.id);
    await repository.saveSession(_session);
    await refresh();
  }

  Future<void> continueAsClinician() async {
    await continueAsClinicianDemo();
  }

  Future<void> continueAsClinicianDemo() async {
    _currentUser = repository.clinicianDemo;
    _session = AppSession(
      stage: SessionStage.clinician,
      userId: _currentUser.id,
    );
    await repository.saveSession(_session);
    await refresh();
  }

  Future<void> signOut() async {
    _session = const AppSession.signedOut();
    _currentUser = repository.patientDemo;
    _summaries = [];
    _journalEntries = [];
    _consentHistory = [];
    _linkedPatients = [];
    _clinicianLinkStatuses = [];
    _selectedPatientBundle = null;
    _inviteValidation = null;
    _healthPermissionStatus = HealthPermissionStatus.notRequested;
    await repository.saveSession(_session);
    await refresh();
  }

  Future<void> validateInviteCode(String inviteCode) async {
    _setBusy(true);
    try {
      _inviteValidation = await repository.validateInviteCode(
        patientId: _currentUser.id,
        inviteCode: inviteCode,
      );
      notifyListeners();
    } finally {
      _setBusy(false);
    }
  }

  Future<void> acceptValidatedInvite() async {
    final validation = _inviteValidation;
    if (validation == null || !validation.canAccept) {
      return;
    }

    _setBusy(true);
    try {
      _currentUser = await repository.acceptInvite(
        patientId: _currentUser.id,
        inviteCode: validation.normalizedCode,
      );
      _inviteValidation = null;
      await refresh();
    } finally {
      _setBusy(false);
    }
  }

  Future<void> revokeConsent() async {
    _setBusy(true);
    try {
      _currentUser = await repository.revokeConsent(patientId: _currentUser.id);
      _inviteValidation = null;
      await refresh();
    } finally {
      _setBusy(false);
    }
  }

  Future<void> importMockSleep() async {
    _setBusy(true);
    try {
      _healthPermissionStatus = await healthDataProvider
          .checkPermissionStatus();
      if (_healthPermissionStatus != HealthPermissionStatus.ready &&
          _healthPermissionStatus != HealthPermissionStatus.partial) {
        await healthDataProvider.requestPermissions();
        _healthPermissionStatus = await healthDataProvider
            .checkPermissionStatus();
      }
      final samples = await healthDataProvider.fetchSleepSamples(
        HealthRange(
          start: DateTime.now().subtract(const Duration(days: 8)),
          end: DateTime.now().add(const Duration(days: 1)),
        ),
      );
      await repository.saveImportedSleep(
        requesterUserId: currentUser.id,
        patientId: currentUser.id,
        samples: samples,
      );
      await refresh();
    } finally {
      _setBusy(false);
    }
  }

  /// Assembles the current patient's full data export as indented JSON,
  /// suitable for saving or sharing (data-portability right).
  Future<String> exportMyData() async {
    final export = await repository.exportPatientData(
      requesterUserId: currentUser.id,
      patientId: currentUser.id,
    );
    return const JsonEncoder.withIndent(
      '  ',
    ).convert(patientDataExportToJson(export));
  }

  /// Deletes the current patient's personal data (journal, sleep, summaries)
  /// and ends active clinician sharing, retaining the consent audit trail.
  /// Distinct from [resetDemoData], which wipes the whole device demo.
  Future<AccountDeletionResult> deleteMyAccount() async {
    _setBusy(true);
    try {
      final result = await repository.deletePatientData(
        requesterUserId: currentUser.id,
        patientId: currentUser.id,
      );
      await refresh();
      return result;
    } finally {
      _setBusy(false);
    }
  }

  Future<void> resetDemoData() async {
    _setBusy(true);
    try {
      await repository.resetDemoData();
      _session = const AppSession.signedOut();
      _currentUser = repository.patientDemo;
      _summaries = [];
      _journalEntries = [];
      _consentHistory = [];
      _linkedPatients = [];
      _clinicianLinkStatuses = [];
      _selectedPatientBundle = null;
      _inviteValidation = null;
      _healthPermissionStatus = HealthPermissionStatus.notRequested;
      await refresh();
    } finally {
      _setBusy(false);
    }
  }

  Future<void> addJournalEntry({
    required String title,
    required String body,
    String? moodTag,
  }) async {
    await repository.addJournalEntry(
      requesterUserId: currentUser.id,
      entry: JournalEntry(
        id: 'journal-${DateTime.now().microsecondsSinceEpoch}',
        userId: currentUser.id,
        title: title,
        body: body,
        moodTag: moodTag,
        createdAt: DateTime.now(),
      ),
    );
    _journalEntries = await repository.getJournalEntriesForPatient(
      requesterUserId: currentUser.id,
      patientId: currentUser.id,
    );
    notifyListeners();
  }

  Future<void> selectPatient(String patientId) async {
    _selectedPatientBundle = await repository.getPatientSleepSummary(
      clinicianId: currentUser.id,
      patientId: patientId,
    );
    notifyListeners();
  }

  void _setBusy(bool value) {
    _isBusy = value;
    notifyListeners();
  }

  AppUser _userForSession(AppSession session) {
    if (session.stage == SessionStage.clinician) {
      return repository.clinicianDemo;
    }

    return repository.patientDemo;
  }
}
