import 'dart:math';

import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import '../../data/data_sources/health_kit_source.dart';
import '../../data/mock_health_data.dart';
import '../../domain/models/daily_health_entry.dart';
import '../../domain/models/health_metrics_model.dart';
import '../../domain/utils/health_calculation_engine.dart';

enum HealthPermissionState {
  unknown,
  authorized,
  denied,
  missingApp,
  sampleData,
  permanentlyDenied,
}

class HealthProvider extends ChangeNotifier {
  final HealthKitSource _source = HealthKitSource();

  HealthPermissionState _permissionState = HealthPermissionState.unknown;
  HealthPermissionState get permissionState => _permissionState;

  HealthMetricsModel _metrics = HealthMetricsModel.initial();
  HealthMetricsModel get metrics => _metrics;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String get formattedDate => DateFormat('EEEE, MMM d').format(DateTime.now());

  Future<void> initializeAndCheck() async {
    _isLoading = true;
    notifyListeners();
    try {
      bool hasAccess = await _source.checkPermissionStatus();
      if (hasAccess) {
        _permissionState = HealthPermissionState.authorized;
        await loadMetricsData();
      } else {
        _permissionState = HealthPermissionState.unknown;
      }
    } catch (e) {
      _permissionState = HealthPermissionState.missingApp;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> requestAppPermissions() async {
    try {
      PermissionStatus status = await Permission.activityRecognition.request();
      if (status.isDenied) {
        _permissionState = HealthPermissionState.denied;
        notifyListeners();
        return;
      }

      if (status.isPermanentlyDenied) {
        _permissionState = HealthPermissionState.permanentlyDenied;
        notifyListeners();
        return;
      }

      bool granted = await _source.requestPermissions();
      if (granted) {
        _permissionState = HealthPermissionState.authorized;
        await loadMetricsData();
      } else {
        _permissionState = HealthPermissionState.denied;
      }
    } catch (e) {
      _permissionState = HealthPermissionState.missingApp;
    }
    notifyListeners();
  }

  Future<void> loadMetricsData() async {
    try {
      final List<HealthDataPoint> rawData = await _source.fetchLatestMetrics();
      final DateTime now = DateTime.now(); // CONFLICT ADD
      final DateTime todayMidnight = DateTime(now.year, now.month, now.day);

      // Extract Monday anchors
      final DateTime currentWeekMon = todayMidnight.subtract(
        Duration(days: todayMidnight.weekday - 1),
      );
      final DateTime previousWeekMon = currentWeekMon.subtract(
        const Duration(days: 7),
      );

      // --- NEW PRE-SCAN STEP: Count distinct calendar days with real hardware records ---
      final Set<String> uniqueDaysWithData = {};
      for (var point in rawData) {
        num extracted = 0;
        if (point.value is NumericHealthValue) {
          extracted = (point.value as NumericHealthValue).numericValue;
        } else if (point.value is num) {
          extracted = point.value as num;
        }

        // Validate if this point holds real physical metrics activity records
        if (extracted > 0 &&
            (point.type == HealthDataType.STEPS ||
                point.type == HealthDataType.SLEEP_SESSION ||
                point.type == HealthDataType.RESTING_HEART_RATE ||
                point.type == HealthDataType.HEART_RATE)) {
          final localDate = point.dateFrom.toLocal();
          final dateKey =
              "${localDate.year}-${localDate.month}-${localDate.day}";
          uniqueDaysWithData.add(dateKey);
        }
      }

      // Check if the user has reached our 3-day real data density threshold
      final bool hasMinThreeDaysOfData = uniqueDaysWithData.length >= 3;

      // 1. Fetch exact raw hardware data points for all 14 days straight
      List<DailyHealthEntry> combinedFourteenDays = [];

      for (int i = 0; i < 14; i++) {
        final DateTime targetDate = previousWeekMon.add(Duration(days: i));
        combinedFourteenDays.add(
          HealthCalculationEngine.processRawDay(targetDate, rawData),
        );
      }

      for (int i = 0; i < combinedFourteenDays.length; i++) {
        print("**** ${combinedFourteenDays[i].steps}");
      }

      // 2. Find the index where the user's real data actually starts
      int firstRealIndex = -1;
      for (int i = 0; i < combinedFourteenDays.length; i++) {
        final entry = combinedFourteenDays[i];
        if (entry.isOriginal &&
            (entry.steps > 0 ||
                entry.sleepMinutes > 0 ||
                entry.avgHeartRate > 0)) {
          firstRealIndex = i;
          break;
        }
      }

      // 3. Apply the Hybrid Backfill Rules in a clean single pass
      List<DailyHealthEntry> finalFourteenDays = [];
      final randomEngine = Random();

      for (int i = 0; i < combinedFourteenDays.length; i++) {
        final entry = combinedFourteenDays[i];

        if (entry.date.isAtSameMomentAs(todayMidnight)) {
          // --- DYNAMIC TODAY STATUS CHECK ---
          if (entry.isOriginal && (entry.steps > 0 || entry.sleepMinutes > 0)) {
            // Today has live hardware data from the Toolbox -> Keep as valid Blue
            finalFourteenDays.add(entry);
          } else {
            // Today has NO data -> Check if 3+ days of records exist elsewhere
            if (hasMinThreeDaysOfData) {
              // User has established logs elsewhere. Do not add mock numbers; render a real, solid Blue 0 day
              finalFourteenDays.add(
                DailyHealthEntry(
                  date: entry.date,
                  steps: 0,
                  sleepMinutes: 0,
                  avgHeartRate: 0,
                  isOriginal: true, // Forces natural tracking blue style
                ),
              );
            } else {
              // Brand new user under threshold -> Override with an Orange fallback and label it as sample data
              int fallbackTodaySteps =
                  5000 + randomEngine.nextInt(2501); // Random 5000 - 7500
              int fallbackTodaySleep =
                  400 + randomEngine.nextInt(41); // Random 400 - 440 mins

              finalFourteenDays.add(
                DailyHealthEntry(
                  date: entry.date,
                  steps: fallbackTodaySteps,
                  sleepMinutes: fallbackTodaySleep,
                  avgHeartRate: 72,
                  isOriginal: false, // False forces the Orange styling color!
                ),
              );
            }
          }
        } else if (entry.isOriginal) {
          // Past days with hardware records stay exactly as they are (Blue)
          finalFourteenDays.add(entry);
        } else if (entry.date.isAfter(todayMidnight)) {
          // Future slots stay empty
          finalFourteenDays.add(
            DailyHealthEntry(
              date: entry.date,
              steps: 0,
              sleepMinutes: 0,
              avgHeartRate: 0,
              isOriginal: false,
            ),
          );
        } else if (firstRealIndex != -1 && i >= firstRealIndex) {
          // Valid tracked user mid-week 0 baseline slot (Blue)
          finalFourteenDays.add(
            DailyHealthEntry(
              date: entry.date,
              steps: 0,
              sleepMinutes: 0,
              avgHeartRate: 0,
              isOriginal: true,
            ),
          );
        } else {
          // --- COLD START DAYS BEFORE REGISTRATION ---
          if (hasMinThreeDaysOfData) {
            // CRITICAL RULE: If 3+ unique days of tracking exist, stop adding historical dummy data
            finalFourteenDays.add(
              DailyHealthEntry(
                date: entry.date,
                steps: 0,
                sleepMinutes: 0,
                avgHeartRate: 0,
                isOriginal: true, // Clean out to 0 (Solid Blue)
              ),
            );
          } else {
            // Add standard Orange dummy backfills for brand-new users
            int fallbackSteps = 6000 + (entry.date.day % 4 * 800);
            int fallbackSleep = 400 + (entry.date.day % 3 * 30);
            finalFourteenDays.add(
              DailyHealthEntry(
                date: entry.date,
                steps: fallbackSteps,
                sleepMinutes: fallbackSleep,
                avgHeartRate: 72,
                isOriginal: false,
              ),
            );
          }
        }
      }

      // Split the clean data array back into previous and current week blocks
      List<DailyHealthEntry> calculatedPrevWeek = finalFourteenDays.sublist(
        0,
        7,
      );
      List<DailyHealthEntry> calculatedCurrWeek = finalFourteenDays.sublist(
        7,
        14,
      );

      // Isolate current day metrics and yesterday's metrics safely
      final todayEntry = finalFourteenDays[(7 + todayMidnight.weekday - 1)];

      int fineLatestHR = 0;
      DateTime? maxHRTimestamp;
      for (var p in rawData.where(
        (element) => element.type == HealthDataType.HEART_RATE,
      )) {
        if (maxHRTimestamp == null || p.dateFrom.isAfter(maxHRTimestamp)) {
          maxHRTimestamp = p.dateFrom;
          fineLatestHR = p.value is NumericHealthValue
              ? (p.value as NumericHealthValue).numericValue.toInt()
              : (p.value as num).toInt();
        }
      }

      int prevWeekStepsSum = calculatedPrevWeek.fold(
        0,
        (sum, item) => sum + item.steps,
      );
      int currWeekStepsSum = calculatedCurrWeek.fold(
        0,
        (sum, item) => sum + item.steps,
      );
      final int currentPassedDays = now.weekday;
      int currWeekSleepMinsSum = calculatedCurrWeek.fold(
        0,
        (sum, item) => sum + item.sleepMinutes,
      );
      int currWeekSleepCount = calculatedCurrWeek
          .where((e) => e.sleepMinutes > 0)
          .length;

      int avgSleepMins = currWeekSleepCount > 0
          ? (currWeekSleepMinsSum ~/ currWeekSleepCount)
          : 0;

      _metrics = HealthMetricsModel(
        currentSteps: todayEntry.steps,
        stepGoal: 10000,
        sleepDuration:
            "${todayEntry.sleepMinutes ~/ 60}h ${todayEntry.sleepMinutes % 60}m",
        sleepQuality: getSleepStatus(
          "${todayEntry.sleepMinutes ~/ 60}h ${todayEntry.sleepMinutes % 60}m",
        )["text"],
        latestHeartRate: fineLatestHR > 0
            ? fineLatestHR
            : (todayEntry.avgHeartRate > 0 ? todayEntry.avgHeartRate : 72),
        dailyAvgHeartRate: todayEntry.avgHeartRate > 0
            ? todayEntry.avgHeartRate
            : 72,
        previousWeekEntries: calculatedPrevWeek,
        currentWeekEntries: calculatedCurrWeek,
        sevenDayAvgSteps: currWeekStepsSum ~/ currentPassedDays,
        sevenDayAvgSleep: "${avgSleepMins ~/ 60}h ${avgSleepMins % 60}m",
        previousSteps: prevWeekStepsSum ~/ 7,
        previousSleepMinutes:
            calculatedPrevWeek.fold(
              0,
              (sum, item) => sum + item.sleepMinutes,
            ) ~/
            7,
        customInsightMessage: currWeekStepsSum > prevWeekStepsSum
            ? "Your activity volume has scaled up compared to last week's average timeline loop benchmarks!"
            : "Movement trends are slightly lower this week. Focus on step consistency to re-align your averages.",
      );

      _permissionState = HealthPermissionState.authorized;
    } catch (e) {
      debugPrint("Error processing dynamic single-pass layout maps: $e");
    }
    notifyListeners();
  }

  void loginWithSampleData() {
    _isLoading = true;
    notifyListeners();
    _permissionState = HealthPermissionState.sampleData;

    // 1. Pull the fresh dynamic matrix lists
    final prevWeek = MockHealthData.previousWeekSample;
    final currWeek = MockHealthData.currentWeekSample;

    final DateTime now = DateTime.now();
    final int currentPassedDays = now.weekday; // Mon=1, Tue=2, Wed=3...

    // 2. Isolate today's and yesterday's metrics dynamically from the sample list
    final todayEntry = currWeek[currentPassedDays - 1];

    // Safely look up yesterday's entry
    final combined = [...prevWeek, ...currWeek];
    final yesterdayEntry = combined[(7 + currentPassedDays - 1) - 1];

    // 3. Compute the aggregates matching the dynamic sample values exactly
    int prevWeekStepsSum = prevWeek.fold(0, (sum, item) => sum + item.steps);
    int currWeekStepsSum = currWeek.fold(0, (sum, item) => sum + item.steps);
    int currWeekSleepMinsSum = currWeek.fold(
      0,
      (sum, item) => sum + item.sleepMinutes,
    );
    int currWeekSleepCount = currWeek.where((e) => e.sleepMinutes > 0).length;
    int avgSleepMins = currWeekSleepCount > 0
        ? (currWeekSleepMinsSum ~/ currWeekSleepCount)
        : 0;

    _metrics = HealthMetricsModel(
      currentSteps: todayEntry.steps, // Dynamic match!
      stepGoal: 10000,
      sleepDuration:
          "${yesterdayEntry.sleepMinutes ~/ 60}h ${yesterdayEntry.sleepMinutes % 60}m",
      sleepQuality: getSleepStatus(
        "${yesterdayEntry.sleepMinutes ~/ 60}h ${yesterdayEntry.sleepMinutes % 60}m",
      )["text"],
      latestHeartRate: todayEntry.avgHeartRate > 0
          ? todayEntry.avgHeartRate
          : 72,
      dailyAvgHeartRate: todayEntry.avgHeartRate > 0
          ? todayEntry.avgHeartRate
          : 72,
      previousWeekEntries: prevWeek,
      currentWeekEntries: currWeek,

      // Dynamic matching averages
      sevenDayAvgSteps: currWeekStepsSum ~/ currentPassedDays,
      sevenDayAvgSleep: "${avgSleepMins ~/ 60}h ${avgSleepMins % 60}m",
      previousSteps: prevWeekStepsSum ~/ 7,
      previousSleepMinutes:
          prevWeek.fold(0, (sum, item) => sum + item.sleepMinutes) ~/ 7,
      customInsightMessage: currWeekStepsSum > prevWeekStepsSum
          ? "Your sample activity volume has scaled up significantly compared to last week's baseline."
          : "Sample movement trends are running slightly lower. Focus on consistency to recover your targets.",
    );

    _isLoading = false;
    notifyListeners();
  }

  Map<String, dynamic> getSleepStatus(String sleepDurationStr) {
    final RegExp regex = RegExp(r'(?:(\d+)h)?\s*(?:(\d+)m)?');
    final match = regex.firstMatch(sleepDurationStr);
    int hours = 0, minutes = 0;
    if (match != null) {
      hours = int.parse(match.group(1) ?? '0');
      minutes = int.parse(match.group(2) ?? '0');
    }
    final totalMinutes = (hours * 60) + minutes;
    if (totalMinutes == 0) {
      return {"text": "Sample Data", "color": Colors.orange};
    }
    if (totalMinutes < 300) {
      return {"text": "Severe Sleep Debt", "color": Colors.red};
    }
    if (totalMinutes < 420) {
      return {"text": "Short / Fragmented", "color": Colors.orange};
    }
    if (totalMinutes <= 540) {
      return {"text": "Excellent Quality", "color": Colors.green};
    }
    return {"text": "Overslept / Heavy", "color": Colors.blue};
  }

  void resetToUnknown() {
    _permissionState = HealthPermissionState.unknown;
    _metrics = HealthMetricsModel.initial();
    notifyListeners();
  }
}
