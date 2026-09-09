import 'package:flutter/material.dart';
import 'package:vamos_ops_mobile/app/core/theme/app_tokens.dart';

class PageFooter extends StatelessWidget {
  const PageFooter({
    super.key,
    required this.loading,
    required this.hasMore,
    required this.empty,
    required this.emptyText,
    this.error,
    this.onMore,
    this.onRetry,
  });
  final bool loading, hasMore, empty;
  final String emptyText;
  final String? error;
  final VoidCallback? onMore, onRetry;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Column(
      children: [
        if (error != null) ...[
          Text(error!, style: const TextStyle(color: AppColors.danger)),
          TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
        ] else if (loading)
          const Center(child: CircularProgressIndicator())
        else if (empty)
          Text(
            emptyText,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.onSurfaceMuted),
          ),
        if (hasMore && error == null)
          OutlinedButton(
            onPressed: loading ? null : onMore,
            child: const Text('Muat lebih banyak'),
          ),
      ],
    ),
  );
}
