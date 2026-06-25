class DailyHealthEntry {
  final DateTime date;
  final int steps;
  final int sleepMinutes;
  final int avgHeartRate;

  /// Flag identifying data source origin:
  /// true = Native Health Connect Device Telemetry (Blue Color)
  /// false = Injected Estimated Backfill / Sample Data (Orange Color)
  final bool isOriginal;

  DailyHealthEntry({
    required this.date,
    required this.steps,
    required this.sleepMinutes,
    required this.avgHeartRate,
    required this.isOriginal,
  });
}
