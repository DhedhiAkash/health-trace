import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/health_dashboard/presentation/providers/health_provider.dart';
import 'features/health_dashboard/presentation/screens/onboarding_screen.dart';
import 'features/health_dashboard/presentation/screens/dashboard_screen.dart';
import 'features/health_dashboard/presentation/screens/permission_denied_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => HealthProvider()..initializeAndCheck(),
        ),
      ],
      child: const HealthMetricsApp(),
    ),
  );
}

class HealthMetricsApp extends StatelessWidget {
  const HealthMetricsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Health Insights',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Inter',
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      ),
      home: const MainNavigationController(),
    );
  }
}

class MainNavigationController extends StatelessWidget {
  const MainNavigationController({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HealthProvider>().permissionState;
    final loading = context.watch<HealthProvider>().isLoading;

    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF0052CC)),
        ),
      );
    }

    // Update your switch block inside lib/main.dart to match this:
    switch (state) {
      case HealthPermissionState.authorized:
      case HealthPermissionState.sampleData:
        return const DashboardScreen();
      case HealthPermissionState.denied:
      case HealthPermissionState.permanentlyDenied:
      case HealthPermissionState.missingApp:
        return const PermissionDeniedScreen();
      case HealthPermissionState.unknown:
      default:
        return const OnboardingScreen();
    }
  }
}
