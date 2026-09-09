import 'package:flutter/material.dart';
import 'package:vamos_ops_mobile/app/core/theme/app_tokens.dart';

class StatStrip extends StatelessWidget {
  const StatStrip({
    super.key,
    required this.total,
    required this.completed,
    required this.needsPhoto,
  });
  final int total;
  final int completed;
  final int needsPhoto;

  @override
  Widget build(BuildContext context) {
    Widget tile(String value, String label, IconData icon, Color tone) =>
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.md,
              vertical: AppSpace.md,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 18, color: tone),
                const SizedBox(height: AppSpace.sm),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: AppText.xxl,
                    fontFamily: AppText.displayFamily,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.onSurfaceMuted,
                    fontSize: AppText.sm,
                  ),
                ),
              ],
            ),
          ),
        );
    return Row(
      children: [
        tile(
          '$total',
          'Task hari ini',
          Icons.task_alt_rounded,
          AppColors.onSurfaceMuted,
        ),
        const SizedBox(width: AppSpace.md),
        tile(
          '$completed',
          'Selesai',
          Icons.check_circle_outline_rounded,
          AppColors.successText,
        ),
        const SizedBox(width: AppSpace.md),
        tile(
          '$needsPhoto',
          'Perlu bukti',
          Icons.photo_camera_outlined,
          AppColors.warningText,
        ),
      ],
    );
  }
}

/// Two-up action grid. Replaces the single full-width outlined button plus the
/// low-contrast text link that previously hid Clock Out at the very bottom;
/// destructive/shift-ending actions stay visually separated (HIG).
