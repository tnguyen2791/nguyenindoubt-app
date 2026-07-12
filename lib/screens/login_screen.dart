import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'common_widgets.dart';

/// Brand-styled multi-provider sign-in (designs 42/60/62): fog ground, the
/// ember-"In" wordmark, three provider buttons, and a calm phone + OTP flow.
///
/// Wired to an injected [AuthService] so it drives real Firebase auth in
/// production and a [DemoAuthService] no-op in tests. NOT yet mounted as the
/// app entry — staged for the pass that flips the app to real auth.
///
/// All provider errors surface as calm copy through an inline banner; raw
/// exceptions never reach the UI (project rule).
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

  _Stage _stage = _Stage.chooser;
  bool _busy = false;
  String? _errorCopy;
  String? _verificationId;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
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

  bool get _codeLooksValid =>
      _codeController.text.trim().replaceAll(RegExp(r'[^0-9]'), '').length >= 6;

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
  });

  Future<void> _confirmCode() => _guard(() async {
    final verificationId = _verificationId;
    if (verificationId == null) {
      throw const AuthFailure('Please request a new code and try again.');
    }
    await widget.auth.confirmPhoneCode(
      verificationId,
      _codeController.text.trim(),
    );
    widget.onSignedIn?.call();
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
                padding: const EdgeInsets.all(NidSpace.xl),
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
        const Center(child: BrandMark(size: 82)),
        const SizedBox(height: NidSpace.l),
        const Center(child: _BrandWordmark()),
        const SizedBox(height: NidSpace.m),
        Text(
          'Quiet signals, clear mornings.',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: NidColors.slate),
        ),
        const SizedBox(height: NidSpace.xl),
        if (_errorCopy != null) ...[
          _ErrorBanner(message: _errorCopy!),
          const SizedBox(height: NidSpace.m),
        ],
        FilledButton.icon(
          onPressed: _busy ? null : _google,
          icon: const Icon(Icons.g_mobiledata_outlined),
          label: const Text('Continue with Google'),
        ),
        const SizedBox(height: NidSpace.m),
        // Apple sign-in is not enabled server-side yet, so the button stays
        // gently disabled with calm "coming soon" copy rather than throwing a
        // provider error on tap (project rule: no raw errors, calm surfaces).
        FilledButton.icon(
          onPressed: null,
          icon: const Icon(Icons.apple),
          label: const Text('Continue with Apple'),
        ),
        const SizedBox(height: NidSpace.xs),
        Text(
          'Apple sign-in is coming soon.',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: NidColors.faint),
        ),
        const SizedBox(height: NidSpace.m),
        FilledButton.icon(
          onPressed: _busy ? null : _backToPhone,
          icon: const Icon(Icons.phone_outlined),
          label: const Text('Continue with phone'),
        ),
        const SizedBox(height: NidSpace.l),
        Text(
          'Private by design — your data stays yours.',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: NidColors.faint),
        ),
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
        _BackAffordance(onTap: _busy ? null : _backToChooser),
        const SizedBox(height: NidSpace.l),
        Text(
          'Sign in with phone',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontSize: 26,
            color: NidColors.canopy,
            letterSpacing: -0.52,
          ),
        ),
        const SizedBox(height: NidSpace.m),
        Text(
          "We'll text a one-time code — no password to remember.",
          style: Theme.of(context).textTheme.bodyMedium,
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
        Text(
          'Used for sign-in only. Never for marketing by default.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: NidColors.faint),
        ),
        const SizedBox(height: NidSpace.xl),
        FilledButton(
          onPressed: (_phoneLooksValid && !_busy) ? _startPhone : null,
          child: const Text('Send code'),
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
        _BackAffordance(onTap: _busy ? null : _backToPhone),
        const SizedBox(height: NidSpace.l),
        Text(
          'Enter your code',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontSize: 26,
            color: NidColors.canopy,
            letterSpacing: -0.52,
          ),
        ),
        const SizedBox(height: NidSpace.m),
        Text(
          "We sent a 6-digit code to ${_phoneController.text.trim()}. "
          "It's good for a few minutes.",
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: NidSpace.l),
        if (_errorCopy != null) ...[
          _ErrorBanner(message: _errorCopy!),
          const SizedBox(height: NidSpace.m),
        ],
        TextField(
          controller: _codeController,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          enabled: !_busy,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Verification code',
            hintText: '123456',
            prefixIcon: Icon(Icons.lock_outline),
            counterText: '',
          ),
          onChanged: (_) => setState(() => _errorCopy = null),
          onSubmitted: (_) {
            if (_codeLooksValid && !_busy) {
              _confirmCode();
            }
          },
        ),
        const SizedBox(height: NidSpace.xl),
        FilledButton(
          onPressed: (_codeLooksValid && !_busy) ? _confirmCode : null,
          child: const Text('Verify'),
        ),
        const SizedBox(height: NidSpace.s),
        TextButton(
          onPressed: _busy ? null : _backToPhone,
          child: const Text('Change number'),
        ),
        if (_busy) ...[
          const SizedBox(height: NidSpace.s),
          const Center(child: _CalmProgress()),
        ],
      ],
    );
  }
}

/// The brand wordmark: `Nguyen` + ember `In` + `Doubt`, matching the splash.
class _BrandWordmark extends StatelessWidget {
  const _BrandWordmark();

  @override
  Widget build(BuildContext context) {
    const base = TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.84,
      color: NidColors.canopy,
    );
    return const Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(text: 'Nguyen'),
          TextSpan(
            text: 'In',
            style: TextStyle(color: NidColors.ember),
          ),
          TextSpan(text: 'Doubt'),
        ],
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
    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
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
