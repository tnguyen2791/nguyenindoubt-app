import 'package:url_launcher/url_launcher.dart';

/// Platform seam for handing a crisis URI (`tel:`/`sms:`) to the OS.
///
/// The app never places a call or sends a text itself — it only asks the
/// operating system to open its dialer/messages app in response to an explicit
/// user tap. This seam exists so widget tests can assert the requested URI
/// without touching a real platform channel (SAFE-01).
abstract class CrisisLauncher {
  /// Attempts to hand [uri] to the OS.
  ///
  /// Returns `true` if a handler was launched, `false` if no handler is
  /// available (for example a `tel:` scheme on web). Never throws.
  Future<bool> launch(Uri uri);
}

/// Default [CrisisLauncher] backed by `url_launcher`.
///
/// Guards every launch with [canLaunchUrl] and returns `false` — never throws —
/// when no handler exists, so callers can degrade gracefully. It launches only
/// on an explicit user tap and never auto-invokes on build.
class UrlCrisisLauncher implements CrisisLauncher {
  const UrlCrisisLauncher();

  @override
  Future<bool> launch(Uri uri) async {
    if (!await canLaunchUrl(uri)) {
      return false;
    }
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
