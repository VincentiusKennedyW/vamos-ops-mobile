import 'package:get/get.dart';
import 'package:vamos_ops_mobile/app/core/services/device_services.dart';
import 'package:vamos_ops_mobile/app/core/services/ops_cache.dart';
import 'package:vamos_ops_mobile/app/core/storage/session_store.dart';
import 'package:vamos_ops_mobile/app/data/providers/ops_api_provider.dart';
import 'package:vamos_ops_mobile/app/data/repositories/ops_repository.dart';
import 'package:vamos_ops_mobile/app/data/repositories/ops_repository_contract.dart';
import 'package:vamos_ops_mobile/app/modules/auth/controllers/auth_controller.dart';
import 'package:vamos_ops_mobile/app/modules/auth/data/auth_api_provider.dart';
import 'package:vamos_ops_mobile/app/modules/auth/data/auth_repository.dart';

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
