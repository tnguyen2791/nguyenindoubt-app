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

const expiredInvitePatient = AppUser(
  id: 'patient-expired',
  displayName: 'Jordan Lee',
  role: UserRole.patient,
  consentStatus: ConsentStatus.notAsked,
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
    ClinicianLink(
      inviteCode: 'NID-4455',
      clinicianUserId: demoClinician.id,
      patientUserId: expiredInvitePatient.id,
      status: LinkStatus.expired,
      createdAt: now.subtract(const Duration(days: 15)),
      updatedAt: now.subtract(const Duration(days: 8)),
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

/// The "your markers, explained" strip for Explore (design 70). Reassurance-
/// first InfoTip copy for the wearable signals the app now reads — voice per
/// brand-readme (what it is, what a change usually means, ends reassuring, no
/// exclamation marks).
const seedExploreMarkers = [
  ExploreMarker(
    name: 'Heart rate variability',
    abbr: 'HRV',
    tip:
        'The tiny timing differences between heartbeats. Higher usually means '
        'your system is rested; a dip after a stressful day is normal and '
        'recovers with rest.',
  ),
  ExploreMarker(
    name: 'Resting heart rate',
    abbr: 'RHR',
    tip:
        'Your heart rate at rest, compared to your own norm. A slightly higher '
        'morning can follow a hard day or a short night, and it usually settles '
        'again on its own.',
  ),
  ExploreMarker(
    name: 'Temperature deviation',
    abbr: '°',
    tip:
        'Overnight skin temperature vs your baseline. Small drifts are normal; '
        'a sustained rise can follow a demanding stretch and eases back down '
        'with rest.',
  ),
  ExploreMarker(
    name: 'Readiness',
    abbr: '0–100',
    tip:
        'A calm read on how recovered you are, blending your overnight signals '
        'against your own baseline. It is observational — a starting point for '
        'the day, never a diagnosis.',
  ),
];

/// The Explore article + practice library (design 70/72). Static, supportive,
/// non-diagnostic reads authored in the brand voice — each closes on
/// reassurance, and mood-facing reads point to 988. Ordered as they appear in
/// Explore: the featured practice first, then the Mind & mood rows.
const seedExploreArticles = [
  ExploreArticle(
    id: 'box-breathing',
    kind: 'Practice',
    title: 'Box breathing',
    readMinutes: 4,
    rowSummary: 'a four-count in, hold, out, hold — to settle a spiking moment',
    section: 'Practice',
    reviewedBy: 'Reviewed by the NiD care team',
    updated: 'Jun 2026',
    lede:
        'A steady four-count in, hold, out, hold. One round settles a spiking '
        'moment; four rounds settle an evening. It is one of the few things you '
        'can do in sixty seconds that your body actually notices.',
    body: [
      ArticleBlock.heading('How it works'),
      ArticleBlock.paragraph(
        'Slow, even breathing gently nudges your nervous system out of a '
        'braced, alert state and toward rest. You are not forcing calm — you '
        'are giving your body a clear, unhurried rhythm to follow.',
        tipTerm: 'HRV',
        tipBody:
            'Heart rate variability: the tiny timing differences between '
            'heartbeats. Slow breathing tends to widen it, which usually reads '
            'as more rested.',
      ),
      ArticleBlock.heading('The four counts'),
      ArticleBlock.paragraph(
        'Breathe in for four counts. Hold for four. Breathe out for four. '
        'Hold for four. That is one round. Keep the counts loose and '
        'comfortable — if four feels long, use three; the shape matters more '
        'than the exact number.',
      ),
      ArticleBlock.paragraph(
        'Repeat for four rounds, about four minutes. If your mind wanders, '
        'that is expected — just return to the count. Nothing here has to be '
        'perfect to work.',
      ),
    ],
    calloutTitle: 'Worth knowing',
    calloutBody:
        'One round can take the edge off a sharp moment. The evening version — '
        'four unhurried rounds before bed — is where it does the quiet work.',
    practiceTitle: 'Try it now',
    practiceBody:
        'Box breathing — four counts in, hold, out, hold. Four rounds, four '
        'minutes, and you can feel the shift within the hour.',
    practiceCta: 'Begin practice',
    featured: true,
    readNextIds: ['stress-signature', 'wind-down'],
  ),
  ExploreArticle(
    id: 'stress-signature',
    kind: 'Read',
    title: 'Stress leaves a signature',
    readMinutes: 3,
    rowSummary: 'how tension shows up in HRV before you feel it',
    section: 'Mind & mood',
    reviewedBy: 'Reviewed by the NiD science team',
    updated: 'Jun 2026',
    lede:
        "Long before you'd call a day \"stressful,\" your body has already "
        'filed a report. It shows up in the space between heartbeats — and '
        'learning to read it is the point of this app.',
    body: [
      ArticleBlock.heading('The signal under the noise'),
      ArticleBlock.paragraph(
        "Your heart doesn't beat like a metronome. The gaps between beats "
        'stretch and shrink slightly with every breath, and that variation — '
        'HRV — reflects how much capacity your nervous system has in reserve. '
        'Under sustained tension, the variation flattens: the body idles '
        'higher, ready for a threat that usually never comes.',
        tipTerm: 'HRV',
        tipBody:
            'Heart rate variability: the tiny timing differences between '
            'heartbeats. Higher usually means your system is rested.',
      ),
      ArticleBlock.paragraph(
        'That is why a demanding week often appears in your readings before it '
        'appears in your mood. A lower HRV trend, a slightly raised resting '
        'heart rate, a warmer night — none of these mean something is wrong. '
        'They mean your body is working harder than usual, and it is telling '
        'you.',
      ),
      ArticleBlock.heading('What to do with it'),
      ArticleBlock.paragraph(
        'Nothing dramatic. The useful response to a stress signature is almost '
        'always small: shorten the evening, move gently instead of hard, put '
        'the phone down earlier. Your baseline was built from your own calm '
        'weeks — getting back to it is the whole goal, and it usually takes '
        'days, not willpower.',
      ),
      ArticleBlock.paragraph(
        "And if the tension you're carrying feels bigger than a busy week — "
        'persistent, heavy, or hard to name — that is not a data problem. '
        'Talking to someone helps more than any metric will.',
      ),
    ],
    calloutTitle: 'Worth knowing',
    calloutBody:
        'One flat reading is noise. Three in a row is a pattern. That is when '
        'a lighter day, an earlier night, or ten unhurried minutes actually '
        'pays off.',
    practiceTitle: 'Try it now',
    practiceBody:
        'Box breathing — four counts in, hold, out, hold. Four rounds, four '
        'minutes, measurable within the hour.',
    practiceCta: 'Begin practice',
    readNextIds: ['anxiety-sleep', 'low-days'],
  ),
  ExploreArticle(
    id: 'anxiety-sleep',
    kind: 'Read',
    title: 'Anxiety and sleep: breaking the loop',
    readMinutes: 5,
    rowSummary: 'why worried nights compound, and where to interrupt',
    section: 'Mind & mood',
    reviewedBy: 'Reviewed by the NiD science team',
    updated: 'Jun 2026',
    lede:
        'Anxiety and short sleep feed each other: a worried night frays the '
        'next day, and a frayed day writes the next worried night. The loop is '
        'real — and it has more than one place to interrupt it.',
    body: [
      ArticleBlock.heading('Why the loop tightens'),
      ArticleBlock.paragraph(
        'A racing mind at bedtime keeps the body a little too alert to drift '
        'off. Lose an hour, and the next day runs on a shorter fuse, which '
        'makes the evening worries louder. None of this means you are doing it '
        'wrong — it means the loop is doing exactly what loops do.',
      ),
      ArticleBlock.heading('Where to interrupt it'),
      ArticleBlock.paragraph(
        'You do not have to fix the whole cycle at once. A wind-down that '
        'starts thirty minutes earlier, a notebook by the bed for the '
        'thoughts that will not wait, a few slow breaths — small interruptions '
        'compound in your favor, the same way the loop compounds against you.',
      ),
      ArticleBlock.paragraph(
        'If worried nights have become most nights, that is worth more than a '
        'self-help fix. Talking to a clinician can loosen a knot that '
        'willpower keeps tightening.',
      ),
    ],
    calloutTitle: 'Worth knowing',
    calloutBody:
        'Sleep tonight is shaped as much by this morning as by this evening — '
        'light, movement, and an unhurried wind-down all count as sleep '
        'support.',
    practiceTitle: 'Try it now',
    practiceBody:
        'A racing-mind wind-down: a slow body scan from feet to forehead, '
        'letting each part go heavy. Ten minutes, lights low.',
    practiceCta: 'Begin practice',
    readNextIds: ['stress-signature', 'low-days'],
  ),
  ExploreArticle(
    id: 'low-days',
    kind: 'Read',
    title: 'Low days are data, not verdicts',
    readMinutes: 4,
    rowSummary: 'reading a rough patch without spiraling on it',
    section: 'Mind & mood',
    reviewedBy: 'Reviewed by the NiD science team',
    updated: 'Jun 2026',
    lede:
        'A low day is information, not a judgment. Your readings might dip, '
        'your mood with them — and the most useful thing you can do is read it '
        'plainly, without turning one hard day into a story about who you are.',
    body: [
      ArticleBlock.heading('A dip is a data point'),
      ArticleBlock.paragraph(
        'Bodies have off days for reasons that never fully announce '
        'themselves: a short night, a hard week catching up, a season '
        'shifting. A lower reading describes the day, not the person having '
        'it.',
      ),
      ArticleBlock.heading('Reading it without spiraling'),
      ArticleBlock.paragraph(
        'The trap is not the low day — it is the second story we tell about '
        'it. Notice the dip, meet it with a lighter plan, and let the week be '
        'the unit that matters. One point rarely means much; the shape over '
        'time means more.',
      ),
      ArticleBlock.paragraph(
        'And if the low days are stacking up — heavier, longer, or harder to '
        'climb out of — that is exactly when reaching out matters most. You do '
        'not have to wait until it is a crisis to talk to someone.',
      ),
    ],
    calloutTitle: 'Worth knowing',
    calloutBody:
        'If a low stretch lingers for more than a couple of weeks, or the days '
        'feel heavy in a way that is hard to name, talking to a clinician is a '
        'strong, ordinary next step.',
    practiceTitle: 'Try it now',
    practiceBody:
        'A two-minute reset: name one thing that felt heavy and one small '
        'thing within reach today. Written down, both get a little smaller.',
    practiceCta: 'Begin practice',
    readNextIds: ['stress-signature', 'wind-down'],
  ),
  ExploreArticle(
    id: 'wind-down',
    kind: 'Practice',
    title: 'A wind-down that actually works',
    readMinutes: 10,
    rowSummary: 'a body scan for racing-mind evenings',
    section: 'Practice',
    reviewedBy: 'Reviewed by the NiD care team',
    updated: 'Jun 2026',
    lede:
        'A wind-down is not about doing more — it is about doing less, on '
        'purpose, in an order your body can follow toward sleep. This one is a '
        'slow body scan for the evenings when your mind will not stop '
        'narrating.',
    body: [
      ArticleBlock.heading('Set the room'),
      ArticleBlock.paragraph(
        'Lower the lights, put the phone across the room, and let the day '
        'officially be over. You are signaling to your body that the work of '
        'the day is done — and it takes that signal seriously.',
      ),
      ArticleBlock.heading('The body scan'),
      ArticleBlock.paragraph(
        'Lying down, bring gentle attention to your feet, then let them go '
        'heavy. Move slowly upward — calves, hips, hands, shoulders, jaw, '
        'forehead — releasing each part as you pass it. If your mind wanders '
        'to tomorrow, that is fine; just return to the next part of the body.',
      ),
      ArticleBlock.paragraph(
        'There is no finish line to reach. If you fall asleep partway through, '
        'the practice worked. If you do not, you are still more rested than '
        'when you started.',
      ),
    ],
    calloutTitle: 'Worth knowing',
    calloutBody:
        'A wind-down works best as a rhythm, not a rescue. Done most nights, '
        'it quietly lowers the effort of falling asleep over a week or two.',
    practiceTitle: 'Try it now',
    practiceBody:
        'A slow body scan from feet to forehead, letting each part go heavy. '
        'Ten minutes, lights low, phone away.',
    practiceCta: 'Begin practice',
    readNextIds: ['anxiety-sleep', 'box-breathing'],
  ),
];

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
