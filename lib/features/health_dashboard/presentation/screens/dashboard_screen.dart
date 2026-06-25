import 'package:flutter/material.dart';
import 'package:health_dashboard/features/health_dashboard/presentation/widgets/sync_banner_widget.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/health_provider.dart';
import 'insights_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  void _changeTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HealthProvider>();

    final List<Widget> screens = [
      _BuildDashboardHome(
        provider: provider,
        onNavigateToInsights: () => _changeTab(1),
      ),
      const InsightsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        onTap: _changeTab,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            label: 'Insights',
          ),
        ],
      ),
    );
  }
}

class _BuildDashboardHome extends StatelessWidget {
  final HealthProvider provider;
  final VoidCallback onNavigateToInsights;

  const _BuildDashboardHome({
    required this.provider,
    required this.onNavigateToInsights,
  });

  @override
  Widget build(BuildContext context) {
    final metrics = provider.metrics;
    final double rawStepRatio = metrics.stepGoal > 0
        ? metrics.currentSteps / metrics.stepGoal
        : 0.0;
    final sleepStatus = provider.getSleepStatus(metrics.sleepDuration);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldBackground,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Hello, Team Confident Pose",
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              provider.formattedDate,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.notifications_none,
              color: AppColors.textDark,
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.accentFill,
              child: Icon(Icons.person, color: AppColors.textDark),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SyncBannerWidget(),
            const SizedBox(height: 20),

            // Target Step Telemetry Ring Module Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(
                            Icons.directions_run,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          SizedBox(width: 6),
                          Text(
                            "Steps",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                      const Text(
                        "Daily Activity",
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "${metrics.currentSteps}",
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(bottom: 4.0, left: 4.0),
                            child: Text(
                              " / 10,000 steps",
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: CircularProgressIndicator(
                          value: rawStepRatio.clamp(
                            0.0,
                            1.0,
                          ), // Clamped perfectly to handle over-targets cleanly
                          strokeWidth: 8,
                          backgroundColor: AppColors.accentFill,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        "${(rawStepRatio * 100).toInt()}%",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Sleep & Heart Rate Split Metrics Grid Rows
            Row(
              children: [
                Expanded(
                  child: _MetricGridCard(
                    icon: Icons.dark_mode_outlined,
                    iconColor: Colors.teal,
                    title: "Sleep",
                    value: metrics.sleepDuration == "0h 0m"
                        ? "6h 20m"
                        : metrics.sleepDuration,
                    subtitle: sleepStatus["text"], // Dynamic Status Text
                    subtitleColor:
                        sleepStatus["color"], // Dynamic Warning Color
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _MetricGridCard(
                    icon: Icons.favorite_border_rounded,
                    iconColor: Colors.redAccent,
                    title: "Heart Rate",
                    value: "${metrics.latestHeartRate} BPM",
                    subtitle: "Resting Heart Rate",
                    subtitleColor: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Health Summary Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.analytics_outlined,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "Health Summary",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          Text(
                            "Last synced 2m ago",
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: onNavigateToInsights,
                    child: const Text(
                      "Details",
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
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
}

class _MetricGridCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String subtitle;
  final Color subtitleColor;

  const _MetricGridCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: subtitleColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
