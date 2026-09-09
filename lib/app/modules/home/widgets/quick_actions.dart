import 'package:flutter/material.dart';
import 'package:vamos_ops_mobile/app/core/theme/app_tokens.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({
    super.key,
    required this.onReport,
    required this.onFinish,
  });
  final VoidCallback onReport;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    Widget action({
      required IconData icon,
      required String label,
      required String caption,
      required VoidCallback onTap,
      required Color tone,
      required Color background,
    }) => Expanded(
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            constraints: const BoxConstraints(minHeight: 112),
            padding: const EdgeInsets.all(AppSpace.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(icon, size: 19, color: tone),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: AppText.md,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      caption,
                      style: const TextStyle(
                        color: AppColors.onSurfaceMuted,
                        fontSize: AppText.sm,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    // IntrinsicHeight so both tiles match the taller one. A bare
    // CrossAxisAlignment.stretch would ask for infinite height inside the
    // unbounded sliver list and blow up layout.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          action(
            icon: Icons.flag_outlined,
            label: 'Lapor temuan',
            caption: 'Kerusakan atau stok',
            onTap: onReport,
            tone: AppColors.warningText,
            background: AppColors.warningSubtle,
          ),
          const SizedBox(width: AppSpace.md),
          action(
            icon: Icons.logout_rounded,
            label: 'Clock Out',
            caption: 'Catat Clock Out hari ini',
            onTap: onFinish,
            tone: AppColors.dangerText,
            background: AppColors.dangerSubtle,
          ),
        ],
      ),
    );
  }
}
