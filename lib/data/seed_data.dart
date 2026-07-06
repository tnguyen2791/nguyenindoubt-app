import '../models/app_models.dart';

final nowSeed = DateTime.now();

final demoPatient = AppUser(
  id: 'patient-demo',
  displayName: 'Alex Rivera',
  role: UserRole.patient,
  consentStatus: ConsentStatus.notAsked,
);

final linkedPatient = AppUser(
  id: 'patient-linked',
  displayName: 'Maya Chen',
  role: UserRole.patient,
  consentStatus: ConsentStatus.granted,
  clinicCode: 'NID-8274',
);

const demoClinician = AppUser(
  id: 'clinician-demo',
  displayName: 'Dr. Nguyen',
  role: UserRole.clinician,
  consentStatus: ConsentStatus.notAsked,
);

List<ClinicianLink> seedClinicianLinks() {
  final now = DateTime.now();
  return [
    ClinicianLink(
      inviteCode: 'NID-8274',
      clinicianUserId: demoClinician.id,
      patientUserId: linkedPatient.id,
      status: LinkStatus.accepted,
      createdAt: now.subtract(const Duration(days: 8)),
      updatedAt: now.subtract(const Duration(days: 7)),
    ),
    ClinicianLink(
      inviteCode: 'NID-1138',
      clinicianUserId: demoClinician.id,
      patientUserId: demoPatient.id,
      status: LinkStatus.pending,
      createdAt: now.subtract(const Duration(days: 1)),
      updatedAt: now.subtract(const Duration(days: 1)),
    ),
  ];
}

List<HealthSample> seedLinkedSleepSamples() {
  final durations = <double>[6.2, 6.5, 7.0, 7.2, 5.9, 6.8, 7.6];
  final now = DateTime.now();
  return List.generate(durations.length, (index) {
    final end = DateTime(
      now.year,
      now.month,
      now.day,
      7,
      10,
    ).subtract(Duration(days: durations.length - index - 1));
    final start = end.subtract(
      Duration(minutes: (durations[index] * 60).round()),
    );
    return HealthSample(
      userId: linkedPatient.id,
      source: 'Apple Health mock',
      metricType: MetricType.sleep,
      start: start,
      end: end,
      value: durations[index],
      unit: 'hours',
      createdAt: now,
    );
  });
}

List<JournalEntry> seedJournalEntries() {
  return [
    JournalEntry(
      id: 'journal-1',
      userId: demoPatient.id,
      title: 'The part I keep avoiding',
      body:
          'I noticed I sleep less when I try to solve tomorrow before it arrives.',
      moodTag: 'uneasy',
      createdAt: DateTime.now().subtract(const Duration(hours: 8)),
    ),
    JournalEntry(
      id: 'journal-2',
      userId: linkedPatient.id,
      title: 'A steadier morning',
      body:
          'I woke up before the alarm. Not fixed, not magic, but a little more room.',
      moodTag: 'steady',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];
}

const seedResources = [
  ResourceCard(
    id: 'sleep-basics',
    title: 'Sleep is data, not a verdict',
    category: 'Sleep',
    body:
        'Look for patterns across a week. One rough night can mean stress, schedule drift, caffeine, pain, screens, or nothing obvious at all.',
    disclaimer:
        'Educational only. Bring persistent insomnia, nightmares, or safety concerns to a clinician.',
    sortOrder: 1,
  ),
  ResourceCard(
    id: 'medication-basics',
    title: 'Medication questions worth writing down',
    category: 'Medication',
    body:
        'Track benefits, side effects, missed doses, sleep changes, appetite, and the question you forget as soon as the appointment starts.',
    disclaimer: 'Do not start, stop, or change medication based on this app.',
    sortOrder: 2,
  ),
  ResourceCard(
    id: 'therapy-fit',
    title: 'Therapy can be useful before it feels useful',
    category: 'Therapy',
    body:
        'A good session is not always dramatic. Sometimes the work is noticing a pattern with enough honesty that it loosens.',
    disclaimer:
        'This is not therapy and does not replace a therapeutic relationship.',
    sortOrder: 3,
  ),
  ResourceCard(
    id: 'parenting-life',
    title: 'When the house carries the symptom',
    category: 'Parenting and life',
    body:
        'Sleep, conflict, school pressure, and phone rhythms often travel together. Start by naming the pattern without assigning blame.',
    disclaimer:
        'For family education only. Seek professional help for escalating conflict or safety concerns.',
    sortOrder: 4,
  ),
  ResourceCard(
    id: 'not-enough',
    title: 'When this app is not enough',
    category: 'Safety',
    body:
        'If there is danger, possible self-harm, harm to someone else, psychosis, intoxication, or you cannot stay safe, use urgent help now.',
    disclaimer:
        'In the U.S., call or text 988 for the Suicide and Crisis Lifeline. Call 911 for immediate danger.',
    crisisFlag: true,
    sortOrder: 0,
  ),
];
