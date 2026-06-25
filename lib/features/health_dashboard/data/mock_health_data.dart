import 'dart:math';
import '../domain/models/daily_health_entry.dart';

class MockHealthData {
  /// Dynamically computes the calendar Monday anchors based on the current live time
  static DateTime get _currentWeekMon {
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);
    return todayMidnight.subtract(Duration(days: todayMidnight.weekday - 1));
  }

  static DateTime get _previousWeekMon =>
      _currentWeekMon.subtract(const Duration(days: 7));

  /// Baseline sample matrix for standard user preview modes (Dynamically maps last week)
  static List<DailyHealthEntry> get previousWeekSample {
    final startMon = _previousWeekMon;
    final random = Random();

    // Previous week is entirely in the past, so all days receive full dummy activity values
    final stepsBase = [5600, 3200, 8100, 9420, 4900, 8900, 11200];
    final sleepBase = [425, 410, 420, 435, 400, 430, 485];
    final hrBase = [74, 72, 70, 74, 72, 71, 78];

    return List.generate(7, (index) {
      return DailyHealthEntry(
        date: startMon.add(Duration(days: index)),
        steps:
            stepsBase[index] +
            random.nextInt(601) -
            300, // Adds subtle unique variance (-300 to +300)
        sleepMinutes: sleepBase[index] + random.nextInt(31) - 15,
        avgHeartRate: hrBase[index],
        isOriginal: false,
      );
    });
  }

  /// Standard current week timeline structure matrix template (Dynamically zeroed out for the future)
  static List<DailyHealthEntry> get currentWeekSample {
    final startMon = _currentWeekMon;
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);
    final random = Random();

    final stepsBase = [3550, 9839, 5939, 2298, 8933, 9200, 2098];
    final sleepBase = [530, 415, 445, 420, 410, 460, 490];
    final hrBase = [68, 73, 72, 70, 71, 74, 73];

    return List.generate(7, (index) {
      final targetDate = startMon.add(Duration(days: index));

      // RULE: If this calendar slot is in the future, it stays completely zeroed out
      if (targetDate.isAfter(todayMidnight)) {
        return DailyHealthEntry(
          date: targetDate,
          steps: 0,
          sleepMinutes: 0,
          avgHeartRate: 0,
          isOriginal: false,
        );
      }

      // If it's a past day or today within the current week, give it dummy tracking entries
      return DailyHealthEntry(
        date: targetDate,
        steps: targetDate.isAtSameMomentAs(todayMidnight)
            ? 1498 // Specific distinct baseline metric if it's today's live tracker slot
            : stepsBase[index] + random.nextInt(401) - 200,
        sleepMinutes: sleepBase[index] + random.nextInt(21) - 10,
        avgHeartRate: hrBase[index],
        isOriginal: false,
      );
    });
  }
}
