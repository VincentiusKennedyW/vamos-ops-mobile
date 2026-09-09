import 'package:flutter/material.dart';
import 'package:vamos_ops_mobile/app/core/theme/app_tokens.dart';

class ReportTile extends StatelessWidget {
  const ReportTile({
    super.key,
    required this.title,
    required this.category,
    required this.area,
    required this.time,
    required this.status,
    required this.color,
    required this.onTap,
  });
  final String title, category, area, time, status;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  category,
                  style: TextStyle(
                    color: color,
                    fontSize: AppText.xs,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: color,
                      fontSize: AppText.xs,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.onSurfaceMuted,
                ),
              ],
            ),
            const SizedBox(height: 11),
            Text(
              title,
              style: const TextStyle(
                fontSize: AppText.md,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              '$area  ·  $time',
              style: const TextStyle(
                color: AppColors.onSurfaceMuted,
                fontSize: AppText.xs,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
