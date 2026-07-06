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
  PatientSleepBundle? _selectedPatientBundle;
  bool _healthPermissionGranted = false;
  bool _isBusy = false;

  AppSession get session => _session;
  SessionStage get sessionStage => _session.stage;
  AppUser get currentUser => _currentUser;
  List<DailySummary> get summaries => _summaries;
  List<JournalEntry> get journalEntries => _journalEntries;
  List<ResourceCard> get resources => _resources;
  List<AppUser> get linkedPatients => _linkedPatients;
  PatientSleepBundle? get selectedPatientBundle => _selectedPatientBundle;
  bool get healthPermissionGranted => _healthPermissionGranted;
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
      _selectedPatientBundle = null;
      _summaries = await repository.getDailySummariesForPatient(
        requesterUserId: _currentUser.id,
        patientId: _currentUser.id,
      );
      _journalEntries = await repository.getJournalEntriesForPatient(
        requesterUserId: _currentUser.id,
        patientId: _currentUser.id,
      );
    } else {
      _summaries = [];
      _journalEntries = [];
      _linkedPatients = [];
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
    _linkedPatients = [];
    _selectedPatientBundle = null;
    _healthPermissionGranted = false;
    await repository.saveSession(_session);
    await refresh();
  }

  Future<void> acceptClinicInvite() async {
    _setBusy(true);
    _currentUser = await repository.grantPatientConsent(
      _currentUser.id,
      'NID-1138',
    );
    await refresh();
    _setBusy(false);
  }

  Future<void> importMockSleep() async {
    _setBusy(true);
    _healthPermissionGranted = await healthDataProvider.requestPermissions();
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
    _setBusy(false);
  }

  Future<void> resetDemoData() async {
    _setBusy(true);
    try {
      await repository.resetDemoData();
      _session = const AppSession.signedOut();
      _currentUser = repository.patientDemo;
      _summaries = [];
      _journalEntries = [];
      _linkedPatients = [];
      _selectedPatientBundle = null;
      _healthPermissionGranted = false;
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
