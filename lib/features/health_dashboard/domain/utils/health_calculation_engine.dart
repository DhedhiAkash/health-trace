import 'package:health/health.dart';
import '../models/daily_health_entry.dart';

class HealthCalculationEngine {
  /// Performs the pure extraction of hardware metrics from the raw Health Connect payload
  static DailyHealthEntry processRawDay(
    DateTime targetDate,
    List<HealthDataPoint> bulkPayload,
  ) {
    final startOfDay = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      0,
      0,
      0,
    );
    final sleepQueryStart = startOfDay.subtract(const Duration(hours: 12));
    final sleepQueryEnd = startOfDay.add(const Duration(hours: 12));

    int daySteps = 0;
    List<int> dayHRs = [];
    List<HealthDataPoint> daySleepSessions = [];
    bool containsHardwareRecords = false;

    for (var point in bulkPayload) {
      num extracted = 0;
      // Resilient value extraction wrapper matching various health plugin versions
      if (point.value is NumericHealthValue) {
        extracted = (point.value as NumericHealthValue).numericValue;
      } else if (point.value is num) {
        extracted = point.value as num;
      } else {
        // Fallback parse attempt if the value stringifies directly
        extracted = num.tryParse(point.value.toString()) ?? 0;
      }

      final DateTime pointStartLocal = point.dateFrom.toLocal();

      final bool isSameCalendarDay =
          pointStartLocal.year == targetDate.year &&
          pointStartLocal.month == targetDate.month &&
          pointStartLocal.day == targetDate.day;

      if (point.type == HealthDataType.STEPS && isSameCalendarDay) {
        daySteps += extracted.toInt();
        containsHardwareRecords = true;
      } else if (point.type == HealthDataType.RESTING_HEART_RATE &&
          isSameCalendarDay) {
        dayHRs.add(extracted.toInt());
        containsHardwareRecords = true;
      } else if (point.type == HealthDataType.SLEEP_SESSION &&
          pointStartLocal.isAfter(sleepQueryStart) &&
          pointStartLocal.isBefore(sleepQueryEnd)) {
        daySleepSessions.add(point);
        containsHardwareRecords = true;
      }
    }

    int averageHeartRate = dayHRs.isNotEmpty
        ? (dayHRs.reduce((a, b) => a + b) / dayHRs.length).round()
        : 0;

    return DailyHealthEntry(
      date: targetDate,
      steps: daySteps,
      sleepMinutes: _mergeSleepGaps(daySleepSessions),
      avgHeartRate: averageHeartRate,
      isOriginal:
          containsHardwareRecords, // Temporarily marked true if records exist
    );
  }

  /// Evaluates sleep blocks and merges gaps <= 30 mins
  static int _mergeSleepGaps(List<HealthDataPoint> sleepSessions) {
    if (sleepSessions.isEmpty) return 0;

    sleepSessions.sort((a, b) => a.dateFrom.compareTo(b.dateFrom));
    DateTime segmentStart = sleepSessions.first.dateFrom;
    DateTime segmentEnd = sleepSessions.first.dateTo;
    int mergedSleepMinutes = 0;

    for (int i = 1; i < sleepSessions.length; i++) {
      final next = sleepSessions[i];
      if (next.dateFrom.difference(segmentEnd).inMinutes <= 30) {
        if (next.dateTo.isAfter(segmentEnd)) segmentEnd = next.dateTo;
      } else {
        mergedSleepMinutes += segmentEnd.difference(segmentStart).inMinutes;
        segmentStart = next.dateFrom;
        segmentEnd = next.dateTo;
      }
    }
    mergedSleepMinutes += segmentEnd.difference(segmentStart).inMinutes;
    return mergedSleepMinutes;
  }
}
