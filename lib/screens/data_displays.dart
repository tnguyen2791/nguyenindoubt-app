/// Reusable Oura-style data-display widgets — the Phase 11 kit.
///
/// Everything here is CustomPaint / plain widgets (no chart package) and
/// every color resolves through [NidColors] / [NidStateColors] — never a hex
/// literal in widget code. Motion stays gentle: the score arc eases in over
/// 600ms; nothing pops.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/sleep_insights.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// Maps a [StateTone] to its blessed theme color.
Color nidToneColor(StateTone tone) {
  switch (tone) {
    case StateTone.optimal:
      return NidStateColors.optimal;
    case StateTone.good:
      return NidStateColors.good;
    case StateTone.fair:
      return NidStateColors.fair;
    case StateTone.attention:
      return NidStateColors.attention;
  }
}

/// The hero score readout: a mint ring track with a state-colored arc that
/// eases in, wrapping the score number and its state word.
class ScoreRing extends StatelessWidget {
  const ScoreRing({
    super.key,
    required this.score,
    required this.word,
    required this.color,
    this.size = 120,
    this.strokeWidth = 12,
  });

  final int score;
  final String word;
  final Color color;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: score.toDouble()),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        builder: (context, animatedScore, child) {
          return CustomPaint(
            painter: _ScoreRingPainter(
              progress: animatedScore / 100,
              color: color,
              trackColor: NidColors.mint,
              strokeWidth: strokeWidth,
            ),
            child: child,
          );
        },
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score',
                style: TextStyle(
                  // Proportional to the ring so the number reads right at any
                  // size (34 @120). letterSpacing stays -0.02em @34.
                  fontSize: (size * 0.28).round().toDouble(),
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.68,
                  color: NidColors.ink,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                word,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: NidColors.slate,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreRingPainter extends CustomPainter {
  const _ScoreRingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    // Design -3 inset so the ring sits a hair inside its box (51 @120).
    final radius = ((size.shortestSide - strokeWidth) / 2) - 3;

    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, track);

    if (progress <= 0) {
      return;
    }
    final arc = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant _ScoreRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

/// One explainable score factor: name, state word, and a thin filled track.
class ContributorBar extends StatelessWidget {
  const ContributorBar({
    super.key,
    required this.name,
    required this.word,
    required this.tone,
    required this.fraction,
    this.infoTip,
  });

  final String name;
  final String word;
  final StateTone tone;
  final double fraction;
  final Widget? infoTip;

  @override
  Widget build(BuildContext context) {
    final toneColor = nidToneColor(tone);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              name,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: NidColors.contributorName,
              ),
            ),
            ?infoTip,
            const Spacer(),
            Text(
              word,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: toneColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Container(
          height: 7,
          decoration: BoxDecoration(
            color: NidColors.mint,
            borderRadius: BorderRadius.circular(NidRadius.pill),
          ),
          child: FractionallySizedBox(
            widthFactor: fraction.clamp(0.0, 1.0),
            alignment: Alignment.centerLeft,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: toneColor,
                borderRadius: BorderRadius.circular(NidRadius.pill),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A small "i" affordance that opens a plain-language educational card.
///
/// Mandatory beside metric names a newcomer might not know. Body copy voice
/// (callers supply it): 1-2 sentences — what the metric is, plus what a
/// change usually means — ending reassuring, never a warning, and never an
/// exclamation mark.
class InfoTip extends StatelessWidget {
  const InfoTip({super.key, required this.term, required this.body});

  final String term;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 5),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          showDialog<void>(
            context: context,
            builder: (dialogContext) {
              return AlertDialog(
                title: Text(
                  term,
                  style: Theme.of(dialogContext).textTheme.titleMedium,
                ),
                content: Text(
                  body,
                  style: Theme.of(dialogContext).textTheme.bodyMedium,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Got it'),
                  ),
                ],
              );
            },
          );
        },
        child: Container(
          width: 15,
          height: 15,
          decoration: BoxDecoration(
            color: NidColors.mint,
            shape: BoxShape.circle,
            border: Border.all(color: NidColors.canopy.withValues(alpha: 0.14)),
          ),
          child: const Center(
            child: Text(
              'i',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                fontStyle: FontStyle.italic,
                color: NidColors.canopy,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The stat-delta idiom: metric name (with optional sub-line) on the left,
/// value over a directional delta word on the right.
class StatDeltaRow extends StatelessWidget {
  const StatDeltaRow({
    super.key,
    required this.name,
    this.sub,
    required this.value,
    required this.delta,
    this.flagged = false,
  });

  final String name;
  final String? sub;
  final String value;
  final String delta;
  final bool flagged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: NidColors.ink,
                ),
              ),
              if (sub != null)
                Text(
                  sub!,
                  style: const TextStyle(fontSize: 12, color: NidColors.faint),
                ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: NidColors.ink,
              ),
            ),
            Text(
              delta,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: flagged ? NidColors.ember : NidColors.moss,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
