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

enum MetricType { sleep, steps, heartRate, hrv, mindfulMinutes, medication }

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
