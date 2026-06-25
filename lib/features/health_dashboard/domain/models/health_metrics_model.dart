import 'daily_health_entry.dart';

class HealthMetricsModel {
  // Main Dashboard Metrics (Today's Live Indicators)
  final int currentSteps;
  final int stepGoal;
  final String
  sleepDuration; // Formatted output for dashboard display (e.g. "7h 25m")
  final String sleepQuality; // Dynamic text based on sleep values
  final int latestHeartRate;
  final int dailyAvgHeartRate;

  // 14-Day Structured Ledgers (Chronologically Ordered: Monday -> Sunday)
  final List<DailyHealthEntry>
  previousWeekEntries; // Week 1 (June 15 - June 21)
  final List<DailyHealthEntry> currentWeekEntries; // Week 2 (June 22 - June 28)

  // Comparative & Analytics Fields (Driven by HealthUtils Engine)
  final int sevenDayAvgSteps;
  final String sevenDayAvgSleep;
  final int previousSteps;
  final int previousSleepMinutes;
  final String customInsightMessage;

  HealthMetricsModel({
    required this.currentSteps,
    required this.stepGoal,
    required this.sleepDuration,
    required this.sleepQuality,
    required this.latestHeartRate,
    required this.dailyAvgHeartRate,
    required this.previousWeekEntries,
    required this.currentWeekEntries,
    required this.sevenDayAvgSteps,
    required this.sevenDayAvgSleep,
    required this.previousSteps,
    required this.previousSleepMinutes,
    required this.customInsightMessage,
  });

  /// Factory template providing a clean initial zeroed state configuration
  factory HealthMetricsModel.initial() {
    return HealthMetricsModel(
      currentSteps: 0,
      stepGoal: 10000,
      sleepDuration: "0h 0m",
      sleepQuality: "No Data",
      latestHeartRate: 0,
      dailyAvgHeartRate: 0,
      previousWeekEntries: [],
      currentWeekEntries: [],
      sevenDayAvgSteps: 0,
      sevenDayAvgSleep: "0h 0m",
      previousSteps: 0,
      previousSleepMinutes: 0,
      customInsightMessage:
          "Connect your hardware platform to sync tracking data.",
    );
  }
}
