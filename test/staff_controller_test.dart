import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:vamos_ops_mobile/app/core/services/device_services.dart';
import 'package:vamos_ops_mobile/app/modules/staff/controllers/staff_controller.dart';
import 'package:vamos_ops_mobile/app/modules/tasks/models/ops_task.dart';

import 'support/fake_ops_repository.dart';

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(Get.reset);

  test('refreshHome maps repository data into reactive state', () async {
    final repository = FakeOpsRepository();
    final controller = StaffController(repository);

    await controller.refreshHome();

    expect(controller.isOnline.value, isTrue);
    expect(controller.userName.value, 'API Staff');
    expect(controller.tasks.single.title, 'API task');
  });

  test('failed mutation rolls optimistic task state back', () async {
    final repository = FakeOpsRepository()..failTaskUpdate = true;
    final controller = StaffController(repository);
    await controller.refreshHome();
    final task = controller.tasks.single;

    final saved = await controller.setTaskState(task, TaskState.done);

    expect(saved, isFalse);
    expect(controller.tasks.single.state, TaskState.pending);
  });

  test('task state changes immediately and uses no refresh request', () async {
    final repository = FakeOpsRepository()
      ..taskUpdateCompleter = Completer<OpsTask>();
    final controller = StaffController(repository);
    await controller.refreshHome();

    final pending = controller.setTaskState(
      controller.tasks.single,
      TaskState.done,
    );

    expect(controller.tasks.single.state, TaskState.done);
    expect(controller.completedToday.value, 1);
    expect(repository.homeCalls, 1);
    repository.taskUpdateCompleter!.complete(
      controller.tasks.single.copyWith(id: 'task-api', state: TaskState.done),
    );
    expect(await pending, isTrue);
    expect(repository.homeCalls, 1);
  });

  test('camera evidence is uploaded and linked to its task', () async {
    final repository = FakeOpsRepository();
    final controller = StaffController(
      repository,
      cameraService: _FakeCameraService(),
    );
    await controller.refreshHome();

    final path = await controller.captureTaskEvidence(
      'task-api',
      description: 'Kondisi akhir sudah bersih.',
    );

    expect(path, '/tmp/evidence.jpg');
    expect(repository.uploadedTaskId, 'task-api');
    expect(repository.uploadedPhase, 'AFTER');
    expect(repository.uploadedDescription, 'Kondisi akhir sudah bersih.');
    expect(controller.tasks.single.evidenceCount, 1);
    expect(controller.tasks.single.afterEvidenceCount, 1);
    expect(repository.homeCalls, 1);
  });

  test('task cannot start before Clock In', () async {
    final repository = FakeOpsRepository();
    final controller = StaffController(repository);
    controller.tasks.assignAll(const [
      OpsTask(
        id: 'blocked-task',
        title: 'Blocked task',
        area: 'Venue',
        time: '10:00',
        kind: TaskKind.routine,
        state: TaskState.pending,
      ),
    ]);

    final saved = await controller.setTaskState(
      controller.tasks.single,
      TaskState.inProgress,
    );

    expect(saved, isFalse);
    expect(
      controller.errorMessage.value,
      'Lakukan Clock In sebelum memulai task.',
    );
    expect(repository.updateCalls, 0);
  });

  test('task cannot start after Clock Out', () async {
    final repository = FakeOpsRepository();
    final controller = StaffController(repository);
    controller.attendanceStatus.value = 'ON_DUTY';
    controller.checkOutAt.value = DateTime(2026, 9, 3, 18);
    controller.tasks.assignAll(const [
      OpsTask(
        id: 'closed-task',
        title: 'Closed task',
        area: 'Venue',
        time: '18:01',
        kind: TaskKind.routine,
        state: TaskState.pending,
      ),
    ]);

    final saved = await controller.setTaskState(
      controller.tasks.single,
      TaskState.inProgress,
    );

    expect(saved, isFalse);
    expect(controller.errorMessage.value, contains('Clock Out sudah tercatat'));
    expect(repository.updateCalls, 0);
  });

  test('attendance uses coordinates reported by the device', () async {
    final repository = FakeOpsRepository();
    final controller = StaffController(
      repository,
      locationService: const _FakeLocationService(),
      cameraService: _FakeCameraService(),
    );

    await controller.clockIn();

    expect(repository.lastLatitude, -8.65);
    expect(repository.lastLongitude, 115.21);
  });

  test(
    'staff creates a personal task optimistically without refresh',
    () async {
      final repository = FakeOpsRepository()
        ..taskCreateCompleter = Completer<OpsTask>();
      final controller = StaffController(repository);
      await controller.refreshHome();

      final pending = controller.createTask(
        title: 'Cek stok handuk',
        description: 'Rak depan',
        scheduledAt: DateTime(2026, 9, 3, 16),
        dueAt: DateTime(2026, 9, 3, 17),
      );

      expect(controller.tasks.first.id, startsWith('optimistic-'));
      expect(controller.tasks.first.title, 'Cek stok handuk');
      expect(repository.homeCalls, 1);
      repository.taskCreateCompleter!.complete(
        OpsTask(
          id: 'created-task',
          title: 'Cek stok handuk',
          area: 'Venue',
          time: '17:00',
          kind: TaskKind.routine,
          state: TaskState.pending,
          scheduledAt: DateTime(2026, 9, 3, 16),
          dueAt: DateTime(2026, 9, 3, 17),
        ),
      );
      expect(await pending, isTrue);
      expect(controller.tasks.first.id, 'created-task');
      expect(repository.createdTaskTitle, 'Cek stok handuk');
      expect(repository.createdTaskScheduledAt, DateTime(2026, 9, 3, 16));
      expect(controller.isOnline.value, isTrue);
      expect(repository.homeCalls, 1);
    },
  );
}

class _FakeCameraService implements CameraServiceContract {
  @override
  Future<CapturedPhoto?> capturePhoto({bool frontCamera = false}) async =>
      const CapturedPhoto(
        path: '/tmp/evidence.jpg',
        name: 'evidence.jpg',
        mimeType: 'image/jpeg',
      );
}

class _FakeLocationService implements LocationServiceContract {
  const _FakeLocationService();
  @override
  Future<DevicePosition> currentPosition() async =>
      const DevicePosition(latitude: -8.65, longitude: 115.21);
}
