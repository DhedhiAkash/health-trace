import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/health_provider.dart';

class SyncBannerWidget extends StatelessWidget {
  const SyncBannerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HealthProvider>();
    final isLiveConnected =
        provider.permissionState == HealthPermissionState.authorized;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isLiveConnected ? Colors.white : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLiveConnected
              ? AppColors.borderLine
              : const Color(0xFFFCA5A5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                isLiveConnected ? Icons.sync_alt : Icons.error_outline_rounded,
                color: isLiveConnected
                    ? AppColors.textGreen
                    : const Color(0xFFEF4444),
                size: 18,
              ),
              const SizedBox(width: 10),
              Text(
                isLiveConnected
                    ? "Health Connect: Connected"
                    : "Preview Mode (Sample Data)",
                style: TextStyle(
                  color: isLiveConnected
                      ? AppColors.textDark
                      : const Color(0xFF991B1B),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (!isLiveConnected)
            GestureDetector(
              onTap: () {
                if (provider.permissionState ==
                    HealthPermissionState.sampleData) {
                  provider.resetToUnknown();
                } else {
                  provider
                      .requestAppPermissions(); // Baaki states ke liye normal flow
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "Connect",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
