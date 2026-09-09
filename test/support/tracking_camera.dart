import 'package:vamos_ops_mobile/app/core/services/device_services.dart';

class TrackingCamera implements CameraServiceContract {
  final frontRequests = <bool>[];
  @override
  Future<CapturedPhoto?> capturePhoto({bool frontCamera = false}) async {
    frontRequests.add(frontCamera);
    return const CapturedPhoto(
      path: '/tmp/test.jpg',
      name: 'test.jpg',
      mimeType: 'image/jpeg',
    );
  }
}
