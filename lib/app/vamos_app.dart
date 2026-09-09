import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vamos_ops_mobile/app/bindings/app_binding.dart';
import 'package:vamos_ops_mobile/app/core/theme/app_tokens.dart';
import 'package:vamos_ops_mobile/app/routes/app_pages.dart';
import 'package:vamos_ops_mobile/app/routes/app_routes.dart';

class VamosApp extends StatelessWidget {
  const VamosApp({super.key, this.initialBinding, this.initialRoute});

  final Bindings? initialBinding;
  final String? initialRoute;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'VAMOS OPS',
      debugShowCheckedModeBanner: false,
      theme: buildVamosTheme(),
      initialBinding: initialBinding ?? AppBinding(),
      initialRoute: initialRoute ?? AppRoutes.splash,
      defaultTransition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 320),
      getPages: AppPages.pages,
    );
  }
}
