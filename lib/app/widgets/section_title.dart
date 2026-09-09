import 'package:flutter/material.dart';
import 'package:vamos_ops_mobile/app/core/theme/app_tokens.dart';

class SectionTitle extends StatelessWidget {
  const SectionTitle({
    super.key,
    required this.title,
    required this.caption,
    this.count,
  });
  final String title;
  final String caption;
  final int? count;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: AppText.xl,
                    fontFamily: AppText.displayFamily,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (count != null) ...[
                  const SizedBox(width: AppSpace.sm),
                  Container(
                    constraints: const BoxConstraints(minWidth: 24),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceRaised,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      '$count',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: AppText.xs,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurfaceMuted,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 2),
            Text(
              caption,
              style: const TextStyle(
                color: AppColors.onSurfaceMuted,
                fontSize: AppText.base,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

/// Compact figure strip under the shift card. Three read-only stats that answer
/// "how much is left today" without opening the Task tab.
