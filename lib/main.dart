import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'repositories/app_repository.dart';
import 'screens/app_shell.dart';
import 'services/health_data_provider.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
  const NguyenInDoubtApp({super.key, required this.state});

  final NguyenInDoubtState state;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NguyenInDoubt',
      theme: buildNidTheme(),
      home: AppShell(state: state),
    );
  }
}
