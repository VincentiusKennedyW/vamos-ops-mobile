import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../errors/api_exception.dart';

class DevicePosition {
  const DevicePosition({required this.latitude, required this.longitude});
  final double latitude;
  final double longitude;
}

class CapturedPhoto {
  const CapturedPhoto({
    required this.path,
    required this.name,
    required this.mimeType,
  });
  final String path;
  final String name;
  final String mimeType;
}

abstract interface class LocationServiceContract {
  Future<DevicePosition> currentPosition();
}

abstract interface class CameraServiceContract {
  Future<CapturedPhoto?> capturePhoto({bool frontCamera = false});
}

class DeviceLocationService implements LocationServiceContract {
  const DeviceLocationService();

  @override
  Future<DevicePosition> currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const ApiException(
        'Lokasi perangkat tidak aktif. Aktifkan GPS lalu coba lagi.',
      );
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const ApiException(
        'Izin lokasi diperlukan untuk check-in dan check-out.',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw const ApiException(
        'Izin lokasi diblokir. Aktifkan kembali dari pengaturan perangkat.',
      );
    }
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
    return DevicePosition(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }
}

class DeviceCameraService implements CameraServiceContract {
  DeviceCameraService({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();
  final ImagePicker _picker;

  @override
  Future<CapturedPhoto?> capturePhoto({bool frontCamera = false}) async {
    final photo = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: frontCamera
          ? CameraDevice.front
          : CameraDevice.rear,
      imageQuality: 82,
      maxWidth: 1920,
      maxHeight: 1920,
      requestFullMetadata: false,
    );
    if (photo == null) return null;
    final lowerName = photo.name.toLowerCase();
    final mimeType = lowerName.endsWith('.png')
        ? 'image/png'
        : lowerName.endsWith('.webp')
        ? 'image/webp'
        : 'image/jpeg';
    return CapturedPhoto(
      path: photo.path,
      name: photo.name,
      mimeType: mimeType,
    );
  }
}

class VenueFallbackLocationService implements LocationServiceContract {
  const VenueFallbackLocationService();
  @override
  Future<DevicePosition> currentPosition() async =>
      const DevicePosition(latitude: -8.670458, longitude: 115.212629);
}
