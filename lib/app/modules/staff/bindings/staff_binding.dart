import 'package:get/get.dart';
import 'package:vamos_ops_mobile/app/core/services/device_services.dart';
import 'package:vamos_ops_mobile/app/core/services/ops_cache.dart';
import 'package:vamos_ops_mobile/app/data/repositories/ops_repository_contract.dart';
import 'package:vamos_ops_mobile/app/modules/staff/controllers/staff_controller.dart';

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
