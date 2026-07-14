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

    // Sleep permission is the readiness floor: the app is usable (and stays
    // ready) as long as sleep is granted. The extra readiness signals are
    // best-effort — missing ones are skipped at read time, never fatal — so
    // the ready/partial decision keys off the sleep types, matching the
    // sleep-only behavior the rest of the app already relies on.
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

    // Ask for the full type set in one prompt (sleep + readiness signals) so
    // the user grants everything at once. The user may deny individual
    // readiness types; reads guard per-type, so partial grants degrade
    // gracefully rather than failing.
    final requestedTypes = _authorizationTypes;
    final authorized = await _health.requestAuthorization(
      requestedTypes,
      permissions: List.filled(
        requestedTypes.length,
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
    // Report the metrics this platform can map to a health type, so callers
    // know which readiness signals to expect. Sleep is always first.
    final available = <MetricType>[MetricType.sleep];
    for (final metric in kReadinessMetricTypes) {
      if (_platformTypesFor(metric).isNotEmpty) {
        available.add(metric);
      }
    }
    return available;
  }

  @override
  Future<List<HealthSample>> fetchSamples({
    required List<MetricType> metrics,
    required HealthRange range,
  }) async {
    final status = await checkPermissionStatus();
    if (status != HealthPermissionStatus.ready &&
        status != HealthPermissionStatus.partial) {
      return const [];
    }

    final now = DateTime.now();
    final samples = <HealthSample>[];
    for (final metric in metrics) {
      if (metric == MetricType.sleep) {
        // Sleep has its own dedicated read/dedupe/summary path.
        continue;
      }
      final types = _platformTypesFor(metric);
      if (types.isEmpty) {
        // Unsupported on this platform — skip gracefully, never throw.
        continue;
      }

      List<platform_health.HealthDataPoint> dataPoints;
      try {
        dataPoints = await _health.getHealthDataFromTypes(
          types: types,
          startTime: range.start,
          endTime: range.end,
        );
      } on Object {
        // A single unsupported/permission-denied type must not sink the whole
        // read. Skip this metric and keep collecting the others.
        continue;
      }

      for (final point in dataPoints) {
        final value = _numericValue(point);
        if (value == null) {
          continue;
        }
        samples.add(
          HealthSample(
            userId: userId,
            source: _sourceLabel(point),
            metricType: metric,
            start: point.dateFrom,
            end: point.dateTo,
            value: value,
            unit: _unitLabel(metric, point),
            createdAt: now,
          ),
        );
      }
    }
    return samples;
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

  /// The full set of types requested at authorization time: sleep plus every
  /// readiness signal this platform supports. Deduplicated, since a metric may
  /// share no type with sleep but the list is built by union.
  List<platform_health.HealthDataType> get _authorizationTypes {
    final types = <platform_health.HealthDataType>{..._sleepTypes};
    for (final metric in kReadinessMetricTypes) {
      types.addAll(_platformTypesFor(metric));
    }
    return types.toList();
  }

  /// Maps an app [MetricType] to the platform health types to read for it.
  /// iOS and Health Connect expose different identifiers (e.g. HRV is SDNN on
  /// iOS, RMSSD on Android), so this branches per platform. Returns an empty
  /// list when the metric has no supported type here — callers skip it.
  List<platform_health.HealthDataType> _platformTypesFor(MetricType metric) {
    final isAndroid = Platform.isAndroid;
    switch (metric) {
      case MetricType.hrv:
        return [
          isAndroid
              ? platform_health.HealthDataType.HEART_RATE_VARIABILITY_RMSSD
              : platform_health.HealthDataType.HEART_RATE_VARIABILITY_SDNN,
        ];
      case MetricType.restingHeartRate:
        return const [platform_health.HealthDataType.RESTING_HEART_RATE];
      case MetricType.heartRate:
        return const [platform_health.HealthDataType.HEART_RATE];
      case MetricType.respiratoryRate:
        return const [platform_health.HealthDataType.RESPIRATORY_RATE];
      case MetricType.temperature:
        return isAndroid
            ? const [platform_health.HealthDataType.SKIN_TEMPERATURE]
            : const [platform_health.HealthDataType.BODY_TEMPERATURE];
      case MetricType.bloodOxygen:
        return const [platform_health.HealthDataType.BLOOD_OXYGEN];
      case MetricType.activeEnergy:
        return const [platform_health.HealthDataType.ACTIVE_ENERGY_BURNED];
      case MetricType.steps:
        return const [platform_health.HealthDataType.STEPS];
      case MetricType.sleep:
      case MetricType.mindfulMinutes:
      case MetricType.medication:
        return const [];
    }
  }

  /// Extracts a plain numeric value from a health point, or null when the
  /// point does not carry a numeric reading we can use.
  double? _numericValue(platform_health.HealthDataPoint point) {
    final value = point.value;
    if (value is platform_health.NumericHealthValue) {
      return value.numericValue.toDouble();
    }
    return null;
  }

  String _unitLabel(MetricType metric, platform_health.HealthDataPoint point) {
    switch (metric) {
      case MetricType.hrv:
        return 'ms';
      case MetricType.restingHeartRate:
      case MetricType.heartRate:
        return 'bpm';
      case MetricType.respiratoryRate:
        return 'brpm';
      case MetricType.temperature:
        return '°C';
      case MetricType.bloodOxygen:
        return '%';
      case MetricType.activeEnergy:
        return 'kcal';
      case MetricType.steps:
        return 'count';
      case MetricType.sleep:
      case MetricType.mindfulMinutes:
      case MetricType.medication:
        return point.unit.name;
    }
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
