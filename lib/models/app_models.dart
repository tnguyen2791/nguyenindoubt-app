import 'package:flutter/foundation.dart';

enum UserRole { patient, clinician, admin }

enum ConsentStatus { notAsked, granted, revoked }

enum LinkStatus { pending, accepted, revoked, expired }

enum InviteValidationStatus {
  valid,
  empty,
  invalid,
  expired,
  alreadyAccepted,
  revoked,
  missing,
  malformed,
  wrongPatient,
}

enum ConsentEventAction { accepted, revoked }

enum MetricType {
  sleep,
  steps,
  heartRate,
  hrv,
  mindfulMinutes,
  medication,
  // Wearable-core signals (Phase 13). These widen the pipeline beyond sleep so
  // readiness can be a real multi-signal score. Existing values are unchanged.
  restingHeartRate,
  respiratoryRate,
  temperature,
  bloodOxygen,
  activeEnergy,
}

enum SessionStage { signedOut, onboarding, patient, clinician }

@immutable
class AppSession {
  const AppSession({required this.stage, this.userId});

  const AppSession.signedOut() : stage = SessionStage.signedOut, userId = null;

  final SessionStage stage;
  final String? userId;

  bool get isAuthenticated =>
      stage == SessionStage.patient || stage == SessionStage.clinician;
}

@immutable
class AppUser {
  const AppUser({
    required this.id,
    required this.displayName,
    required this.role,
    required this.consentStatus,
    this.clinicCode,
  });

  final String id;
  final String displayName;
  final UserRole role;
  final ConsentStatus consentStatus;
  final String? clinicCode;

  AppUser copyWith({
    String? id,
    String? displayName,
    UserRole? role,
    ConsentStatus? consentStatus,
    String? clinicCode,
    bool clearClinicCode = false,
  }) {
    return AppUser(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      consentStatus: consentStatus ?? this.consentStatus,
      clinicCode: clearClinicCode ? null : clinicCode ?? this.clinicCode,
    );
  }
}

@immutable
class ClinicianLink {
  const ClinicianLink({
    required this.inviteCode,
    required this.clinicianUserId,
    required this.patientUserId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String inviteCode;
  final String clinicianUserId;
  final String patientUserId;
  final LinkStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
}

@immutable
class InviteValidationResult {
  const InviteValidationResult({
    required this.status,
    required this.normalizedCode,
    required this.message,
    this.patientUserId,
    this.clinicianUserId,
    this.clinicianDisplayName,
  });

  final InviteValidationStatus status;
  final String normalizedCode;
  final String message;
  final String? patientUserId;
  final String? clinicianUserId;
  final String? clinicianDisplayName;

  bool get canAccept => status == InviteValidationStatus.valid;
}

@immutable
class ConsentHistoryEvent {
  const ConsentHistoryEvent({
    required this.id,
    required this.patientUserId,
    required this.clinicianUserId,
    required this.inviteCode,
    required this.previousStatus,
    required this.nextStatus,
    required this.action,
    required this.actorUserId,
    required this.occurredAt,
  });

  final String id;
  final String patientUserId;
  final String clinicianUserId;
  final String inviteCode;
  final ConsentStatus previousStatus;
  final ConsentStatus nextStatus;
  final ConsentEventAction action;
  final String actorUserId;
  final DateTime occurredAt;
}

@immutable
class ClinicianLinkStatusView {
  const ClinicianLinkStatusView({
    required this.patientUserId,
    required this.inviteCode,
    required this.status,
    required this.updatedAt,
    this.patientDisplayName,
  });

  final String patientUserId;
  final String? patientDisplayName;
  final String inviteCode;
  final LinkStatus status;
  final DateTime updatedAt;

  bool get canOpenSleepSummary => status == LinkStatus.accepted;
}

@immutable
class HealthRange {
  const HealthRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;
}

@immutable
class HealthSample {
  const HealthSample({
    required this.userId,
    required this.source,
    required this.metricType,
    required this.start,
    required this.end,
    required this.value,
    required this.unit,
    required this.createdAt,
  });

  final String userId;
  final String source;
  final MetricType metricType;
  final DateTime start;
  final DateTime end;
  final double value;
  final String unit;
  final DateTime createdAt;
}

@immutable
class DailySummary {
  const DailySummary({
    required this.userId,
    required this.date,
    required this.sleepDurationHours,
    required this.sleepQualityProxy,
    required this.trendFlag,
  });

  final String userId;
  final DateTime date;
  final double sleepDurationHours;
  final int sleepQualityProxy;
  final String trendFlag;
}

/// One explainable factor behind a [ReadinessSummary].
///
/// Each contributor carries its own observational state word derived from its
/// own value vs a personal baseline — so the evidence always matches the label.
/// Plain data by construction: no Flutter, no derivation logic here, so it
/// serializes cleanly to Firestore and round-trips through the in-memory store.
@immutable
class ReadinessContributor {
  const ReadinessContributor({
    required this.metric,
    required this.name,
    required this.word,
    required this.fraction,
    this.value,
    this.unit,
  });

  /// The wearable signal this contributor summarizes.
  final MetricType metric;

  /// Display name matching the design ("Resting HR", "HRV balance", ...).
  final String name;

  /// The contributor's own observational state word (optimal/good/fair/
  /// pay attention). Non-diagnostic — describes the metric, never the person.
  final String word;

  /// Subscore expressed 0.0-1.0 for the contributor track fill.
  final double fraction;

  /// The raw signal value shown beside the bar (e.g. 51 bpm), when available.
  final double? value;

  /// Unit for [value] (e.g. 'bpm', 'ms', '°C').
  final String? unit;
}

/// A pure, non-diagnostic multi-signal readiness for one day.
///
/// Replaces the fake `sleepQualityProxy` with a genuine multi-factor score
/// computed from HRV, resting HR, respiratory rate, temperature deviation,
/// prior-day activity, and sleep. Patient-facing only — the clinician surface
/// stays sleep-summaries-only per the standing privacy contract.
@immutable
class ReadinessSummary {
  const ReadinessSummary({
    required this.userId,
    required this.date,
    required this.readinessScore,
    required this.state,
    required this.contributors,
  });

  final String userId;
  final DateTime date;

  /// Overall readiness, 0-100.
  final int readinessScore;

  /// Observational state word for the overall score (protective/balanced/
  /// fair/pay attention).
  final String state;

  /// Per-signal contributors behind the score, in display order.
  final List<ReadinessContributor> contributors;
}

@immutable
class JournalEntry {
  const JournalEntry({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.createdAt,
    this.moodTag,
    this.privateByDefault = true,
  });

  final String id;
  final String userId;
  final String title;
  final String body;
  final String? moodTag;
  final DateTime createdAt;
  final bool privateByDefault;
}

@immutable
class ResourceCard {
  const ResourceCard({
    required this.id,
    required this.title,
    required this.category,
    required this.body,
    required this.disclaimer,
    required this.sortOrder,
    this.crisisFlag = false,
  });

  final String id;
  final String title;
  final String category;
  final String body;
  final String disclaimer;
  final bool crisisFlag;
  final int sortOrder;
}

@immutable
class PatientSleepBundle {
  const PatientSleepBundle({
    required this.patient,
    required this.summaries,
    required this.samples,
  });

  final AppUser patient;
  final List<DailySummary> summaries;
  final List<HealthSample> samples;
}
