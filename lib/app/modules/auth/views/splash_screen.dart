import 'package:flutter/material.dart';
import 'package:vamos_ops_mobile/app/core/theme/app_tokens.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: TweenAnimationBuilder<double>(
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 700),
          curve: const Cubic(0.16, 1, 0.3, 1),
          tween: Tween(begin: 0, end: 1),
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 18 * (1 - value)),
              child: Transform.scale(
                scale: 0.96 + (0.04 * value),
                child: child,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 44),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'vamos-logo.png',
                  width: 260,
                  semanticLabel: 'Vamos Arena Fit',
                ),
                const SizedBox(height: 30),
                const SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'VAMOS OPS',
                  style: TextStyle(
                    color: AppColors.onSurface,
                    fontSize: AppText.base,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.1,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Menyiapkan operasional venue',
                  style: TextStyle(
                    color: AppColors.onSurfaceMuted,
                    fontSize: AppText.base,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
