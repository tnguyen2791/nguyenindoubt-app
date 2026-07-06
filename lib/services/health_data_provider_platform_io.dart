import 'dart:io';

import 'package:health/health.dart' as platform_health;

import '../models/app_models.dart';
import 'health_data_provider.dart';

HealthDataProvider createPlatformHealthDataProvider({required String userId}) {
  return PlatformHealthDataProvider(userId: userId);
}

class PlatformHealthDataProvider implements HealthDataProvider {
  PlatformHealthDataProvider({
    required this.userId,
    platform_health.Health? health,
  }) : _health = health ?? platform_health.Health();

  final String userId;
  final platform_health.Health _health;
  HealthPermissionStatus _permissionStatus =
      HealthPermissionStatus.notRequested;
  bool _configured = false;
  bool _requestedBefore = false;

  @override
  HealthPermissionStatus get permissionStatus => _permissionStatus;

  @override
  Future<HealthPermissionStatus> checkPermissionStatus() async {
    if (!_isSupportedPlatform) {
      _permissionStatus = HealthPermissionStatus.unavailable;
      return _permissionStatus;
    }
    await _configure();

    if (Platform.isAndroid) {
      final sdkStatus = await _health.getHealthConnectSdkStatus();
      if (sdkStatus != platform_health.HealthConnectSdkStatus.sdkAvailable) {
        _permissionStatus = HealthPermissionStatus.unavailable;
        return _permissionStatus;
      }
    }

    final permissions = await Future.wait(
      _sleepTypes.map(
        (type) => _health.hasPermissions(
          [type],
          permissions: const [platform_health.HealthDataAccess.READ],
        ),
      ),
    );
    final grantedCount = permissions.where((granted) => granted == true).length;
    if (grantedCount == _sleepTypes.length) {
      _permissionStatus = HealthPermissionStatus.ready;
    } else if (grantedCount > 0) {
      _permissionStatus = HealthPermissionStatus.partial;
    } else if (_permissionStatus == HealthPermissionStatus.ready ||
        _requestedBefore) {
      _permissionStatus = HealthPermissionStatus.revoked;
    } else {
      _permissionStatus = HealthPermissionStatus.notRequested;
    }
    return _permissionStatus;
  }

  @override
  Future<bool> requestPermissions() async {
    if (!_isSupportedPlatform) {
      _permissionStatus = HealthPermissionStatus.unavailable;
      return false;
    }
    await _configure();
    _requestedBefore = true;

    final authorized = await _health.requestAuthorization(
      _sleepTypes,
      permissions: List.filled(
        _sleepTypes.length,
        platform_health.HealthDataAccess.READ,
      ),
    );
    if (!authorized) {
      _permissionStatus = HealthPermissionStatus.denied;
      return false;
    }
    await checkPermissionStatus();
    return _permissionStatus == HealthPermissionStatus.ready ||
        _permissionStatus == HealthPermissionStatus.partial;
  }

  @override
  Future<List<MetricType>> fetchAvailableMetrics(HealthRange range) async {
    if (await checkPermissionStatus() == HealthPermissionStatus.unavailable) {
      return const [];
    }
    return const [MetricType.sleep];
  }

  @override
  Future<List<HealthSample>> fetchSleepSamples(HealthRange range) async {
    final status = await checkPermissionStatus();
    if (status != HealthPermissionStatus.ready &&
        status != HealthPermissionStatus.partial) {
      return const [];
    }

    final dataPoints = await _health.getHealthDataFromTypes(
      types: _sleepTypes,
      startTime: range.start,
      endTime: range.end,
    );
    final now = DateTime.now();
    return dedupeSleepSamples(
      dataPoints
          .where(_isSleepPoint)
          .where((point) => point.dateTo.isAfter(point.dateFrom))
          .map(
            (point) => HealthSample(
              userId: userId,
              source: _sourceLabel(point),
              metricType: MetricType.sleep,
              start: point.dateFrom,
              end: point.dateTo,
              value: _durationHours(point),
              unit: 'hours',
              createdAt: now,
            ),
          ),
    );
  }

  bool get _isSupportedPlatform => Platform.isIOS || Platform.isAndroid;

  List<platform_health.HealthDataType> get _sleepTypes {
    if (Platform.isAndroid) {
      return const [
        platform_health.HealthDataType.SLEEP_SESSION,
        platform_health.HealthDataType.SLEEP_ASLEEP,
        platform_health.HealthDataType.SLEEP_AWAKE,
        platform_health.HealthDataType.SLEEP_DEEP,
        platform_health.HealthDataType.SLEEP_LIGHT,
        platform_health.HealthDataType.SLEEP_REM,
      ];
    }
    return const [
      platform_health.HealthDataType.SLEEP_ASLEEP,
      platform_health.HealthDataType.SLEEP_AWAKE,
      platform_health.HealthDataType.SLEEP_DEEP,
      platform_health.HealthDataType.SLEEP_IN_BED,
      platform_health.HealthDataType.SLEEP_LIGHT,
      platform_health.HealthDataType.SLEEP_REM,
    ];
  }

  Future<void> _configure() async {
    if (_configured) {
      return;
    }
    await _health.configure();
    _configured = true;
  }

  bool _isSleepPoint(platform_health.HealthDataPoint point) {
    return point.type.name.startsWith('SLEEP_');
  }

  double _durationHours(platform_health.HealthDataPoint point) {
    final minutes = point.dateTo.difference(point.dateFrom).inMinutes;
    return minutes / 60;
  }

  String _sourceLabel(platform_health.HealthDataPoint point) {
    final platform = switch (point.sourcePlatform) {
      platform_health.HealthPlatformType.appleHealth => 'Apple Health',
      platform_health.HealthPlatformType.googleHealthConnect =>
        'Health Connect',
    };
    if (point.sourceName.trim().isEmpty) {
      return platform;
    }
    return '$platform: ${point.sourceName}';
  }
}
