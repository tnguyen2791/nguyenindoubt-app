import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'repositories/app_repository.dart';
import 'screens/brand_splash.dart';
import 'services/health_data_provider.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Connect Firebase for account-backed storage. Guarded so a transient init
  // failure (offline, misconfig) degrades to the local demo instead of a black
  // boot screen — the repository swap is staged separately behind real auth.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error, stackTrace) {
    debugPrint('Firebase initialization failed; continuing on local demo.');
    debugPrintStack(stackTrace: stackTrace, label: '$error');
  }

  final preferences = await SharedPreferences.getInstance();
  final repository = InMemoryAppRepository(preferences: preferences);
  final state = NguyenInDoubtState(
    repository: repository,
    healthDataProvider: createDefaultHealthDataProvider(
      userId: repository.patientDemo.id,
    ),
  );
  runApp(NguyenInDoubtApp(state: state));
}

class NguyenInDoubtApp extends StatelessWidget {
  const NguyenInDoubtApp({
    super.key,
    required this.state,
    this.showSplash = true,
  });

  final NguyenInDoubtState state;

  /// Test seam (ONB-01): production boots keep the default `true` and get the
  /// one-shot brand-intro splash. Widget tests pass `false` so the gate
  /// builds [AppShell] directly and `pumpAndSettle` from boot never hangs.
  final bool showSplash;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NguyenInDoubt',
      theme: buildNidTheme(),
      home: BrandSplashGate(state: state, enabled: showSplash),
    );
  }
}
