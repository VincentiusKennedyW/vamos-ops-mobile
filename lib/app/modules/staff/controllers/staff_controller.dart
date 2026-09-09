import 'package:get/get.dart';
import 'package:vamos_ops_mobile/app/core/errors/api_exception.dart';
import 'package:vamos_ops_mobile/app/core/services/device_services.dart';
import 'package:vamos_ops_mobile/app/core/services/ops_cache.dart';
import 'package:vamos_ops_mobile/app/core/utils/operational_date.dart';
import 'package:vamos_ops_mobile/app/data/models/ops_area.dart';
import 'package:vamos_ops_mobile/app/data/models/staff_performance.dart';
import 'package:vamos_ops_mobile/app/data/repositories/ops_repository_contract.dart';
import 'package:vamos_ops_mobile/app/modules/reports/controllers/report_list_controller.dart';
import 'package:vamos_ops_mobile/app/modules/reports/models/ops_report.dart';
import 'package:vamos_ops_mobile/app/modules/tasks/controllers/task_list_controller.dart';
import 'package:vamos_ops_mobile/app/modules/tasks/models/ops_task.dart';
import 'package:vamos_ops_mobile/app/modules/tasks/models/task_evidence.dart';

class StaffController extends GetxController {
  StaffController(
    this._repository, {
    LocationServiceContract? locationService,
    CameraServiceContract? cameraService,
    OpsCache? cache,
  }) : _locationService =
           locationService ?? const VenueFallbackLocationService(),
       _cameraService = cameraService,
       _cache = cache ?? OpsCache();

  final OpsCache _cache;
  final OpsRepositoryContract _repository;
  final LocationServiceContract _locationService;
  final CameraServiceContract? _cameraService;

  final selectedTab = 0.obs;
  final isLoading = true.obs;
  final hasLoaded = false.obs;
  final isMutating = false.obs;
  final isOnline = false.obs;
  final errorMessage = RxnString();
  final userName = ''.obs;
  final userRole = ''.obs;
  final venueName = ''.obs;
  final attendanceStatus = 'NOT_CHECKED_IN'.obs;
  final checkInAt = Rxn<DateTime>();
  final checkOutAt = Rxn<DateTime>();
  final tasks = <OpsTask>[].obs;

  final today = DateTime.now().obs;

  final areas = <OpsArea>[].obs;
  final areasLoading = false.obs;
  final areasError = RxnString();

  final assignedCount = 0.obs, completedToday = 0.obs;

  // These collaborators own query state. The staff coordinator owns cross-feature
  // mutations and home aggregates so optimistic updates have one source of truth.
  late final taskQueries = TaskListController(_repository, _cache, tasks);
  late final reportQueries = ReportListController(_repository, _cache);

  RxList<OpsTask> get taskList => taskQueries.taskList;
  Rx<DateTime> get taskDate => taskQueries.taskDate;
  RxString get taskScope => taskQueries.taskScope;
  Rxn<DateTime> get taskFrom => taskQueries.taskFrom;
  Rxn<DateTime> get taskTo => taskQueries.taskTo;
  RxBool get tasksLoading => taskQueries.tasksLoading;
  RxBool get tasksHasMore => taskQueries.tasksHasMore;
  RxnString get tasksError => taskQueries.tasksError;
  RxList<OpsReport> get reports => reportQueries.reports;
  RxBool get reportsLoading => reportQueries.reportsLoading;
  RxBool get reportsHasMore => reportQueries.reportsHasMore;
  RxnString get reportsError => reportQueries.reportsError;

  Future<void> loadTasks({
    DateTime? date,
    String? scope,
    DateTime? from,
    DateTime? to,
    bool more = false,
    bool refresh = false,
  }) => taskQueries.loadTasks(
    date: date,
    scope: scope,
    from: from,
    to: to,
    more: more,
    refresh: refresh,
  );
  Future<void> loadReports({bool more = false, bool refresh = false}) =>
      reportQueries.loadReports(more: more, refresh: refresh);
  Future<OpsReport> reportDetail(OpsReport report, {bool refresh = false}) =>
      reportQueries.reportDetail(report, refresh: refresh);

  Future<void> loadAreas() async {
    if (areasLoading.value) return;
    final epoch = _cache.epoch;
    areasLoading.value = true;
    areasError.value = null;
    areas.assignAll(_cache.read<List<OpsArea>>('areas') ?? areas.toList());
    try {
      final repo = _repository;
      if (repo is! AreasRepositoryContract) {
        throw const ApiException('Data area tidak tersedia.');
      }
      final result = await (repo as AreasRepositoryContract).getAreas();
      if (isClosed || epoch != _cache.epoch) return;
      areas.assignAll(result);
      _cache.write('areas', result);
    } catch (error) {
      if (!isClosed) {
        areasError.value = error is ApiException
            ? error.message
            : 'Area gagal dimuat. Coba lagi.';
      }
    } finally {
      if (!isClosed) areasLoading.value = false;
    }
  }

  @override
  void onClose() {
    taskQueries.dispose();
    reportQueries.dispose();
    super.onClose();
  }

  Future<OpsTask> taskDetail(OpsTask task) async => task;

  final performance = const StaffPerformance().obs;

  int get completedCount => completedToday.value;
  bool get onDuty => ['ON_DUTY'].contains(attendanceStatus.value);
  bool get canWorkTasks => onDuty && checkOutAt.value == null;

  void _replaceTask(String id, OpsTask replacement) {
    final homeIndex = tasks.indexWhere((item) => item.id == id);
    if (homeIndex >= 0) tasks[homeIndex] = replacement;
    final listIndex = taskList.indexWhere((item) => item.id == id);
    if (listIndex >= 0) taskList[listIndex] = replacement;
    taskQueries.persist();
  }

  @override
  void onReady() {
    super.onReady();
    refreshHome();
  }

  Future<void> refreshHome() async {
    isLoading.value = !hasLoaded.value;
    errorMessage.value = null;
    try {
      final home = await _repository.getHome();
      if (isClosed) return;
      userName.value = home.userName;
      userRole.value = home.userRole;
      venueName.value = home.venueName;
      attendanceStatus.value = home.attendanceStatus;
      checkInAt.value = home.checkInAt;
      checkOutAt.value = home.checkOutAt;
      tasks.assignAll(home.tasks);
      today.value = home.today ?? DateTime.now();
      taskQueries.seedHome(home.tasks, today.value);
      reportQueries.seedHome(home.reports);
      assignedCount.value = home.assignedCount ?? home.tasks.length;
      completedToday.value =
          home.completedCount ??
          home.tasks.where((t) => t.state == TaskState.done).length;
      performance.value = home.performance;
      isOnline.value = true;
    } on ApiException catch (error) {
      errorMessage.value = error.message;
      isOnline.value = false;
    } catch (_) {
      errorMessage.value = 'Tidak dapat terhubung ke VAMOS API.';
      isOnline.value = false;
    } finally {
      isLoading.value = false;
      hasLoaded.value = true;
    }
  }

  Future<bool> setTaskState(OpsTask task, TaskState state) async {
    if (isMutating.value) return false;
    if ((state == TaskState.inProgress || state == TaskState.done) &&
        !canWorkTasks) {
      errorMessage.value = checkOutAt.value != null
          ? 'Clock Out sudah tercatat. Task tidak dapat dikerjakan lagi hari ini.'
          : 'Lakukan Clock In sebelum memulai task.';
      return false;
    }

    final previousHome = tasks.toList();
    final previousList = taskList.toList();
    final previousCompleted = completedToday.value;
    final affectsToday = previousHome.any((item) => item.id == task.id);
    final now = DateTime.now();
    final optimistic = task.copyWith(
      state: state,
      startedAt: state == TaskState.inProgress ? task.startedAt ?? now : null,
      completedAt: state == TaskState.done ? task.completedAt ?? now : null,
      startedBy: state == TaskState.inProgress
          ? task.startedBy ?? userName.value
          : null,
    );
    _replaceTask(task.id, optimistic);
    if (affectsToday &&
        task.state != TaskState.done &&
        state == TaskState.done) {
      completedToday.value++;
    } else if (affectsToday &&
        task.state == TaskState.done &&
        state != TaskState.done) {
      completedToday.value--;
    }

    isMutating.value = true;
    errorMessage.value = null;
    try {
      final confirmed = await _repository.updateTask(task.id, state);
      _replaceTask(task.id, confirmed);
      isOnline.value = true;
      return true;
    } catch (error) {
      tasks.assignAll(previousHome);
      taskList.assignAll(previousList);
      completedToday.value = previousCompleted;
      taskQueries.persist();
      _showError(error);
      return false;
    } finally {
      isMutating.value = false;
    }
  }

  Future<bool> createTask({
    required String title,
    required String description,
    String priority = 'NORMAL',
    String evidencePolicy = 'none',
    required DateTime scheduledAt,
    required DateTime dueAt,
  }) async {
    if (isMutating.value) return false;
    final previousHome = tasks.toList();
    final previousList = taskList.toList();
    final previousAssigned = assignedCount.value;
    final optimisticId = 'optimistic-${DateTime.now().microsecondsSinceEpoch}';
    final optimistic = OpsTask.fromJson({
      'id': optimisticId,
      'title': title,
      'description': description,
      'kind': 'ROUTINE',
      'status': 'PENDING',
      'area': 'Venue',
      'evidencePolicy': evidencePolicy,
      'scheduledAt': scheduledAt.toIso8601String(),
      'dueAt': dueAt.toIso8601String(),
    });
    if (sameOperationalDate(scheduledAt, today.value)) {
      tasks.insert(0, optimistic);
      assignedCount.value++;
    }
    if (taskQueries.containsDate(scheduledAt)) {
      taskList.insert(0, optimistic);
      taskQueries.persist();
    }

    isMutating.value = true;
    errorMessage.value = null;
    try {
      final confirmed = await _repository.createTask(
        title: title,
        description: description,
        priority: priority,
        evidencePolicy: evidencePolicy,
        scheduledAt: scheduledAt,
        dueAt: dueAt,
      );
      _replaceTask(optimisticId, confirmed);
      isOnline.value = true;
      return true;
    } catch (error) {
      tasks.assignAll(previousHome);
      taskList.assignAll(previousList);
      assignedCount.value = previousAssigned;
      taskQueries.persist();
      _showError(error);
      return false;
    } finally {
      isMutating.value = false;
    }
  }

  Future<bool> createReport({
    required String title,
    required String description,
    required String category,
    String priority = 'NORMAL',
    String? areaId,
    String? sourceTaskId,
  }) async {
    if (isMutating.value) return false;
    isMutating.value = true;
    errorMessage.value = null;
    try {
      if (_cameraService == null) {
        throw const ApiException('Kamera wajib tersedia untuk bukti report.');
      }
      final photo = await _cameraService.capturePhoto();
      if (photo == null) throw const ApiException('Foto report wajib diambil.');
      final evidenceId = await _repository.uploadPurposePhoto('REPORT', photo);
      await _repository.createReport(
        title: title,
        description: description,
        category: category,
        priority: priority,
        areaId: areaId,
        sourceTaskId: sourceTaskId,
        evidenceId: evidenceId,
      );
      await refreshHome();
      return true;
    } catch (error) {
      _showError(error);
      return false;
    } finally {
      isMutating.value = false;
    }
  }

  Future<bool> clockIn() async {
    if (isMutating.value) return false;
    isMutating.value = true;
    errorMessage.value = null;
    try {
      if (_cameraService == null) {
        throw const ApiException('Kamera wajib tersedia untuk Clock In.');
      }
      final selfie = await _cameraService.capturePhoto(frontCamera: true);
      if (selfie == null) {
        throw const ApiException('Selfie Clock In wajib diambil.');
      }
      final selfieId = await _repository.uploadPurposePhoto(
        'ATTENDANCE_CHECK_IN',
        selfie,
      );
      final position = await _locationService.currentPosition();
      await _repository.recordAttendance(
        action: 'CHECK_IN',
        latitude: position.latitude,
        longitude: position.longitude,
        selfieId: selfieId,
      );
      await refreshHome();
      return true;
    } catch (error) {
      _showError(error);
      return false;
    } finally {
      isMutating.value = false;
    }
  }

  Future<bool> clockOut({String notes = ''}) async {
    if (isMutating.value) return false;
    isMutating.value = true;
    errorMessage.value = null;
    final outstanding = tasks
        .where((task) => task.state != TaskState.done)
        .map((task) => task.id)
        .toList();
    try {
      final position = await _locationService.currentPosition();
      if (_cameraService == null) {
        throw const ApiException('Kamera wajib tersedia untuk Clock Out.');
      }
      final selfie = await _cameraService.capturePhoto(frontCamera: true);
      if (selfie == null) {
        throw const ApiException('Selfie Clock Out wajib diambil.');
      }
      final selfieId = await _repository.uploadPurposePhoto(
        'ATTENDANCE_CHECK_OUT',
        selfie,
      );
      await _repository.submitHandover(
        completedCount: completedCount,
        totalCount: assignedCount.value,
        outstandingTaskIds: outstanding,
        notes: notes,
      );
      await _repository.recordAttendance(
        action: 'CHECK_OUT',
        latitude: position.latitude,
        longitude: position.longitude,
        selfieId: selfieId,
      );
      await refreshHome();
      return true;
    } catch (error) {
      _showError(error);
      return false;
    } finally {
      isMutating.value = false;
    }
  }

  Future<String?> captureTaskEvidence(
    String taskId, {
    String phase = 'AFTER',
    required String description,
  }) async {
    if (_cameraService == null || isMutating.value) return null;
    isMutating.value = true;
    errorMessage.value = null;
    try {
      final photo = await _cameraService.capturePhoto();
      if (photo == null) return null;
      final evidenceId = await _repository.uploadTaskEvidence(
        taskId,
        photo,
        phase: phase,
        description: description,
      );
      final current =
          tasks.firstWhereOrNull((task) => task.id == taskId) ??
          taskList.firstWhereOrNull((task) => task.id == taskId);
      if (current != null) {
        final evidence = TaskEvidence(
          id: evidenceId,
          phase: phase,
          description: description,
          createdAt: DateTime.now(),
        );
        _replaceTask(
          taskId,
          current.copyWith(
            evidenceCount: current.evidenceCount + 1,
            beforeEvidenceCount:
                current.beforeEvidenceCount + (phase == 'BEFORE' ? 1 : 0),
            afterEvidenceCount:
                current.afterEvidenceCount + (phase == 'AFTER' ? 1 : 0),
            evidence: [...current.evidence, evidence],
          ),
        );
      }
      isOnline.value = true;
      return photo.path;
    } catch (error) {
      _showError(error);
      return null;
    } finally {
      isMutating.value = false;
    }
  }

  void _showError(Object error) {
    final message = error is ApiException
        ? error.message
        : 'Operasi gagal. Silakan coba lagi.';
    errorMessage.value = message;
  }
}
