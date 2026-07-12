/// The Explore tab (design 70) and the Article reader (design 72).
///
/// Explore is the app's calm learning surface: a featured practice, a "your
/// markers, explained" InfoTip strip for the wearable signals the app reads,
/// Mind & mood article rows, and a closing disclaimer folded around the crisis
/// 988 line. Everything here is static, supportive, non-diagnostic content
/// (no wearable data flows through it), so it is fully verifiable on web/sim.
///
/// The crisis/Safety surface stays reachable: the disclaimer's 988 line is a
/// tappable route into the existing [SafetyScreen] (standing project rule), and
/// the Profile tab keeps its own Safety row.
library;

import 'package:flutter/material.dart';

import '../data/seed_data.dart';
import '../models/app_models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'common_widgets.dart';
import 'data_displays.dart';
import 'detail_screens.dart';
import 'resources_screen.dart';
import 'tab_shells.dart';

/// The Explore tab surface. Rebuilt to 70-explore's grammar while keeping the
/// existing crisis content reachable through the 988 disclaimer line.
class ExploreScreen extends StatelessWidget {
  const ExploreScreen({
    super.key,
    required this.state,
    this.articles = seedExploreArticles,
    this.markers = seedExploreMarkers,
  });

  // Kept for parity with the other tab shells (and future data-aware Explore
  // content); Explore is static educational content today.
  // ignore: unused_field
  final NguyenInDoubtState state;

  final List<ExploreArticle> articles;
  final List<ExploreMarker> markers;

  ExploreArticle get _featured =>
      articles.firstWhere((a) => a.featured, orElse: () => articles.first);

  List<ExploreArticle> get _mindAndMood =>
      articles.where((a) => !a.featured).toList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final featured = _featured;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        NidSpace.l,
        NidSpace.xl,
        NidSpace.l,
        NidSpace.l,
      ),
      children: [
        Text(
          'Explore',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontSize: 26,
            color: NidColors.canopy,
            letterSpacing: -0.52,
          ),
        ),
        const SizedBox(height: NidSpace.xs),
        Text(
          'Short reads and practices — learn what your body is telling you.',
          style: theme.textTheme.bodyMedium?.copyWith(color: NidColors.slate),
        ),
        const SizedBox(height: NidSpace.l),

        // Featured practice — the mint hero card.
        _FeaturedPracticeCard(
          article: featured,
          onBegin: () => openArticle(context, featured, articles),
        ),

        const SizedBox(height: NidSpace.m),
        const SectionKicker('Your markers, explained'),
        const SizedBox(height: NidSpace.m),
        _MarkersCard(markers: markers),

        const SizedBox(height: NidSpace.l),
        const SectionKicker('Mind & mood'),
        const SizedBox(height: NidSpace.m),
        for (final article in _mindAndMood) ...[
          _ArticleRow(
            article: article,
            onTap: () => openArticle(context, article, articles),
          ),
          const SizedBox(height: NidSpace.s),
        ],

        const SizedBox(height: NidSpace.m),
        _ExploreDisclaimer(onCrisis: () => openSafety(context)),
      ],
    );
  }
}

/// The mint featured-practice hero (design `.feat`): a moss eyebrow with the
/// kind + minutes, a canopy title, a supportive line, and a canopy Begin pill.
class _FeaturedPracticeCard extends StatelessWidget {
  const _FeaturedPracticeCard({required this.article, required this.onBegin});

  final ExploreArticle article;
  final VoidCallback onBegin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(NidSpace.l + 4),
      decoration: BoxDecoration(
        color: NidColors.mint,
        borderRadius: BorderRadius.circular(NidRadius.cardLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${article.kind} · ${article.readMinutes} min',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.9,
              color: NidColors.moss,
            ),
          ),
          const SizedBox(height: NidSpace.xs + 2),
          Text(
            article.title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.19,
              color: NidColors.canopy,
            ),
          ),
          const SizedBox(height: NidSpace.xs + 2),
          Text(
            article.lede,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: NidColors.slate,
            ),
          ),
          const SizedBox(height: NidSpace.m),
          Align(
            alignment: Alignment.centerLeft,
            child: Material(
              color: NidColors.canopy,
              borderRadius: BorderRadius.circular(NidRadius.pill),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onBegin,
                child: const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: NidSpace.l + 2,
                    vertical: NidSpace.s + 1,
                  ),
                  child: Text(
                    'Begin',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The "your markers, explained" card (design `.card` + `.mrow`): one row per
/// wearable signal, each carrying an [InfoTip] and a faint trailing abbr.
class _MarkersCard extends StatelessWidget {
  const _MarkersCard({required this.markers});

  final List<ExploreMarker> markers;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        children: [
          for (var i = 0; i < markers.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                color: NidColors.canopy.withValues(alpha: 0.14),
              ),
            _MarkerRow(marker: markers[i]),
          ],
        ],
      ),
    );
  }
}

class _MarkerRow extends StatelessWidget {
  const _MarkerRow({required this.marker});

  final ExploreMarker marker;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: NidSpace.m - 1),
      child: Row(
        children: [
          Flexible(
            child: Text(
              marker.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: NidColors.ink,
              ),
            ),
          ),
          InfoTip(term: marker.name, body: marker.tip),
          const Spacer(),
          Text(
            marker.abbr,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: NidColors.faint,
            ),
          ),
        ],
      ),
    );
  }
}

/// A Mind & mood article row (design `.art`): a mint icon tile, a title over a
/// kind · time · summary meta line, and a trailing chevron.
class _ArticleRow extends StatelessWidget {
  const _ArticleRow({required this.article, required this.onTap});

  final ExploreArticle article;
  final VoidCallback onTap;

  IconData get _icon => switch (article.id) {
    'stress-signature' => Icons.psychology_outlined,
    'anxiety-sleep' => Icons.nightlight_outlined,
    'low-days' => Icons.favorite_outline,
    'wind-down' => Icons.self_improvement_outlined,
    _ => Icons.menu_book_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(NidRadius.card),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(NidRadius.card),
            border: Border.all(color: NidColors.canopy.withValues(alpha: 0.14)),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: NidSpace.l,
            vertical: NidSpace.m + 3,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: NidColors.mint,
                  borderRadius: BorderRadius.circular(NidRadius.tile),
                ),
                child: Icon(_icon, size: 20, color: NidColors.canopy),
              ),
              const SizedBox(width: NidSpace.m + 1),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                        color: NidColors.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${article.kind} · ${article.readMinutes} min — '
                      '${article.rowSummary}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: NidColors.faint,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: NidSpace.s),
              const Icon(Icons.chevron_right, size: 18, color: NidColors.faint),
            ],
          ),
        ),
      ),
    );
  }
}

/// The closing disclaimer + crisis 988 line (design `.disc`). "Educational,
/// not medical advice — and never a diagnosis," then a reassuring 988 pointer.
/// The whole block taps through to the reachable Safety surface so the crisis
/// line is never a dead end.
class _ExploreDisclaimer extends StatelessWidget {
  const _ExploreDisclaimer({required this.onCrisis});

  final VoidCallback onCrisis;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onCrisis,
      borderRadius: BorderRadius.circular(NidRadius.control),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: NidSpace.s,
          vertical: NidSpace.s,
        ),
        child: Column(
          children: [
            const Text(
              'Educational, not medical advice — and never a diagnosis.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.6,
                color: NidColors.faint,
              ),
            ),
            const SizedBox(height: NidSpace.xs),
            Text.rich(
              const TextSpan(
                children: [
                  TextSpan(
                    text: 'If things feel heavy, talking helps. ',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: NidColors.slate,
                    ),
                  ),
                  TextSpan(text: 'In the US, call or text '),
                  TextSpan(
                    text: '988',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: NidColors.canopy,
                    ),
                  ),
                  TextSpan(text: ' anytime.'),
                ],
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                height: 1.6,
                color: NidColors.faint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pushes the existing Safety surface as a gentle fade — the reachable crisis
/// route folded behind Explore's 988 line (standing project rule).
void openSafety(BuildContext context) {
  Navigator.of(context).push(
    fadeDetailRoute<void>(
      Scaffold(
        appBar: AppBar(
          backgroundColor: NidColors.fog,
          title: const Text('Safety and limits'),
        ),
        body: const SafetyScreen(),
      ),
    ),
  );
}

/// Pushes the Article reader (design 72) as a gentle fade. Resolves read-next
/// links against [library] so the reader can chain to the next read.
void openArticle(
  BuildContext context,
  ExploreArticle article,
  List<ExploreArticle> library,
) {
  Navigator.of(context).push(
    fadeDetailRoute<void>(
      ArticleReaderScreen(article: article, library: library),
    ),
  );
}

/// The Article reader (design 72): a back affordance, a moss kicker (section ·
/// kind · time), a canopy title, a byline, a lede, body blocks with an inline
/// InfoTip, a "Worth knowing" callout, a "Try it now" practice card, read-next
/// rows, and the closing disclaimer + 988 line.
class ArticleReaderScreen extends StatelessWidget {
  const ArticleReaderScreen({
    super.key,
    required this.article,
    this.library = seedExploreArticles,
  });

  final ExploreArticle article;
  final List<ExploreArticle> library;

  List<ExploreArticle> get _readNext => [
    for (final id in article.readNextIds)
      ...library.where((a) => a.id == id).take(1),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final readNext = _readNext;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: NidColors.fog,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_outlined, color: NidColors.canopy),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          NidSpace.xl,
          0,
          NidSpace.xl,
          NidSpace.xxl,
        ),
        children: [
          Text(
            '${article.section} · ${article.kind} · ${article.readMinutes} min',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.9,
              color: NidColors.moss,
            ),
          ),
          const SizedBox(height: NidSpace.s),
          Text(
            article.title,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontSize: 27,
              height: 1.2,
              color: NidColors.canopy,
              letterSpacing: -0.54,
            ),
          ),
          const SizedBox(height: NidSpace.s + 2),
          Text(
            '${article.reviewedBy} · Updated ${article.updated}',
            style: const TextStyle(fontSize: 12, color: NidColors.faint),
          ),
          const SizedBox(height: NidSpace.l + 2),
          Text(
            article.lede,
            style: const TextStyle(
              fontSize: 15,
              height: 1.65,
              color: NidColors.slate,
            ),
          ),

          for (final block in article.body) _ArticleBlockView(block: block),

          const SizedBox(height: NidSpace.l + 4),
          _WorthKnowingCallout(
            title: article.calloutTitle,
            body: article.calloutBody,
          ),

          const SizedBox(height: NidSpace.xl),
          _TryItNowCard(
            title: article.practiceTitle,
            body: article.practiceBody,
            cta: article.practiceCta,
          ),

          if (readNext.isNotEmpty) ...[
            const SizedBox(height: NidSpace.xl),
            _ReadNext(
              articles: readNext,
              onOpen: (next) => openArticle(context, next, library),
            ),
          ],

          const SizedBox(height: NidSpace.xl),
          const _ArticleDisclaimer(),
        ],
      ),
    );
  }
}

/// One body block — a heading or a paragraph with an optional trailing inline
/// InfoTip (design 72's inline `.tipdot`).
class _ArticleBlockView extends StatelessWidget {
  const _ArticleBlockView({required this.block});

  final ArticleBlock block;

  @override
  Widget build(BuildContext context) {
    if (block.isHeading) {
      return Padding(
        padding: const EdgeInsets.only(top: NidSpace.xl + 2),
        child: Text(
          block.text,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.17,
            color: NidColors.ink,
          ),
        ),
      );
    }

    final hasTip = block.tipTerm != null && block.tipBody != null;
    return Padding(
      padding: const EdgeInsets.only(top: NidSpace.m),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Text(
              block.text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.7,
                color: NidColors.slate,
              ),
            ),
          ),
          if (hasTip)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: InfoTip(term: block.tipTerm!, body: block.tipBody!),
            ),
        ],
      ),
    );
  }
}

/// The "Worth knowing" callout (design `.callout`) — a mint card with a moss
/// eyebrow and an ink body.
class _WorthKnowingCallout extends StatelessWidget {
  const _WorthKnowingCallout({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        NidSpace.l + 2,
        NidSpace.l,
        NidSpace.l + 2,
        NidSpace.l,
      ),
      decoration: BoxDecoration(
        color: NidColors.mint,
        borderRadius: BorderRadius.circular(NidRadius.control),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.96,
              color: NidColors.moss,
            ),
          ),
          const SizedBox(height: NidSpace.xs + 2),
          Text(
            body,
            style: const TextStyle(
              fontSize: 13,
              height: 1.6,
              color: NidColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

/// The "Try it now" practice card (design `.try`) — a white card with a canopy
/// CTA that opens the box-breathing practice.
class _TryItNowCard extends StatelessWidget {
  const _TryItNowCard({
    required this.title,
    required this.body,
    required this.cta,
  });

  final String title;
  final String body;
  final String cta;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: NidColors.ink,
            ),
          ),
          const SizedBox(height: NidSpace.xs + 1),
          Text(
            body,
            style: const TextStyle(
              fontSize: 13,
              height: 1.55,
              color: NidColors.slate,
            ),
          ),
          const SizedBox(height: NidSpace.m),
          Align(
            alignment: Alignment.centerLeft,
            child: Material(
              color: NidColors.canopy,
              borderRadius: BorderRadius.circular(NidRadius.pill),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {},
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: NidSpace.l + 2,
                    vertical: NidSpace.s + 1,
                  ),
                  child: Text(
                    cta,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The "Read next" list (design `.next`) — a canopy kicker over tappable rows.
class _ReadNext extends StatelessWidget {
  const _ReadNext({required this.articles, required this.onOpen});

  final List<ExploreArticle> articles;
  final ValueChanged<ExploreArticle> onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: NidSpace.l + 2),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: NidColors.canopy.withValues(alpha: 0.14)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionKicker('Read next'),
          for (final article in articles)
            InkWell(
              onTap: () => onOpen(article),
              child: Padding(
                padding: const EdgeInsets.only(top: NidSpace.m),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        article.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: NidColors.ink,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: NidColors.faint,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The reader's closing disclaimer + 988 line (design `.disc`).
class _ArticleDisclaimer extends StatelessWidget {
  const _ArticleDisclaimer();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Text(
          'Educational, not medical advice — and never a diagnosis.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, height: 1.6, color: NidColors.faint),
        ),
        SizedBox(height: NidSpace.xs),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: 'If things feel heavy, talking helps. '),
              TextSpan(text: 'In the US, call or text '),
              TextSpan(
                text: '988',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: NidColors.canopy,
                ),
              ),
              TextSpan(text: ' anytime.'),
            ],
          ),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, height: 1.6, color: NidColors.faint),
        ),
      ],
    );
  }
}
