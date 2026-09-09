import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:vamos_ops_mobile/app/data/models/ops_area.dart';
import 'package:vamos_ops_mobile/app/data/repositories/ops_repository_contract.dart';
import 'package:vamos_ops_mobile/app/modules/reports/views/report_form_sheet.dart';
import 'package:vamos_ops_mobile/app/modules/staff/controllers/staff_controller.dart';

import 'support/fake_ops_repository.dart' show FakeOpsRepository;
import 'support/tracking_camera.dart' show TrackingCamera;

class AreaFormRepository extends FakeOpsRepository
    implements AreasRepositoryContract {
  String? selectedArea;
  @override
  Future<List<OpsArea>> getAreas() async => [
    const OpsArea('court-id', 'Court 1'),
  ];
  @override
  Future<void> createReport({
    required String title,
    required String description,
    required String category,
    required String priority,
    String? areaId,
    String? sourceTaskId,
    required String evidenceId,
  }) async {
    selectedArea = areaId;
  }
}

void main() {
  tearDown(Get.reset);
  testWidgets('report sends the selected master area', (tester) async {
    final repo = AreaFormRepository();
    final controller = StaffController(repo, cameraService: TrackingCamera());
    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showReportSheet(context, controller),
              child: const Text('Open report'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open report'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('report-area-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Court 1').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Temuan di Court 1');
    await tester.ensureVisible(find.text('KIRIM REPORT'));
    await tester.tap(find.text('KIRIM REPORT'));
    await tester.pumpAndSettle();
    expect(repo.selectedArea, 'court-id');
    expect(tester.takeException(), isNull);
  });
}
