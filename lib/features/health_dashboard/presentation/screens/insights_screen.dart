import 'package:flutter/material.dart';
import 'package:health_dashboard/features/health_dashboard/presentation/widgets/sync_banner_widget.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/health_utils.dart';
import '../providers/health_provider.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HealthProvider>();
    final metrics = provider.metrics;

    // Calculate trends dynamically using our utility helpers
    final stepsTrend = HealthUtils.getPercentageTrend(
      metrics.sevenDayAvgSteps.toDouble(),
      metrics.previousSteps.toDouble(),
      'steps_volume',
    );

    final RegExp sleepRegex = RegExp(r'(?:(\d+)h)?\s*(?:(\d+)m)?');
    final match = sleepRegex.firstMatch(metrics.sevenDayAvgSleep);
    int currentSleepMins = 0;
    if (match != null) {
      currentSleepMins =
          (int.parse(match.group(1) ?? '0') * 60) +
          int.parse(match.group(2) ?? '0');
    }
    final sleepTrend = HealthUtils.getValueVariance(
      currentSleepMins,
      metrics.previousSleepMinutes,
      'min',
      'sleep_duration',
      isDataMissing: metrics.sevenDayAvgSleep == "0h 0m",
    );

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldBackground,
        elevation: 0,
        title: const Text(
          "Health Insights",
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SyncBannerWidget(),
            const SizedBox(height: 16),

            // Steps Insights Module Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "WEEKLY AVERAGE STEPS",
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        "${metrics.sevenDayAvgSteps} Steps",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildTrendChip(stepsTrend),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildLegendItem2Params(
                        AppColors.primary,
                        Colors.orange,
                        "Current Week",
                      ),
                      const SizedBox(width: 12),
                      _buildLegendItem2Params(
                        AppColors.primary.withValues(alpha: 0.35),
                        Colors.orange.withValues(alpha: 0.35),
                        "Previous Week",
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Dual Week Comparative Bar Graph Rendering Component
                  SizedBox(
                    height: 100,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(7, (index) {
                        final prevDay =
                            metrics.previousWeekEntries.length > index
                            ? metrics.previousWeekEntries[index]
                            : null;
                        final currDay =
                            metrics.currentWeekEntries.length > index
                            ? metrics.currentWeekEntries[index]
                            : null;

                        final double prevHeightRatio = prevDay != null
                            ? (prevDay.steps / 10000).clamp(0.0, 1.0)
                            : 0.0;
                        final double currHeightRatio = currDay != null
                            ? (currDay.steps / 10000).clamp(0.0, 1.0)
                            : 0.0;

                        final Color prevBarColor =
                            (prevDay?.isOriginal ?? false)
                            ? AppColors.primary
                            : Colors.orange;
                        final Color currBarColor =
                            (currDay?.isOriginal ?? false)
                            ? AppColors.primary
                            : Colors.orange;

                        const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

                        return Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  width: 10,
                                  height: 70 * prevHeightRatio,
                                  decoration: BoxDecoration(
                                    color: prevBarColor.withValues(alpha: 0.35),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  width: 10,
                                  height: 70 * currHeightRatio,
                                  decoration: BoxDecoration(
                                    color: currBarColor,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              dayLabels[index],
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildLegendItem(AppColors.primary, "Device Data"),
                      const SizedBox(width: 12),
                      _buildLegendItem(Colors.orange, "Sample Data"),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Sleep Insights Module Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "WEEKLY AVERAGE SLEEP",
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        metrics.sevenDayAvgSleep == "0h 0m"
                            ? "6h 20m"
                            : metrics.sevenDayAvgSleep,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildTrendChip(sleepTrend),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Assignment Choice Insight Banner Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0052CC), Color(0xFF3B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 18),
                      SizedBox(width: 6),
                      Text(
                        "Weekly Activity Tip",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    metrics.customInsightMessage,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendChip(Map<String, dynamic> trend) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (trend['color'] as Color).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            trend['icon'] as IconData,
            color: trend['color'] as Color,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            trend['text'] as String,
            style: TextStyle(
              color: trend['color'] as Color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem2Params(Color color1, Color color2, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color1, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color2, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
