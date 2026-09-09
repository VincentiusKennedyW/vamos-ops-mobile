import 'package:get/get.dart';
import '../../../core/services/ops_cache.dart';

import '../../../core/storage/session_store.dart';
import '../../../core/services/device_services.dart';
import '../../../data/providers/ops_api_provider.dart';
import '../../../data/repositories/ops_repository.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/data/auth_api_provider.dart';
import '../../auth/data/auth_repository.dart';
import '../controllers/staff_controller.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<OpsCache>(OpsCache(), permanent: true);
    Get.put<SessionStoreContract>(SessionStore(), permanent: true);
    Get.put<AuthApiProvider>(AuthApiProvider(), permanent: true);
    Get.put<AuthRepositoryContract>(
      AuthRepository(
        Get.find<AuthApiProvider>(),
        Get.find<SessionStoreContract>(),
      ),
      permanent: true,
    );
    Get.put<AuthController>(
      AuthController(Get.find<AuthRepositoryContract>()),
      permanent: true,
    );
    Get.put<OpsApiProvider>(
      OpsApiProvider(Get.find<SessionStoreContract>()),
      permanent: true,
    );
    Get.put<OpsRepositoryContract>(
      OpsRepository(Get.find<OpsApiProvider>()),
      permanent: true,
    );
    Get.put<LocationServiceContract>(
      const DeviceLocationService(),
      permanent: true,
    );
    Get.put<CameraServiceContract>(DeviceCameraService(), permanent: true);
  }
}

class StaffBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<StaffController>(
      () => StaffController(
        Get.find<OpsRepositoryContract>(),
        cache: Get.isRegistered<OpsCache>() ? Get.find<OpsCache>() : null,
        locationService: Get.isRegistered<LocationServiceContract>()
            ? Get.find<LocationServiceContract>()
            : const VenueFallbackLocationService(),
        cameraService: Get.isRegistered<CameraServiceContract>()
            ? Get.find<CameraServiceContract>()
            : null,
      ),
      fenix: true,
    );
  }
}
