import 'package:flutter/material.dart';
import 'package:health/health.dart';

class HealthKitSource {
  final Health _health = Health();

  final List<HealthDataType> types = [
    HealthDataType.STEPS,
    HealthDataType.SLEEP_SESSION,
    HealthDataType.HEART_RATE,
    HealthDataType.RESTING_HEART_RATE,
  ];

  Future<bool> requestPermissions() async {
    // Map permissions to explicitly use READ access configurations
    final permissions = types.map((e) => HealthDataAccess.READ).toList();

    // Check if Health Connect is installed/supported on the device
    bool? isAvailable = await _health.hasPermissions(types);
    if (isAvailable == null) {
      throw UnsupportedError("Health Connect launcher missing on this device.");
    }

    return await _health.requestAuthorization(types, permissions: permissions);
  }

  Future<bool> checkPermissionStatus() async {
    try {
      // Compares structural read access grants
      final permissions = types.map((e) => HealthDataAccess.READ).toList();
      return await _health.hasPermissions(types, permissions: permissions) ??
          false;
    } catch (e) {
      // If the platform throws a missing launcher exception during boot check
      return false;
    }
  }

  Future<List<HealthDataPoint>> fetchLatestMetrics() async {
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);

    // CRITICAL FIX: Roll back the query window to 15 days ago
    // This safely pulls your complete 2-week historical database from the Toolbox
    final startTimeFence = todayMidnight.subtract(const Duration(days: 15));

    try {
      return await _health.getHealthDataFromTypes(
        startTime: startTimeFence,
        endTime: now,
        types: types,
      );
    } catch (e) {
      debugPrint("Error fetching raw native records from Health Connect: $e");
      return [];
    }
  }
}
