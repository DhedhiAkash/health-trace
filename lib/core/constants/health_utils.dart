import 'package:flutter/material.dart';

class HealthUtils {
  /// Aspect Map for generating distinct dynamic contextual variations
  static const Map<String, Map<String, String>> metricAspects = {
    'steps_volume': {'up': 'increase in volume', 'down': 'drop in movement'},
    'steps_pace': {'up': 'faster active pace', 'down': 'slower pace'},
    'steps_consistency': {
      'up': 'better consistency',
      'down': 'less consistent',
    },
    'heart_resting': {
      'up': 'higher resting baseline',
      'down': 'improved recovery lower resting',
    },
    'heart_cardio': {
      'up': 'more aerobic exertion',
      'down': 'less cardio strain',
    },
    'heart_stability': {
      'up': 'stable rhythm trends',
      'down': 'increased variance profiles',
    },
    'sleep_duration': {
      'up': 'more rest accumulated',
      'down': 'sleep debt logged',
    },
    'sleep_deep': {'up': 'deeper REM cycles', 'down': 'shallow sleep stages'},
    'sleep_efficiency': {
      'up': 'higher efficiency rating',
      'down': 'restless wake times',
    },
    'calories_burn': {
      'up': 'elevated metabolic burn',
      'down': 'lower caloric output',
    },
  };

  /// Calculates percentage metrics and outputs standard display configs
  static Map<String, dynamic> getPercentageTrend(
    double current,
    double previous,
    String aspectKey,
  ) {
    if (previous == 0) {
      return {
        'text': '0% vs last week',
        'icon': Icons.trending_flat,
        'color': const Color(0xFF6B7280),
      };
    }

    double pctChange = ((current - previous) / previous) * 100;
    bool isPositiveChange = pctChange >= 0;
    String sign = isPositiveChange ? '↗ +' : '↘ ';

    // Fetch contextual labels based on aspect mapping
    final aspect =
        metricAspects[aspectKey] ??
        {'up': 'vs last week', 'down': 'vs last week'};
    String contextLabel = isPositiveChange ? aspect['up']! : aspect['down']!;

    // Green is good for steps/sleep up, but Red might be bad for heart rate up.
    // We adjust visual accents based on target metrics:
    bool isGoodNews = isPositiveChange;
    if (aspectKey.startsWith('heart_resting') && isPositiveChange) {
      isGoodNews = false;
    }

    return {
      'text': '$sign${pctChange.abs().toStringAsFixed(1)}% $contextLabel',
      'icon': isPositiveChange
          ? Icons.arrow_upward_rounded
          : Icons.arrow_downward_rounded,
      'color': isGoodNews ? const Color(0xFF10B981) : const Color(0xFFEF4444),
    };
  }

  /// Calculates simple value variances (e.g., +20 min)
  static Map<String, dynamic> getValueVariance(
    int current,
    int previous,
    String unit,
    String aspectKey, {
    bool isDataMissing = false,
  }) {
    int diff = current - previous;
    bool isPositive = diff >= 0;
    String sign = isPositive ? '+' : '-';

    final aspect =
        metricAspects[aspectKey] ?? {'up': 'gained', 'down': 'dropped'};
    String contextLabel = isPositive ? aspect['up']! : aspect['down']!;

    bool isGoodNews = isPositive;
    if (aspectKey.startsWith('heart_resting') && isPositive) isGoodNews = false;
    if (isDataMissing) {
      return {
        'text': 'Sample Sleep Data',
        'icon': isPositive
            ? Icons.add_circle_outline_rounded
            : Icons.remove_circle_outline_rounded,
        'color': Colors.orange,
      };
    }
    return {
      'text': '$sign${diff.abs()} $unit ($contextLabel)',
      'icon': isPositive
          ? Icons.add_circle_outline_rounded
          : Icons.remove_circle_outline_rounded,
      'color': isGoodNews ? const Color(0xFF10B981) : const Color(0xFFEF4444),
    };
  }
}
