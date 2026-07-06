import 'package:flutter/foundation.dart';

import '../models/app_models.dart';
import '../repositories/app_repository.dart';
import '../services/health_data_provider.dart';

class NguyenInDoubtState extends ChangeNotifier {
  NguyenInDoubtState({
    required this.repository,
    required this.healthDataProvider,
  }) {
    _currentUser = repository.patientDemo;
    refresh();
  }

  final InMemoryAppRepository repository;
  final HealthDataProvider healthDataProvider;

  late AppUser _currentUser;
  List<DailySummary> _summaries = [];
  List<JournalEntry> _journalEntries = [];
  List<ResourceCard> _resources = [];
  List<AppUser> _linkedPatients = [];
  PatientSleepBundle? _selectedPatientBundle;
  bool _healthPermissionGranted = false;
  bool _isBusy = false;

  AppUser get currentUser => _currentUser;
  List<DailySummary> get summaries => _summaries;
  List<JournalEntry> get journalEntries => _journalEntries;
  List<ResourceCard> get resources => _resources;
  List<AppUser> get linkedPatients => _linkedPatients;
  PatientSleepBundle? get selectedPatientBundle => _selectedPatientBundle;
  bool get healthPermissionGranted => _healthPermissionGranted;
  bool get isBusy => _isBusy;
  bool get isClinician => _currentUser.role == UserRole.clinician;

  Future<void> refresh() async {
    _resources = await repository.getResourceCards();
    if (isClinician) {
      _linkedPatients = await repository.getLinkedPatients(_currentUser.id);
      if (_linkedPatients.isNotEmpty) {
        _selectedPatientBundle = await repository.getPatientSleepSummary(
          clinicianId: _currentUser.id,
          patientId: _linkedPatients.first.id,
        );
      }
    } else {
      _summaries = await repository.getDailySummaries(_currentUser.id);
      _journalEntries = await repository.getJournalEntries(_currentUser.id);
    }
    notifyListeners();
  }

  Future<void> continueAsPatient() async {
    _currentUser = repository.patientDemo;
    _selectedPatientBundle = null;
    await refresh();
  }

  Future<void> continueAsClinician() async {
    _currentUser = repository.clinicianDemo;
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
      userId: currentUser.id,
      samples: samples,
    );
    await refresh();
    _setBusy(false);
  }

  Future<void> addJournalEntry({
    required String title,
    required String body,
    String? moodTag,
  }) async {
    await repository.addJournalEntry(
      JournalEntry(
        id: 'journal-${DateTime.now().microsecondsSinceEpoch}',
        userId: currentUser.id,
        title: title,
        body: body,
        moodTag: moodTag,
        createdAt: DateTime.now(),
      ),
    );
    _journalEntries = await repository.getJournalEntries(currentUser.id);
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
}
