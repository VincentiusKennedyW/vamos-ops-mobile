import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:vamos_ops_mobile/app/data/repositories/ops_repository.dart';
import 'package:vamos_ops_mobile/app/core/services/device_services.dart';
import 'package:vamos_ops_mobile/app/routes/app_routes.dart';
import 'package:vamos_ops_mobile/data.dart';
import 'package:vamos_ops_mobile/vamos_app.dart';

void main() {
  test('selected filter chip uses a readable brand color pair', () {
    final chip = buildVamosTheme().chipTheme;
    expect(chip.selectedColor, AppColors.primary);
    expect(chip.secondaryLabelStyle?.color, AppColors.onPrimary);
    expect(chip.checkmarkColor, AppColors.onPrimary);
  });

  testWidgets('staff home exposes core shift actions', (tester) async {
    await tester.pumpWidget(
      VamosApp(
        initialRoute: AppRoutes.staff,
        initialBinding: BindingsBuilder(() {
          Get.put<OpsRepositoryContract>(_WidgetRepository());
        }),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Selamat pagi, Andi'), findsOneWidget);
    expect(find.text('ON DUTY'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Lapor temuan'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Lapor temuan'), findsOneWidget);
    expect(find.text('Beranda'), findsOneWidget);
    expect(find.text('Task'), findsOneWidget);
  });
}

class _WidgetRepository implements OpsRepositoryContract {
  @override
  Future<OpsTask> createTask({
    required String title,
    required String description,
    required String priority,
    required String evidencePolicy,
    required DateTime scheduledAt,
    required DateTime dueAt,
  }) async => OpsTask(
    id: 'created-task',
    title: title,
    area: 'Venue',
    time: '10:00',
    kind: TaskKind.routine,
    state: TaskState.pending,
  );

  @override
  Future<String> uploadTaskEvidence(
    String taskId,
    CapturedPhoto photo, {
    required String phase,
    required String description,
  }) async => 'evidence-1';

  @override
  Future<String> uploadPurposePhoto(
    String purpose,
    CapturedPhoto photo,
  ) async => 'evidence-1';

  @override
  Future<StaffHomeData> getHome() async => const StaffHomeData(
    userName: 'Andi Saputra',
    userRole: 'Crew Padel',
    attendanceStatus: 'ON_DUTY',
    checkInAt: null,
    tasks: [],
    reports: [],
  );

  @override
  Future<void> createReport({
    required String title,
    required String description,
    required String category,
    required String priority,
    String? areaId,
    String? sourceTaskId,
    required String evidenceId,
  }) async {}

  @override
  Future<void> recordAttendance({
    required String action,
    required double latitude,
    required double longitude,
    required String selfieId,
  }) async {}

  @override
  Future<void> submitHandover({
    required int completedCount,
    required int totalCount,
    required List<String> outstandingTaskIds,
    required String notes,
  }) async {}

  @override
  Future<OpsTask> updateTask(String taskId, TaskState state) async => OpsTask(
    id: taskId,
    title: 'Task',
    area: 'Venue',
    time: '10:00',
    kind: TaskKind.routine,
    state: state,
  );
}
