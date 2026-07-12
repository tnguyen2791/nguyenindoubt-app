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

/// A single "your markers, explained" row in Explore — a wearable signal the
/// app now reads, paired with its short abbreviation and a plain-language
/// InfoTip body. Static educational content (no wearable data flows through it),
/// so it is plain data with no Flutter dependency.
@immutable
class ExploreMarker {
  const ExploreMarker({
    required this.name,
    required this.abbr,
    required this.tip,
  });

  /// Full signal name shown in the row ("Heart rate variability").
  final String name;

  /// Compact abbreviation on the row's trailing edge ("HRV", "RHR", "°").
  final String abbr;

  /// Plain-language InfoTip body: what the signal is and what a change usually
  /// means, ending reassuring — never a warning, no exclamation marks.
  final String tip;
}

/// A short, non-diagnostic article or guided practice surfaced in Explore and
/// opened in the Article reader (design 72). Static seed content authored in
/// the brand voice: supportive, educational-not-medical, closing on
/// reassurance. Plain data — no Flutter dependency — so it stays test-friendly.
@immutable
class ExploreArticle {
  const ExploreArticle({
    required this.id,
    required this.kind,
    required this.title,
    required this.readMinutes,
    required this.rowSummary,
    required this.section,
    required this.reviewedBy,
    required this.updated,
    required this.lede,
    required this.body,
    required this.calloutTitle,
    required this.calloutBody,
    required this.practiceTitle,
    required this.practiceBody,
    required this.practiceCta,
    this.featured = false,
    this.readNextIds = const <String>[],
  });

  /// Stable id, used for read-next links and featured lookup.
  final String id;

  /// "Read" or "Practice" — drives the kicker/meta label and the featured
  /// card's eyebrow.
  final String kind;

  /// Article title / featured practice name.
  final String title;

  /// Estimated read/practice time in minutes.
  final int readMinutes;

  /// One-line summary shown on the Explore row beneath the title.
  final String rowSummary;

  /// Section eyebrow for the reader kicker ("Mind & mood").
  final String section;

  /// Reviewer attribution line (byline).
  final String reviewedBy;

  /// "Updated" recency label ("Jun 2026").
  final String updated;

  /// Opening lede paragraph.
  final String lede;

  /// Ordered body blocks — each an [ArticleBlock] (heading or paragraph).
  final List<ArticleBlock> body;

  /// "Worth knowing" callout heading + body.
  final String calloutTitle;
  final String calloutBody;

  /// "Try it now" practice card title, body, and CTA label.
  final String practiceTitle;
  final String practiceBody;
  final String practiceCta;

  /// Whether this is the Explore hero featured practice.
  final bool featured;

  /// Ids of the "Read next" rows at the foot of the reader.
  final List<String> readNextIds;
}

/// One block in an [ExploreArticle] body — either a section heading or a
/// paragraph. Paragraphs may carry a trailing inline InfoTip term/body.
@immutable
class ArticleBlock {
  const ArticleBlock.heading(this.text)
    : isHeading = true,
      tipTerm = null,
      tipBody = null;

  const ArticleBlock.paragraph(this.text, {this.tipTerm, this.tipBody})
    : isHeading = false;

  final String text;
  final bool isHeading;

  /// When non-null, an inline InfoTip is rendered after the paragraph for this
  /// term (design 72's inline `.tipdot`).
  final String? tipTerm;
  final String? tipBody;
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
