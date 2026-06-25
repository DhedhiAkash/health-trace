import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/health_provider.dart';

class PermissionDeniedScreen extends StatefulWidget {
  const PermissionDeniedScreen({super.key});

  @override
  State<PermissionDeniedScreen> createState() => _PermissionDeniedScreenState();
}

class _PermissionDeniedScreenState extends State<PermissionDeniedScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    // Register this screen to listen to app lifecycle events (like background/foreground transitions)
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // Unregister the observer when leaving the screen
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // TRIGGERED AUTOMATICALLY WHEN USER RETURNS TO THE APP
    if (state == AppLifecycleState.resumed) {
      final provider = context.read<HealthProvider>();

      // If they were stuck on the missing app screen, check if they finished installing it
      if (provider.permissionState == HealthPermissionState.missingApp) {
        provider.requestAppPermissions();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final providerState = context.watch<HealthProvider>().permissionState;
    final bool isPermanentlyDenied =
        providerState == HealthPermissionState.permanentlyDenied;
    final bool isMissingApp = providerState == HealthPermissionState.missingApp;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isMissingApp
                      ? Colors.orange.shade700
                      : (isPermanentlyDenied ? Colors.grey : AppColors.primary),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isMissingApp ? Icons.download_rounded : Icons.add_moderator,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                flex: 4,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: AppColors.accentFill,
                  ),
                  child: Center(
                    child: Icon(
                      isMissingApp
                          ? Icons.shop_two_outlined
                          : Icons.lock_person_outlined,
                      size: 100,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Icon(
                Icons.error_outline_rounded,
                color: isMissingApp ? Colors.orange : Colors.redAccent,
                size: 32,
              ),
              const SizedBox(height: 12),
              Text(
                isMissingApp ? "Health Connect Missing" : "Access Required",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isMissingApp
                    ? "Health Trace reads your data via Android Health Connect. It looks like the Health Connect app isn't installed on your device yet. Please install it from the Google Play Store to continue."
                    : isPermanentlyDenied
                    ? "Activity tracking and health tracking permissions have been permanently disabled. To fix this, you must open your system settings below."
                    : "To provide accurate insights, Health Trace needs access to your step count and sleep data from Health Connect. This permission was previously denied.",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textMuted,
                  height: 1.5,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isMissingApp
                        ? Colors.green.shade700
                        : (isPermanentlyDenied
                              ? Colors.grey.shade300
                              : AppColors.primary),
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  onPressed: isPermanentlyDenied
                      ? null
                      : () async {
                          if (isMissingApp) {
                            final Uri playStoreUri = Uri.parse(
                              "market://details?id=com.google.android.apps.healthdata",
                            );
                            final Uri browserFallbackUri = Uri.parse(
                              "https://play.google.com/store/apps/details?id=com.google.android.apps.healthdata",
                            );
                            try {
                              if (!await launchUrl(
                                playStoreUri,
                                mode: LaunchMode.externalApplication,
                              )) {
                                await launchUrl(
                                  browserFallbackUri,
                                  mode: LaunchMode.externalApplication,
                                );
                              }
                            } catch (e) {
                              await launchUrl(
                                browserFallbackUri,
                                mode: LaunchMode.externalApplication,
                              );
                            }
                          } else {
                            context
                                .read<HealthProvider>()
                                .requestAppPermissions();
                          }
                        },
                  child: Text(
                    isMissingApp
                        ? "Install Health Connect"
                        : (isPermanentlyDenied
                              ? "Permanently Denied"
                              : "Retry Permission"),
                    style: TextStyle(
                      color: isPermanentlyDenied
                          ? Colors.grey.shade600
                          : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: (isPermanentlyDenied || isMissingApp)
                          ? AppColors.primary
                          : AppColors.borderLine,
                      width: (isPermanentlyDenied || isMissingApp) ? 1.5 : 1.0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  onPressed: () {
                    if (isMissingApp) {
                      context.read<HealthProvider>().loginWithSampleData();
                    } else {
                      openAppSettings();
                    }
                  },
                  child: Text(
                    isMissingApp
                        ? "Explore with Demo Sandbox"
                        : "Open System Settings",
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
