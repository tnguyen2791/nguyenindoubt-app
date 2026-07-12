import '../models/app_models.dart';
import 'health_data_provider.dart';

// On platforms without HealthKit / Health Connect (web demo, desktop) there is
// no real sleep source. The public GitHub Pages / local demo still needs to
// exercise the sleep-only import flow, so fall back to the on-device mock
// provider rather than a permanently-unavailable one. Real device builds use
// health_data_provider_platform_io.dart, which talks to the OS health store.
HealthDataProvider createPlatformHealthDataProvider({required String userId}) {
  return MockHealthDataProvider(userId: userId);
}

class UnavailableHealthDataProvider implements HealthDataProvider {
  const UnavailableHealthDataProvider({required this.userId});

  final String userId;

  @override
  HealthPermissionStatus get permissionStatus =>
      HealthPermissionStatus.unavailable;

  @override
  Future<HealthPermissionStatus> checkPermissionStatus() async {
    return HealthPermissionStatus.unavailable;
  }

  @override
  Future<bool> requestPermissions() async => false;

  @override
  Future<List<MetricType>> fetchAvailableMetrics(HealthRange range) async {
    return const [];
  }

  @override
  Future<List<HealthSample>> fetchSleepSamples(HealthRange range) async {
    return const [];
  }

  @override
  Future<List<HealthSample>> fetchSamples({
    required List<MetricType> metrics,
    required HealthRange range,
  }) async {
    return const [];
  }
}
