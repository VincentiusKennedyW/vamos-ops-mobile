import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:vamos_ops_mobile/app/core/errors/api_exception.dart';
import 'package:vamos_ops_mobile/app/core/services/device_services.dart';
import 'package:vamos_ops_mobile/app/data/models/staff_home_data.dart';
import 'package:vamos_ops_mobile/app/data/repositories/ops_repository_contract.dart';
import 'package:vamos_ops_mobile/app/modules/attendance/views/handover_sheet.dart';
import 'package:vamos_ops_mobile/app/modules/home/views/home_screen.dart';
import 'package:vamos_ops_mobile/app/modules/profile/views/me_screen.dart';
import 'package:vamos_ops_mobile/app/modules/reports/models/ops_report.dart';
import 'package:vamos_ops_mobile/app/modules/reports/views/report_form_sheet.dart';
import 'package:vamos_ops_mobile/app/modules/staff/controllers/staff_controller.dart';
import 'package:vamos_ops_mobile/app/modules/tasks/models/ops_task.dart';
import 'package:vamos_ops_mobile/app/modules/tasks/models/task_evidence.dart';
import 'package:vamos_ops_mobile/app/modules/tasks/views/create_task_sheet.dart';
import 'package:vamos_ops_mobile/app/modules/tasks/views/task_detail_sheet.dart';
import 'package:vamos_ops_mobile/app/routes/app_routes.dart';
import 'package:vamos_ops_mobile/app/vamos_app.dart';

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  testWidgets('completed task shows stored photo in detail on small screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final task = OpsTask(
      id: 'done-photo',
      title: 'Pekerjaan selesai',
      area: 'Court 2',
      time: '08:00',
      kind: TaskKind.routine,
      state: TaskState.done,
      evidence: [
        TaskEvidence(
          id: 'stored-photo',
          phase: 'AFTER',
          description: '',
          createdAt: DateTime(2026, 9, 7, 8),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () =>
                  showTaskSheet(context, task, (_, __) async => true),
              child: const Text('OPEN'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byType(Image),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Bukti foto'), findsOneWidget);
    final photo = tester.widget<Image>(find.byType(Image).first);
    expect((photo.image as NetworkImage).url, contains('/media/stored-photo'));
    expect(find.text('END TASK'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('home notification affordance is actionable', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeScreen(
            userName: 'Andi Saputra',
            userRole: 'Crew Padel',
            isOnline: true,
            onDuty: true,
            tasks: const [],
            completed: 0,
            onStart: () {},
            onTask: (_) {},
            onReport: () {},
            onFinish: () {},
          ),
        ),
      ),
    );

    expect(
      find.ancestor(
        of: find.byIcon(Icons.notifications_none_rounded),
        matching: find.byType(InkWell),
      ),
      findsOneWidget,
    );
  });

  testWidgets('profile settings and sync status are actionable', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: MeScreen())),
    );

    expect(
      find.ancestor(
        of: find.byIcon(Icons.settings_outlined),
        matching: find.byType(InkWell),
      ),
      findsOneWidget,
    );
    final syncTile = tester.widget<ListTile>(
      find.widgetWithText(ListTile, 'Semua data tersinkron'),
    );
    expect(syncTile.onTap, isNotNull);
  });

  testWidgets('photo evidence affordance is actionable', (tester) async {
    const task = OpsTask(
      id: 'photo-task',
      title: 'Bersihkan kaca',
      area: 'Court 2',
      time: '10:00',
      kind: TaskKind.manager,
      state: TaskState.pending,
      photoRequired: true,
      evidencePolicy: 'before_after',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () =>
                  showTaskSheet(context, task, (_, __) async => true),
              child: const Text('OPEN'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add_circle));
    await tester.pump();
    expect(find.text('Deskripsi foto minimal 3 karakter.'), findsNothing);
    expect(find.text('Kamera tidak tersedia pada sesi ini.'), findsOneWidget);
    expect(
      find.ancestor(
        of: find.byIcon(Icons.add_circle),
        matching: find.byType(InkWell),
      ),
      findsOneWidget,
    );
    expect(find.text('Informasi'), findsOneWidget);
    expect(find.text('Kamera tidak tersedia pada sesi ini.'), findsOneWidget);
  });

  testWidgets('ordinary inspection task ends without checklist or photo', (
    tester,
  ) async {
    TaskState? savedState;
    const task = OpsTask(
      id: '40000000-0000-0000-0000-000000000002',
      title: 'Inspeksi toilet area padel',
      area: 'Toilet',
      time: '10:30',
      kind: TaskKind.routine,
      state: TaskState.inProgress,
      evidencePolicy: 'none',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () => showTaskSheet(context, task, (
                _,
                state, {
                checklistResponse,
              }) async {
                savedState = state;
                return true;
              }),
              child: const Text('OPEN'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();
    expect(find.text('Menipis'), findsNothing);
    expect(find.byKey(const Key('task-evidence-description')), findsNothing);
    await tester.ensureVisible(find.text('END TASK'));
    await tester.tap(find.text('END TASK'));
    await tester.pumpAndSettle();
    expect(savedState, TaskState.done);
  });

  testWidgets('empty report submission shows validation feedback', (
    tester,
  ) async {
    final controller = StaffController(_FakeRepository());
    await tester.pumpWidget(
      GetMaterialApp(
        home: Builder(
          builder: (context) => FilledButton(
            onPressed: () => showReportSheet(context, controller),
            child: const Text('OPEN'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('KIRIM REPORT'));
    await tester.pump();

    expect(find.text('Deskripsi minimal 3 karakter.'), findsOneWidget);
  });

  testWidgets('staff create-task sheet validates and submits to repository', (
    tester,
  ) async {
    final repository = _FakeRepository();
    final controller = StaffController(repository);
    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () => showCreateTaskSheet(context, controller),
              child: const Text('OPEN TASK FORM'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('OPEN TASK FORM'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('create-task-start-time')), findsOneWidget);
    expect(find.byKey(const Key('create-task-due-time')), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('create-task-title')),
      'Cek stok handuk',
    );
    // The sheet is a lazy ListView; the submit button is only built once the
    // list has scrolled to it, so drive the scroll instead of ensureVisible.
    await tester.scrollUntilVisible(
      find.byKey(const Key('submit-created-task')),
      250,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(find.text('Task dapat diselesaikan tanpa foto.'), findsOneWidget);
    expect(
      find.text('Foto bukti wajib. Kamera akan dibuka saat report dikirim.'),
      findsNothing,
    );
    await tester.tap(find.byKey(const Key('submit-created-task')));
    await tester.pumpAndSettle();

    expect(repository.taskCreateCalls, 1);
    expect(repository.lastTaskScheduledAt, isNotNull);
    expect(
      repository.lastTaskDueAt!.isAfter(repository.lastTaskScheduledAt!),
      isTrue,
    );
    expect(find.text('Task ditambahkan'), findsOneWidget);
  });

  testWidgets('failed task mutation shows feedback and keeps sheet open', (
    tester,
  ) async {
    const task = OpsTask(
      id: 'failed-task',
      title: 'Task gagal',
      area: 'Court 1',
      time: '10:00',
      kind: TaskKind.routine,
      state: TaskState.pending,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => FilledButton(
            onPressed: () =>
                showTaskSheet(context, task, (_, __) async => false),
            child: const Text('OPEN'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('START TASK'));
    await tester.pump();

    expect(find.text('Task gagal disimpan. Coba lagi.'), findsOneWidget);
    expect(find.text('START TASK'), findsOneWidget);
  });

  testWidgets(
    'main navigation, filters, notifications, settings and sync work',
    (tester) async {
      final repository = _FakeRepository(
        home: StaffHomeData(
          userName: 'Andi Saputra',
          userRole: 'Crew Padel',
          attendanceStatus: 'ON_DUTY',
          checkInAt: DateTime(2026, 9, 2, 5, 57),
          tasks: const [
            OpsTask(
              id: 'pending-task',
              title: 'Pending API task',
              area: 'Court 1',
              time: '10:00',
              kind: TaskKind.routine,
              state: TaskState.pending,
            ),
            OpsTask(
              id: 'done-task',
              title: 'Done API task',
              area: 'Court 2',
              time: '09:00',
              kind: TaskKind.routine,
              state: TaskState.done,
            ),
          ],
          reports: [
            OpsReport(
              id: 'report-1',
              number: 'RPT-1',
              title: 'Lampu berkedip',
              category: 'DAMAGE',
              area: 'Court 3',
              status: 'OPEN',
              description: 'Lampu sisi utara berkedip.',
              priority: 'HIGH',
              detailLoaded: true,
              createdAt: DateTime(2026, 9, 2, 10),
            ),
          ],
        ),
      );
      await tester.pumpWidget(
        VamosApp(
          initialRoute: AppRoutes.staff,
          initialBinding: BindingsBuilder(() {
            Get.put<OpsRepositoryContract>(repository, permanent: true);
          }),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Task'));
      await tester.pumpAndSettle();
      expect(find.text('Task hari ini'), findsOneWidget);
      await tester.tap(find.text('Selesai'));
      await tester.pumpAndSettle();
      expect(find.text('Done API task'), findsOneWidget);
      expect(find.text('Pending API task'), findsNothing);

      await tester.tap(find.text('Report'));
      await tester.pumpAndSettle();
      expect(find.text('Lampu berkedip'), findsOneWidget);
      await tester.tap(find.text('Lampu berkedip'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('report-detail-sheet')), findsOneWidget);
      expect(find.text('Lampu sisi utara berkedip.'), findsOneWidget);
      expect(find.text('HIGH'), findsOneWidget);
      await tester.tap(find.byTooltip('Tutup'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Profil'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Pengaturan aplikasi'));
      await tester.pumpAndSettle();
      expect(find.text('Pengaturan aplikasi'), findsOneWidget);
      Navigator.of(
        tester.element(find.text('Pengaturan aplikasi')),
      ).pop<void>();
      await tester.pumpAndSettle();
      await tester.fling(
        find.byType(ListView).last,
        const Offset(0, -500),
        1000,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Semua data tersinkron'));
      await tester.pumpAndSettle();
      expect(find.text('Sinkron selesai'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));

      await tester.tap(find.text('Beranda'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.notifications_none_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Notifikasi'), findsOneWidget);
      expect(find.text('Lampu berkedip'), findsOneWidget);
    },
  );

  testWidgets('successful task mutation closes sheet and shows feedback', (
    tester,
  ) async {
    const task = OpsTask(
      id: 'success-task',
      title: 'Task berhasil',
      area: 'Court 1',
      time: '10:00',
      kind: TaskKind.routine,
      state: TaskState.pending,
    );
    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () =>
                  showTaskSheet(context, task, (_, __) async => true),
              child: const Text('OPEN'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('START TASK'));
    await tester.pumpAndSettle();

    expect(find.text('Task dimulai dan waktu Start tercatat.'), findsOneWidget);
    expect(find.text('START TASK'), findsNothing);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets(
    'successful report submission calls repository and gives feedback',
    (tester) async {
      final repository = _FakeRepository();
      final controller = StaffController(
        repository,
        cameraService: _FakeCameraService(),
      );
      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => FilledButton(
                onPressed: () => showReportSheet(context, controller),
                child: const Text('OPEN'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kerusakan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Stok / Barang').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField),
        'Lampu Court 2 tidak menyala',
      );
      await tester.tap(find.text('KIRIM REPORT'));
      await tester.pumpAndSettle();

      expect(repository.reportCalls, 1);
      expect(repository.lastReportCategory, 'STOCK');
      expect(find.text('Report terkirim'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
    },
  );

  testWidgets('handover failure keeps form open and preserves feedback', (
    tester,
  ) async {
    String? submittedNotes;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => FilledButton(
            onPressed: () => showHandoverSheet(context, 2, 3, (notes) async {
              submittedNotes = notes;
              return 'Server handover tidak tersedia.';
            }),
            child: const Text('OPEN'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Laundry menunggu vendor');
    await tester.tap(find.text('CLOCK OUT'));
    await tester.pumpAndSettle();

    expect(submittedNotes, 'Laundry menunggu vendor');
    expect(find.text('Server handover tidak tersedia.'), findsOneWidget);
    expect(find.text('CLOCK OUT'), findsOneWidget);
  });

  testWidgets('report API failure stays visible in the form', (tester) async {
    final repository = _FakeRepository()..failReport = true;
    final controller = StaffController(
      repository,
      cameraService: _FakeCameraService(),
    );
    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () => showReportSheet(context, controller),
              child: const Text('OPEN'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Report akan gagal');
    await tester.tap(find.text('KIRIM REPORT'));
    await tester.pumpAndSettle();

    expect(find.text('simulated report failure'), findsOneWidget);
    expect(find.text('KIRIM REPORT'), findsOneWidget);
  });

  testWidgets('successful handover closes form and shows feedback', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () =>
                  showHandoverSheet(context, 3, 3, (_) async => null),
              child: const Text('OPEN'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CLOCK OUT'));
    await tester.pumpAndSettle();

    expect(find.text('Clock Out berhasil'), findsOneWidget);
    expect(find.text('Lokasi, selfie, dan catatan tersimpan.'), findsOneWidget);
    expect(find.text('CLOCK OUT'), findsNothing);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('start shift API failure is visible to the user', (tester) async {
    final repository = _FakeRepository(
      home: const StaffHomeData(
        userName: 'Andi Saputra',
        userRole: 'Crew Padel',
        attendanceStatus: 'SCHEDULED',
        checkInAt: null,
        tasks: [],
        reports: [],
      ),
    )..failAttendance = true;
    await tester.pumpWidget(
      VamosApp(
        initialRoute: AppRoutes.staff,
        initialBinding: BindingsBuilder(() {
          Get.put<OpsRepositoryContract>(repository, permanent: true);
          Get.put<CameraServiceContract>(_FakeCameraService(), permanent: true);
          Get.put<LocationServiceContract>(
            const _FakeLocationService(),
            permanent: true,
          );
        }),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('CLOCK IN'));
    await tester.pumpAndSettle();

    expect(find.text('Aksi gagal'), findsOneWidget);
    expect(find.text('simulated attendance failure'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('successful start shift gives confirmation', (tester) async {
    final repository = _FakeRepository(
      home: const StaffHomeData(
        userName: 'Andi Saputra',
        userRole: 'Crew Padel',
        attendanceStatus: 'SCHEDULED',
        checkInAt: null,
        tasks: [],
        reports: [],
      ),
    );
    await tester.pumpWidget(
      VamosApp(
        initialRoute: AppRoutes.staff,
        initialBinding: BindingsBuilder(() {
          Get.put<OpsRepositoryContract>(repository, permanent: true);
          Get.put<CameraServiceContract>(_FakeCameraService(), permanent: true);
          Get.put<LocationServiceContract>(
            const _FakeLocationService(),
            permanent: true,
          );
        }),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('CLOCK IN'));
    await tester.pumpAndSettle();

    expect(find.text('Clock In berhasil'), findsOneWidget);
    expect(
      find.text('Lokasi dan selfie tersimpan di database.'),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 5));
  });
}

class _FakeRepository implements OpsRepositoryContract {
  _FakeRepository({StaffHomeData? home})
    : home =
          home ??
          const StaffHomeData(
            userName: 'Andi Saputra',
            userRole: 'Crew Padel',
            attendanceStatus: 'ON_DUTY',
            checkInAt: null,
            tasks: [],
            reports: [],
          );

  final StaffHomeData home;
  bool failAttendance = false;
  bool failReport = false;

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
  int reportCalls = 0;
  String? lastReportCategory;
  int taskCreateCalls = 0;
  DateTime? lastTaskScheduledAt;
  DateTime? lastTaskDueAt;

  @override
  Future<OpsTask> createTask({
    required String title,
    required String description,
    required String priority,
    required String evidencePolicy,
    required DateTime scheduledAt,
    required DateTime dueAt,
  }) async {
    taskCreateCalls += 1;
    lastTaskScheduledAt = scheduledAt;
    lastTaskDueAt = dueAt;
    return OpsTask(
      id: 'created-task',
      title: title,
      area: 'Venue',
      time: '10:00',
      kind: TaskKind.routine,
      state: TaskState.pending,
      scheduledAt: scheduledAt,
      dueAt: dueAt,
    );
  }

  @override
  Future<StaffHomeData> getHome() async => home;

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
    if (failReport) throw const ApiException('simulated report failure');
    reportCalls += 1;
    lastReportCategory = category;
  }

  @override
  Future<void> recordAttendance({
    required String action,
    required double latitude,
    required double longitude,
    required String selfieId,
  }) async {
    if (failAttendance) {
      throw const ApiException('simulated attendance failure');
    }
  }

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

class _FakeCameraService implements CameraServiceContract {
  @override
  Future<CapturedPhoto?> capturePhoto({bool frontCamera = false}) async =>
      const CapturedPhoto(
        path: '/tmp/vamos-test-photo.jpg',
        name: 'vamos-test-photo.jpg',
        mimeType: 'image/jpeg',
      );
}

class _FakeLocationService implements LocationServiceContract {
  const _FakeLocationService();

  @override
  Future<DevicePosition> currentPosition() async =>
      const DevicePosition(latitude: -1.262269, longitude: 116.877548);
}
