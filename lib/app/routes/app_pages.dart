import 'package:get/get.dart';
import 'package:vamos_ops_mobile/app/modules/auth/views/login_screen.dart';
import 'package:vamos_ops_mobile/app/modules/auth/views/splash_screen.dart';
import 'package:vamos_ops_mobile/app/modules/staff/bindings/staff_binding.dart';
import 'package:vamos_ops_mobile/app/modules/staff/views/staff_shell.dart';
import 'package:vamos_ops_mobile/app/routes/app_routes.dart';

abstract final class AppPages {
  static final pages = <GetPage<dynamic>>[
    GetPage<dynamic>(
      name: AppRoutes.splash,
      page: SplashScreen.new,
      transition: Transition.noTransition,
    ),
    GetPage<dynamic>(
      name: AppRoutes.login,
      page: LoginScreen.new,
      transition: Transition.fadeIn,
    ),
    GetPage<dynamic>(
      name: AppRoutes.staff,
      page: StaffShell.new,
      binding: StaffBinding(),
      transition: Transition.fadeIn,
    ),
  ];
}
