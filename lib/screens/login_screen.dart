import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// Brand-styled multi-provider sign-in, built to the onboarding welcome (`42`)
/// and verify-code (`62`) designs: a fog ground, the concentric-ring hero with
/// the compact `NiD` canopy lockup, the "Quiet signals, clear mornings"
/// headline, three full-width provider blocks, and a calm 6-box OTP step.
///
/// The design's welcome offers Apple + email; this app's providers are
/// Google / Apple / Phone, so the same button/lockup/disclosure grammar is
/// kept while the labels match the real providers. Apple stays gracefully
/// disabled ("coming soon") until its provider is enabled server-side.
///
/// Wired to an injected [AuthService] so it drives real Firebase auth in
/// production and a [DemoAuthService] no-op in tests. All provider errors
/// surface as calm copy through an inline banner; raw exceptions never reach
/// the UI (project rule).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.auth, this.onSignedIn});

  final AuthService auth;

  /// Optional hook fired after any provider sign-in resolves — lets the next
  /// pass route into the app. Left null in isolation/tests.
  final VoidCallback? onSignedIn;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

enum _Stage { chooser, phoneEntry, codeEntry }

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _codeFocus = FocusNode();

  _Stage _stage = _Stage.chooser;
  bool _busy = false;
  String? _errorCopy;
  String? _verificationId;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  // A light guard: E.164-ish — a leading + and at least 8 total digits. The
  // authoritative validation happens server-side; this only gates the button
  // so an empty or obviously-incomplete number can't be submitted.
  bool get _phoneLooksValid {
    final value = _phoneController.text.trim();
    if (!value.startsWith('+')) {
      return false;
    }
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length >= 8;
  }

  String get _codeDigits =>
      _codeController.text.trim().replaceAll(RegExp(r'[^0-9]'), '');

  bool get _codeLooksValid => _codeDigits.length >= 6;

  void _clearError() {
    if (_errorCopy != null) {
      setState(() => _errorCopy = null);
    }
  }

  /// Runs [action], showing the busy state and turning any [AuthFailure] into
  /// calm inline copy. Never lets a raw exception reach the UI.
  Future<void> _guard(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _errorCopy = null;
    });
    try {
      await action();
    } on AuthFailure catch (failure) {
      if (mounted) {
        setState(() => _errorCopy = failure.message);
      }
    } catch (_) {
      // Defensive: any non-AuthFailure still shows calm copy, never the raw
      // error (project rule: no raw exceptions in the UI).
      if (mounted) {
        setState(() => _errorCopy = 'Something went wrong. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _google() => _guard(() async {
    await widget.auth.signInWithGoogle();
    widget.onSignedIn?.call();
  });

  Future<void> _startPhone() => _guard(() async {
    final result = await widget.auth.startPhoneSignIn(
      _phoneController.text.trim(),
    );
    if (!mounted) {
      return;
    }
    if (result.autoResolved) {
      // Instant verification already signed the user in — skip code entry.
      widget.onSignedIn?.call();
      return;
    }
    setState(() {
      _verificationId = result.verificationId;
      _stage = _Stage.codeEntry;
    });
    // Focus the hidden field so the OTP boxes start collecting immediately.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _codeFocus.requestFocus();
      }
    });
  });

  Future<void> _confirmCode() => _guard(() async {
    final verificationId = _verificationId;
    if (verificationId == null) {
      throw const AuthFailure('Please request a new code and try again.');
    }
    await widget.auth.confirmPhoneCode(verificationId, _codeDigits);
    widget.onSignedIn?.call();
  });

  /// Resends a fresh code by re-running the phone start on the same number.
  Future<void> _resendCode() => _guard(() async {
    final result = await widget.auth.startPhoneSignIn(
      _phoneController.text.trim(),
    );
    if (!mounted) {
      return;
    }
    if (result.autoResolved) {
      widget.onSignedIn?.call();
      return;
    }
    setState(() {
      _verificationId = result.verificationId;
      _errorCopy = null;
    });
  });

  void _backToChooser() {
    _clearError();
    setState(() => _stage = _Stage.chooser);
  }

  void _backToPhone() {
    _clearError();
    setState(() => _stage = _Stage.phoneEntry);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NidColors.fog,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: NidSpace.xl,
                  vertical: NidSpace.l,
                ),
                child: switch (_stage) {
                  _Stage.chooser => _buildChooser(context),
                  _Stage.phoneEntry => _buildPhoneEntry(context),
                  _Stage.codeEntry => _buildCodeEntry(context),
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChooser(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Progress dots — welcome is step one of the onboarding arc (42).
        const Center(child: _ProgressDots(active: 0)),
        const SizedBox(height: NidSpace.xl),
        // The concentric-ring hero wrapping the compact NiD lockup.
        const Center(child: _RingHero()),
        const SizedBox(height: NidSpace.xl),
        Text(
          'Quiet signals,\nclear mornings',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontSize: 30,
            height: 1.15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.6,
            color: NidColors.canopy,
          ),
        ),
        const SizedBox(height: NidSpace.m),
        Text(
          'NguyenInDoubt reads your sleep, recovery, and rhythm — and tells '
          'you what it means, not what to fear.',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: NidColors.slate, height: 1.5),
        ),
        const SizedBox(height: NidSpace.xl),
        if (_errorCopy != null) ...[
          _ErrorBanner(message: _errorCopy!),
          const SizedBox(height: NidSpace.m),
        ],
        // Provider blocks — full-width, in the design's order (Google primary,
        // then Apple, then Phone), matching the 42 CTA stack.
        _ProviderButton(
          label: 'Continue with Google',
          icon: Icons.g_mobiledata_outlined,
          onPressed: _busy ? null : _google,
        ),
        const SizedBox(height: NidSpace.m), // mock .cta margin-top:12px
        // Apple sign-in is not enabled server-side yet, so the button stays
        // gently disabled with calm "coming soon" copy rather than throwing a
        // provider error on tap (project rule: no raw errors, calm surfaces).
        const _ProviderButton(
          label: 'Continue with Apple',
          icon: Icons.apple,
          onPressed: null,
          ghost: true,
        ),
        const SizedBox(height: NidSpace.xs),
        const Text(
          'Apple sign-in is coming soon.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: NidColors.faint),
        ),
        const SizedBox(height: NidSpace.m), // mock .cta margin-top:12px
        _ProviderButton(
          label: 'Continue with phone',
          icon: Icons.phone_outlined,
          onPressed: _busy ? null : _backToPhone,
          ghost: true,
        ),
        const SizedBox(height: NidSpace.l),
        const _FinePrint(),
        if (_busy) ...[
          const SizedBox(height: NidSpace.l),
          const Center(child: _CalmProgress()),
        ],
      ],
    );
  }

  Widget _buildPhoneEntry(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepHeader(active: 1, onBack: _busy ? null : _backToChooser),
        const SizedBox(height: NidSpace.l),
        Text(
          'Sign in with phone',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontSize: 26,
            color: NidColors.canopy,
            letterSpacing: -0.52,
          ),
        ),
        const SizedBox(height: NidSpace.s),
        Text(
          "We'll text a one-time code — no password to remember.",
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: NidColors.slate),
        ),
        const SizedBox(height: NidSpace.l),
        if (_errorCopy != null) ...[
          _ErrorBanner(message: _errorCopy!),
          const SizedBox(height: NidSpace.m),
        ],
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          enabled: !_busy,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
          ],
          decoration: const InputDecoration(
            labelText: 'Phone number',
            hintText: '+1 415 555 0123',
            prefixIcon: Icon(Icons.phone_outlined),
          ),
          onChanged: (_) => setState(() => _errorCopy = null),
          onSubmitted: (_) {
            if (_phoneLooksValid && !_busy) {
              _startPhone();
            }
          },
        ),
        const SizedBox(height: NidSpace.s),
        const Text(
          'Used for sign-in only. Never for marketing by default.',
          style: TextStyle(fontSize: 12, color: NidColors.faint),
        ),
        const SizedBox(height: NidSpace.xl),
        _PrimaryCta(
          label: 'Send code',
          onPressed: (_phoneLooksValid && !_busy) ? _startPhone : null,
        ),
        if (_busy) ...[
          const SizedBox(height: NidSpace.l),
          const Center(child: _CalmProgress()),
        ],
      ],
    );
  }

  Widget _buildCodeEntry(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepHeader(active: 2, onBack: _busy ? null : _backToPhone),
        const SizedBox(height: NidSpace.l),
        Text(
          'Enter your code',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontSize: 26,
            color: NidColors.canopy,
            letterSpacing: -0.52,
          ),
        ),
        const SizedBox(height: NidSpace.s),
        Text.rich(
          TextSpan(
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: NidColors.slate),
            children: [
              const TextSpan(text: 'We sent a 6-digit code to '),
              TextSpan(
                text: _phoneController.text.trim(),
                style: const TextStyle(
                  color: NidColors.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const TextSpan(text: ". It's good for a few minutes."),
            ],
          ),
        ),
        const SizedBox(height: NidSpace.l),
        if (_errorCopy != null) ...[
          _ErrorBanner(message: _errorCopy!),
          const SizedBox(height: NidSpace.m),
        ],
        // The 6-box OTP grammar (62): a hidden field drives the boxes so the
        // native keyboard, paste, and SMS autofill all still work.
        _OtpBoxes(
          controller: _codeController,
          focusNode: _codeFocus,
          enabled: !_busy,
          onChanged: () => setState(() => _errorCopy = null),
          onCompleted: () {
            if (_codeLooksValid && !_busy) {
              _confirmCode();
            }
          },
        ),
        const SizedBox(height: NidSpace.l),
        // Resend + change-number affordances (62 `.resend`).
        Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'Nothing yet? ',
                style: TextStyle(fontSize: 13, color: NidColors.slate),
              ),
              _QuietLink(
                label: 'Resend code',
                onTap: _busy ? null : _resendCode,
              ),
              const Text(
                '  ·  ',
                style: TextStyle(fontSize: 13, color: NidColors.faint),
              ),
              _QuietLink(
                label: 'Change number',
                onTap: _busy ? null : _backToPhone,
              ),
            ],
          ),
        ),
        const SizedBox(height: NidSpace.xl),
        _PrimaryCta(
          label: 'Verify',
          onPressed: (_codeLooksValid && !_busy) ? _confirmCode : null,
        ),
        if (_busy) ...[
          const SizedBox(height: NidSpace.m),
          const Center(child: _CalmProgress()),
        ],
      ],
    );
  }
}

/// The onboarding progress dots (42/62 `.dots`): three pills, the active one
/// stretched wide in canopy, the rest small mint dots.
class _ProgressDots extends StatelessWidget {
  const _ProgressDots({required this.active});

  final int active;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            width: i == active ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: i == active ? NidColors.canopy : NidColors.mint,
              borderRadius: BorderRadius.circular(NidRadius.pill),
            ),
          ),
        ],
      ],
    );
  }
}

/// A step header pairing the calm 32px back circle (62 `.back`) with the
/// centered progress dots.
class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.active, required this.onBack});

  final int active;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: _BackAffordance(onTap: onBack),
        ),
        _ProgressDots(active: active),
      ],
    );
  }
}

/// The concentric-ring hero (42 `.hero`): two rounded arcs on mint tracks
/// around the compact `NiD` canopy lockup.
class _RingHero extends StatelessWidget {
  const _RingHero();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 168,
      height: 168,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(size: const Size(168, 168), painter: _RingHeroPainter()),
          const _CompactMark(),
        ],
      ),
    );
  }
}

class _RingHeroPainter extends CustomPainter {
  const _RingHeroPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    // Two concentric rings, tracks in mint, arcs in optimal/moss, rounded caps,
    // rotated to start at the top — matching the 42 hero geometry.
    void ring(double radius, Color arc, double sweepFraction) {
      final track = Paint()
        ..color = NidColors.mint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8;
      canvas.drawCircle(center, radius, track);
      final paint = Paint()
        ..color = arc
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round;
      const start = -1.5708; // -90deg
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        6.2832 * sweepFraction,
        false,
        paint,
      );
    }

    ring(76, NidStateColors.optimal, 0.68);
    ring(60, NidColors.moss, 0.55);
  }

  @override
  bool shouldRepaint(covariant _RingHeroPainter oldDelegate) => false;
}

/// The compact `NiD` lockup (42 `.mark-lg`): a canopy pill with white bold
/// letters and an ember "i" — the below-80px brand form per brand-readme.
class _CompactMark extends StatelessWidget {
  const _CompactMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: NidColors.canopy,
        borderRadius: BorderRadius.circular(NidRadius.card),
      ),
      alignment: Alignment.center,
      child: const Text.rich(
        TextSpan(
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.69,
            color: Colors.white,
          ),
          children: [
            TextSpan(text: 'N'),
            TextSpan(
              text: 'i',
              style: TextStyle(color: NidColors.ember),
            ),
            TextSpan(text: 'D'),
          ],
        ),
      ),
    );
  }
}

/// A full-width provider block (42 `.cta` / `.cta.ghost`): the primary is a
/// canopy fill, the ghost a canopy outline. Disabled ghosts read faint so the
/// "coming soon" state stays calm, never alarming.
class _ProviderButton extends StatelessWidget {
  const _ProviderButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.ghost = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool ghost;

  @override
  Widget build(BuildContext context) {
    if (ghost) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(label),
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}

/// The canopy-fill primary CTA (Send code / Verify), full-width (42/62 `.cta`).
class _PrimaryCta extends StatelessWidget {
  const _PrimaryCta({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(onPressed: onPressed, child: Text(label)),
    );
  }
}

/// The welcome fine print (42 `.fine`): the privacy line over Terms · Privacy.
class _FinePrint extends StatelessWidget {
  const _FinePrint();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Private by design — your data stays yours.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: NidColors.faint, height: 1.6),
        ),
        const SizedBox(height: 2),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _QuietLink(label: 'Terms', onTap: () {}),
            const Text(
              '  ·  ',
              style: TextStyle(fontSize: 12, color: NidColors.faint),
            ),
            _QuietLink(label: 'Privacy', onTap: () {}),
          ],
        ),
      ],
    );
  }
}

/// A quiet canopy text link (42/62 link grammar) — calm weight, no raw button
/// chrome.
class _QuietLink extends StatelessWidget {
  const _QuietLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(NidRadius.tile),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: onTap == null ? NidColors.faint : NidColors.canopy,
          ),
        ),
      ),
    );
  }
}

/// The 6-box OTP entry (62 `.code`): six boxes over a single hidden field so
/// the platform keyboard, paste, and SMS autofill keep working. The box under
/// the cursor gets a canopy border and a blinking caret when empty.
class _OtpBoxes extends StatelessWidget {
  const _OtpBoxes({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.onChanged,
    required this.onCompleted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final VoidCallback onChanged;
  final VoidCallback onCompleted;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // The visible boxes rebuild from the controller's current value.
        AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final digits = controller.text.replaceAll(RegExp(r'[^0-9]'), '');
            final active = digits.length.clamp(0, 5);
            return Row(
              children: [
                for (var i = 0; i < 6; i++) ...[
                  if (i > 0) const SizedBox(width: 9),
                  Expanded(
                    child: _OtpCell(
                      value: i < digits.length ? digits[i] : '',
                      active: enabled && i == active,
                    ),
                  ),
                ],
              ],
            );
          },
        ),
        // The hidden field that actually collects input, overlaid transparent.
        Positioned.fill(
          child: Opacity(
            opacity: 0,
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: enabled,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              maxLength: 6,
              showCursor: false,
              enableInteractiveSelection: false,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
              ),
              onChanged: (value) {
                onChanged();
                if (value.replaceAll(RegExp(r'[^0-9]'), '').length >= 6) {
                  onCompleted();
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// One OTP box (62 `.cbox`): a white tile with a hairline (canopy when active),
/// a big bold digit, or a blinking caret when it is the cursor's empty box.
class _OtpCell extends StatelessWidget {
  const _OtpCell({required this.value, required this.active});

  final String value;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.82,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: active
                ? NidColors.canopy
                : NidColors.canopy.withValues(alpha: 0.14),
            width: active ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: value.isNotEmpty
              ? Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: NidColors.ink,
                  ),
                )
              : (active
                    // A calm static caret marks the cursor's box. A repeating
                    // blink would keep the tree animating and break the
                    // pumpAndSettle the app-pumping tests rely on, so the caret
                    // stays steady — the canopy border already signals "active".
                    ? Container(width: 2, height: 22, color: NidColors.canopy)
                    : const SizedBox.shrink()),
        ),
      ),
    );
  }
}

/// Calm inline error banner — carries friendly copy only, never a raw error.
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: NidSpace.l,
        vertical: NidSpace.m,
      ),
      decoration: BoxDecoration(
        color: NidColors.ember.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(NidRadius.control),
        border: Border.all(color: NidColors.ember.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: NidColors.ember),
          const SizedBox(width: NidSpace.s),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: NidColors.ember,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The calm 32x32 circular back affordance from the onboarding design.
class _BackAffordance extends StatelessWidget {
  const _BackAffordance({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: Material(
        color: Colors.white,
        shape: CircleBorder(
          side: BorderSide(color: NidColors.canopy.withValues(alpha: 0.14)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: const Tooltip(
            message: 'Back',
            child: Icon(
              Icons.arrow_back_outlined,
              size: 18,
              color: NidColors.canopy,
            ),
          ),
        ),
      ),
    );
  }
}

/// A quiet canopy-toned progress indicator.
class _CalmProgress extends StatelessWidget {
  const _CalmProgress();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 22,
      height: 22,
      child: CircularProgressIndicator(
        strokeWidth: 2.4,
        valueColor: AlwaysStoppedAnimation<Color>(NidColors.canopy),
      ),
    );
  }
}
