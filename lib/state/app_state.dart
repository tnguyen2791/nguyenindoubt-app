import 'package:flutter/foundation.dart';

import '../models/app_models.dart';
import '../repositories/app_repository.dart';
import '../services/auth_service.dart';
import '../services/health_data_provider.dart';
import '../services/readiness.dart';

class NguyenInDoubtState extends ChangeNotifier {
  NguyenInDoubtState({
    required this.repository,
    required this.healthDataProvider,
    this.authService = const DemoAuthService(),
  }) {
    _healthPermissionStatus = healthDataProvider.permissionStatus;

    final uid = authService.currentUid;
    if (uid == null) {
      // Demo / in-memory path — unchanged from before real auth. Tests and the
      // public demo land here (DemoAuthService always reports a null uid), so
      // the seeded session, demo users, and every behavior stay byte-identical.
      final demo = _demoRepository;
      _session = demo.currentSession;
      _currentUser = _userForSession(_session);
      refresh();
    } else {
      // Signed-in path — a real Firebase uid backs the app. Seed a calm
      // signed-out placeholder synchronously, then bootstrap the real profile
      // (ensureUser) and load their data. A freshly signed-up account has an
      // empty Firestore; the existing empty states render calmly (correct, not
      // a bug — no seeding happens here).
      _session = const AppSession.signedOut();
      _currentUser = AppUser(
        id: uid,
        displayName: 'You',
        role: UserRole.patient,
        consentStatus: ConsentStatus.notAsked,
      );
      _bootstrapSignedInUser(uid);
    }
  }

  final NidRepository repository;
  final HealthDataProvider healthDataProvider;
  final AuthService authService;

  /// True once a real signed-in uid backs this state. When false the app runs
  /// the in-memory demo exactly as before real auth existed.
  bool get isSignedInMode => authService.currentUid != null;

  /// The demo-only repository surface (seeded session, demo users, local
  /// persistence). Only valid on the demo path; the signed-in path never
  /// touches it. Guarded by [isSignedInMode] so a misuse fails loudly in
  /// debug rather than silently reading demo state under a real account.
  InMemoryAppRepository get _demoRepository {
    final repo = repository;
    assert(
      repo is InMemoryAppRepository,
      'Demo-only repository access requires an InMemoryAppRepository.',
    );
    return repo as InMemoryAppRepository;
  }

  /// Bootstraps a signed-in user: ensures their profile exists, then enters the
  /// patient experience backed by the real repository. Any failure degrades to
  /// a calm signed-out state rather than surfacing a raw error (project rule).
  Future<void> _bootstrapSignedInUser(String uid) async {
    _setBusy(true);
    try {
      final user = await repository.ensureUser(
        uid: uid,
        displayName: _currentUser.displayName,
        role: UserRole.patient,
      );
      _currentUser = user;
      _session = AppSession(stage: SessionStage.patient, userId: user.id);
      await refresh();
    } catch (error, stackTrace) {
      // Never surface a raw exception. Log for debugging; leave the user on a
      // calm signed-out screen so they can retry.
      debugPrint('[state] signed-in bootstrap failed: $error');
      debugPrintStack(stackTrace: stackTrace, label: 'signed-in bootstrap');
      _session = const AppSession.signedOut();
    } finally {
      _setBusy(false);
    }
  }

  late AppUser _currentUser;
  late AppSession _session;
  List<DailySummary> _summaries = [];
  ReadinessSummary? _readiness;
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

  /// Whether the brand-intro splash has already played this cold launch.
  /// Deliberately a plain in-memory bool — never persisted, never a counter,
  /// no analytics (ONB-01). Resets naturally on every cold start.
  bool splashHasPlayed = false;

  /// Marks the one-shot splash as played for this launch. No listeners need
  /// notifying — the splash gate drives its own rebuild.
  void markSplashPlayed() {
    splashHasPlayed = true;
  }

  AppSession get session => _session;
  SessionStage get sessionStage => _session.stage;
  AppUser get currentUser => _currentUser;
  List<DailySummary> get summaries => _summaries;

  /// The patient's current multi-signal readiness (Phase 14 Today hero).
  /// Null until wearable signals have been read at least once. Patient-only —
  /// the clinician surface never exposes readiness (sleep-only contract).
  ReadinessSummary? get readiness => _readiness;
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
      _readiness = null;
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
      // Load any persisted readiness; the most recent day is the Today hero.
      // Absent (no wearable read yet) leaves the hero on the sleep-score
      // fallback — an honest empty rather than a fabricated score.
      final readiness = await repository.getReadinessSummariesForPatient(
        requesterUserId: _currentUser.id,
        patientId: _currentUser.id,
      );
      _readiness = readiness.isEmpty ? null : readiness.last;
    } else {
      _summaries = [];
      _readiness = null;
      _journalEntries = [];
      _consentHistory = [];
      _linkedPatients = [];
      _clinicianLinkStatuses = [];
      _selectedPatientBundle = null;
    }
    notifyListeners();
  }

  Future<void> startPatientOnboarding() async {
    final demo = _demoRepository;
    _session = const AppSession(stage: SessionStage.onboarding);
    _currentUser = demo.patientDemo;
    await demo.saveSession(_session);
    await refresh();
  }

  Future<void> completePatientOnboarding({required String displayName}) async {
    final demo = _demoRepository;
    final normalizedName = displayName.trim().isEmpty
        ? demo.patientDemo.displayName
        : displayName.trim();
    _currentUser = await demo.updateDemoPatientProfile(
      displayName: normalizedName,
    );
    _session = AppSession(stage: SessionStage.patient, userId: _currentUser.id);
    await demo.saveSession(_session);
    await refresh();
  }

  Future<void> continueAsPatient() async {
    final demo = _demoRepository;
    _currentUser = demo.patientDemo;
    _session = AppSession(stage: SessionStage.patient, userId: _currentUser.id);
    await demo.saveSession(_session);
    await refresh();
  }

  Future<void> continueAsClinician() async {
    await continueAsClinicianDemo();
  }

  Future<void> continueAsClinicianDemo() async {
    final demo = _demoRepository;
    _currentUser = demo.clinicianDemo;
    _session = AppSession(
      stage: SessionStage.clinician,
      userId: _currentUser.id,
    );
    await demo.saveSession(_session);
    await refresh();
  }

  Future<void> signOut() async {
    // Signed-in mode: sign out through the provider. main.dart's AuthGate
    // listens to uidChanges and fades back to the LoginScreen — this state is
    // discarded and rebuilt fresh, so there is no demo session to restore.
    if (isSignedInMode) {
      await authService.signOut();
      return;
    }

    final demo = _demoRepository;
    _session = const AppSession.signedOut();
    _currentUser = demo.patientDemo;
    _summaries = [];
    _readiness = null;
    _journalEntries = [];
    _consentHistory = [];
    _linkedPatients = [];
    _clinicianLinkStatuses = [];
    _selectedPatientBundle = null;
    _inviteValidation = null;
    _healthPermissionStatus = HealthPermissionStatus.notRequested;
    await demo.saveSession(_session);
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
    } on PrivacyException {
      // Firebase mode intentionally throws here — invite acceptance needs a
      // trusted backend operation that isn't live yet. Surface it as calm
      // "not available" invite copy (project rule: no raw errors in the UI),
      // never an uncaught throw. The demo path never reaches this branch (its
      // acceptInvite succeeds once canAccept is true).
      _inviteValidation = InviteValidationResult(
        status: InviteValidationStatus.invalid,
        normalizedCode: validation.normalizedCode,
        clinicianDisplayName: validation.clinicianDisplayName,
        message:
            'Accepting invites is not available yet. We\'ll enable clinician '
            'sharing soon — nothing was changed.',
      );
      notifyListeners();
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
    } on PrivacyException catch (error) {
      // Calm surface for a Firebase-mode revoke that has nothing to revoke.
      // Demo mode only throws when there is genuinely no accepted link, which
      // the UI already guards, so the demo tests never hit this path.
      debugPrint('[state] revokeConsent unavailable: $error');
      _inviteValidation = InviteValidationResult(
        status: InviteValidationStatus.invalid,
        normalizedCode: '',
        message: 'Sharing controls are not available yet. Nothing was changed.',
      );
      notifyListeners();
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
      final range = HealthRange(
        start: DateTime.now().subtract(const Duration(days: 8)),
        end: DateTime.now().add(const Duration(days: 1)),
      );
      final samples = await healthDataProvider.fetchSleepSamples(range);
      await repository.saveImportedSleep(
        requesterUserId: currentUser.id,
        patientId: currentUser.id,
        samples: samples,
      );

      // Wearable-core (Phase 14): read the full multi-signal set and compute a
      // real readiness for the most recent day. Best-effort — a wearable gap
      // (partial permission, unsupported signal) simply yields a neutral
      // contributor via the scoring's null fallback, never a failed import.
      await _computeAndSaveReadiness(range);

      await refresh();
    } finally {
      _setBusy(false);
    }
  }

  /// Reads the multi-signal readiness samples for [range], reduces the most
  /// recent day into [ReadinessInputs], scores it against the recent-sleep
  /// window, and persists the resulting [ReadinessSummary]. Pure scoring lives
  /// in readiness.dart; this only orchestrates the read + persist. The sleep
  /// window uses the summaries just imported so the sleep-balance contributor
  /// reflects a window, not one night.
  Future<void> _computeAndSaveReadiness(HealthRange range) async {
    final samples = await healthDataProvider.fetchSamples(
      metrics: kReadinessMetricTypes,
      range: range,
    );
    if (samples.isEmpty) {
      return;
    }

    // The most recent sample day drives Today's readiness.
    DateTime dayOf(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
    final latestDay = samples
        .map((s) => dayOf(s.end))
        .reduce((a, b) => a.isAfter(b) ? a : b);
    final daySamples = samples
        .where((s) => dayOf(s.end) == latestDay)
        .toList();

    final recentSummaries = await repository.getDailySummariesForPatient(
      requesterUserId: currentUser.id,
      patientId: currentUser.id,
    );
    final recentSleepHours = recentSummaries
        .map((summary) => summary.sleepDurationHours)
        .toList();
    final latestSleepHours = recentSummaries.isEmpty
        ? null
        : recentSummaries.last.sleepDurationHours;

    final inputs = readinessInputsFromSamples(
      userId: currentUser.id,
      date: latestDay,
      samples: daySamples,
      sleepHours: latestSleepHours,
    );
    final summary = computeReadiness(
      inputs: inputs,
      recentSleepHours: recentSleepHours,
    );

    await repository.saveReadinessSummaries(
      requesterUserId: currentUser.id,
      patientId: currentUser.id,
      summaries: [summary],
    );
  }

  Future<void> resetDemoData() async {
    final demo = _demoRepository;
    _setBusy(true);
    try {
      await demo.resetDemoData();
      _session = const AppSession.signedOut();
      _currentUser = demo.patientDemo;
      _summaries = [];
      _readiness = null;
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

  Future<void> deleteJournalEntry(String id) async {
    await repository.deleteJournalEntry(
      requesterUserId: currentUser.id,
      entryId: id,
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

  // Demo-only: resolves the seeded user for a restored local session. Only
  // reached on the demo constructor path (currentUid == null).
  AppUser _userForSession(AppSession session) {
    final demo = _demoRepository;
    if (session.stage == SessionStage.clinician) {
      return demo.clinicianDemo;
    }

    return demo.patientDemo;
  }
}
