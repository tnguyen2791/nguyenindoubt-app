import '../models/app_models.dart';
import 'health_data_provider.dart';

HealthDataProvider createPlatformHealthDataProvider({required String userId}) {
  return UnavailableHealthDataProvider(userId: userId);
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
}
