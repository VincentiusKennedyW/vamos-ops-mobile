import 'package:get/get.dart';
import '../../../core/services/ops_cache.dart';

import '../../../core/errors/api_exception.dart';
import '../../../routes/app_routes.dart';
import '../data/auth_repository.dart';
import '../models/auth_session.dart';

class AuthController extends GetxController {
  AuthController(this._repository);

  final AuthRepositoryContract _repository;
  final isBootstrapping = true.obs;
  final isAuthenticating = false.obs;
  final obscurePassword = true.obs;
  final errorMessage = RxnString();
  final user = Rxn<AuthUser>();

  @override
  void onReady() {
    super.onReady();
    bootstrap();
  }

  Future<void> bootstrap() async {
    isBootstrapping.value = true;
    errorMessage.value = null;
    try {
      final session = await _repository.restore();
      user.value = session?.user;
      Get.offAllNamed(session == null ? AppRoutes.login : AppRoutes.staff);
    } on ApiException catch (error) {
      errorMessage.value = error.message;
      Get.offAllNamed(AppRoutes.login);
    } catch (_) {
      errorMessage.value =
          'Sesi tidak dapat diverifikasi. Silakan masuk ulang.';
      Get.offAllNamed(AppRoutes.login);
    } finally {
      isBootstrapping.value = false;
    }
  }

  Future<bool> login(String email, String password) async {
    if (isAuthenticating.value) return false;
    if (email.trim().isEmpty || password.isEmpty) {
      errorMessage.value = 'Email dan kata sandi wajib diisi.';
      return false;
    }
    isAuthenticating.value = true;
    errorMessage.value = null;
    try {
      final session = await _repository.login(email, password);
      if (Get.isRegistered<OpsCache>()) Get.find<OpsCache>().clear();
      user.value = session.user;
      Get.offAllNamed(AppRoutes.staff);
      return true;
    } on ApiException catch (error) {
      errorMessage.value = error.message;
      return false;
    } catch (_) {
      errorMessage.value = 'Login gagal. Periksa koneksi lalu coba lagi.';
      return false;
    } finally {
      isAuthenticating.value = false;
    }
  }

  Future<void> logout() async {
    if (isAuthenticating.value) return;
    isAuthenticating.value = true;
    errorMessage.value = null;
    try {
      await _repository.logout();
    } catch (_) {
      // The local credential must still be cleared by the repository.
    } finally {
      if (Get.isRegistered<OpsCache>()) Get.find<OpsCache>().clear();
      user.value = null;
      isAuthenticating.value = false;
      Get.offAllNamed(AppRoutes.login);
    }
  }
}
