import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'app_shell.dart';
import 'common_widgets.dart';

/// Boot gate that plays the one-shot animated brand-intro splash, then
/// cross-fades into [AppShell] (ONB-01).
///
/// Sequence (gentle, no bounce, ~3.5s): fog ground -> [BrandMark] fades in
/// with a soft bloom -> the "NguyenInDoubt" wordmark fades up beneath ->
/// hold -> cross-fade into the app. Plays once per cold launch, guarded by
/// the in-memory [NguyenInDoubtState.splashHasPlayed] flag — never a
/// persisted counter and never analytics.
///
/// Test seam: widget tests pass `NguyenInDoubtApp(showSplash: false)`, which
/// sets [enabled] false here. The disabled path builds [AppShell] directly —
/// no [AnimationController], no pending timers — so `pumpAndSettle` from boot
/// settles instantly.
class BrandSplashGate extends StatefulWidget {
  const BrandSplashGate({
    super.key,
    required this.state,
    required this.enabled,
  });

  /// Marker key for the splash-only view, so tests can assert its presence
  /// during the intro and its absence after the cross-fade.
  static const Key splashKey = Key('brand-splash');

  final NguyenInDoubtState state;
  final bool enabled;

  @override
  State<BrandSplashGate> createState() => _BrandSplashGateState();
}

class _BrandSplashGateState extends State<BrandSplashGate>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  bool _showingSplash = false;

  @override
  void initState() {
    super.initState();
    if (widget.enabled && !widget.state.splashHasPlayed) {
      _showingSplash = true;
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 3500),
      );
      _controller = controller;
      controller.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.state.markSplashPlayed();
          if (mounted) {
            setState(() => _showingSplash = false);
          }
        }
      });
      controller.forward();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) {
      // Splash disabled or already played this launch: straight to the app,
      // with zero animation machinery so widget tests settle immediately.
      return AppShell(state: widget.state);
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: _showingSplash
          ? _BrandSplashView(
              key: BrandSplashGate.splashKey,
              controller: controller,
            )
          : AppShell(state: widget.state),
    );
  }
}

/// The splash visual itself: fog ground, blooming [BrandMark], rising
/// wordmark, and a thin ember accent.
class _BrandSplashView extends StatelessWidget {
  const _BrandSplashView({super.key, required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final markFade = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );
    final markBloom = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.15, 0.7, curve: Curves.easeOutCubic),
      ),
    );
    final wordmarkFade = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.55, 0.95, curve: Curves.easeOut),
    );
    final wordmarkRise =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: controller,
            curve: const Interval(0.55, 0.95, curve: Curves.easeOut),
          ),
        );
    return Scaffold(
      backgroundColor: NidColors.fog,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeTransition(
              opacity: markFade,
              child: ScaleTransition(
                scale: markBloom,
                child: const BrandMark(size: 96),
              ),
            ),
            const SizedBox(height: NidSpace.xl),
            FadeTransition(
              opacity: wordmarkFade,
              child: SlideTransition(
                position: wordmarkRise,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'NguyenInDoubt',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: NidColors.canopy,
                      ),
                    ),
                    const SizedBox(height: NidSpace.m),
                    Container(
                      width: 32,
                      height: 2,
                      decoration: BoxDecoration(
                        color: NidColors.ember,
                        borderRadius: BorderRadius.circular(NidRadius.pill),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
