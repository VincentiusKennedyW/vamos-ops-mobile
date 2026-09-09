import 'package:flutter/material.dart';
import 'package:vamos_ops_mobile/app/core/theme/app_tokens.dart';

class DetailPill extends StatelessWidget {
  const DetailPill({super.key, required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: color,
        fontSize: AppText.xs,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
