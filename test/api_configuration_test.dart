import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:vamos_ops_mobile/app/core/config/app_config.dart';
import 'package:vamos_ops_mobile/app/core/errors/api_exception.dart';
import 'package:vamos_ops_mobile/app/data/providers/ops_api_provider.dart';
import 'package:vamos_ops_mobile/app/data/repositories/ops_repository.dart';
import 'package:vamos_ops_mobile/app/modules/staff/controllers/staff_controller.dart';

void main() {
  test('mobile defaults to the configured LAN host', () {
    expect(AppConfig.apiBaseUrl, 'http://10.175.194.43:3000/api/v1');
  });

  test('controller does not expose demo task IDs before API sync', () {
    final controller = StaffController(OpsRepository(_OfflineProvider()));

    expect(controller.tasks, isEmpty);
  });

  test('network failure explains which API URL is unreachable', () async {
    final repository = OpsRepository(_OfflineProvider());

    await expectLater(
      repository.getHome(),
      throwsA(
        isA<ApiException>()
            .having(
              (error) => error.message,
              'message',
              contains('Tidak dapat terhubung'),
            )
            .having((error) => error.message, 'message', contains('/api/v1')),
      ),
    );
  });
}

class _OfflineProvider extends OpsApiProvider {
  @override
  Future<Response<dynamic>> fetchHome() async => const Response<dynamic>(
    statusCode: null,
    statusText: 'SocketException: Connection refused',
  );
}
