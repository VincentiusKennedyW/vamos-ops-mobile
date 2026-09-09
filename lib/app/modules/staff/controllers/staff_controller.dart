import 'package:get/get.dart';
import '../../../core/services/ops_cache.dart';

import '../../../core/errors/api_exception.dart';
import '../../../core/services/device_services.dart';
import '../../../data/repositories/ops_repository.dart';
import '../../../../data.dart';

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
  final reports = <OpsReport>[].obs;
  final taskList = <OpsTask>[].obs;
  final taskDate = DateTime.now().obs;
  final today = DateTime.now().obs;
  final taskScope = 'day'.obs;
  final taskFrom = Rxn<DateTime>(), taskTo = Rxn<DateTime>();
  final areas = <OpsArea>[].obs;
  final areasLoading = false.obs;
  final areasError = RxnString();
  String _activeTaskKey = '';
  final tasksLoading = false.obs, reportsLoading = false.obs;
  final tasksHasMore = false.obs, reportsHasMore = false.obs;
  final tasksError = RxnString(), reportsError = RxnString();
  final assignedCount = 0.obs, completedToday = 0.obs;
  int _taskPage = 1,
      _reportPage = 1,
      _taskGeneration = 0,
      _reportGeneration = 0;
  bool _dateInitialized = false;

  Future<void> loadTasks({
    DateTime? date,
    String? scope,
    DateTime? from,
    DateTime? to,
    bool more = false,
    bool refresh = false,
  }) async {
    if (more && (tasksLoading.value || !tasksHasMore.value)) return;
    if (date != null) {
      taskDate.value = date;
      taskScope.value = 'day';
    }
    if (scope != null) taskScope.value = scope;
    if (from != null) taskFrom.value = from;
    if (to != null) taskTo.value = to;
    final epoch = _cache.epoch;
    final dateValue = taskDate.value.toIso8601String().substring(0, 10);
    final fromValue = taskFrom.value?.toIso8601String().substring(0, 10);
    final toValue = taskTo.value?.toIso8601String().substring(0, 10);
    final key = switch (taskScope.value) {
      'all' => 'tasks/all',
      'range' => 'tasks/range/$fromValue/$toValue',
      _ => 'tasks/day/$dateValue',
    };
    if (!more) {
      final cached = _cache.read<CachedList<OpsTask>>(key);
      if (key != _activeTaskKey) {
        taskList.assignAll(cached?.items ?? []);
        _taskPage = cached?.page ?? 1;
        tasksHasMore.value = cached?.hasMore ?? false;
      }
      _activeTaskKey = key;
      if (!refresh && cached != null) {
        tasksError.value = null;
        tasksLoading.value = false;
        return;
      }
      _taskPage = 1;
    }
    final generation = ++_taskGeneration;
    final page = more ? _taskPage + 1 : 1;
    tasksLoading.value = true;
    tasksError.value = null;
    try {
      final repo = _repository;
      if (repo is! PagedOpsRepositoryContract) {
        taskList.assignAll(tasks);
        return;
      }
      final from = taskScope.value == 'range' ? fromValue : null;
      final to = taskScope.value == 'range' ? toValue : null;
      final allDates = taskScope.value == 'all';
      final pages = await Future.wait([
        for (var p = more ? page : 1; p <= page; p++)
          (repo as PagedOpsRepositoryContract).getTasks(
            dateValue,
            p,
            'all',
            from: from,
            to: to,
            allDates: allDates,
          ),
      ]);
      final result = OpsPage(
        pages.expand((p) => p.items).toList(),
        hasMore: pages.last.hasMore,
      );
      if (generation != _taskGeneration || isClosed || epoch != _cache.epoch) {
        return;
      }
      if (more) {
        final ids = taskList.map((t) => t.id).toSet();
        taskList.addAll(result.items.where((t) => !ids.contains(t.id)));
      } else {
        taskList.assignAll(result.items);
      }
      _taskPage = page;
      tasksHasMore.value = result.hasMore;
      if (page <= 10) {
        _cache.write(key, CachedList(taskList, page, result.hasMore));
      }
    } catch (error) {
      if (generation == _taskGeneration) {
        tasksError.value = error is ApiException
            ? error.message
            : 'Task gagal dimuat. Coba lagi.';
      }
    } finally {
      if (generation == _taskGeneration) tasksLoading.value = false;
    }
  }

  Future<void> loadReports({bool more = false, bool refresh = false}) async {
    if (more && (reportsLoading.value || !reportsHasMore.value)) return;
    final epoch = _cache.epoch;
    if (!more) {
      final cached = _cache.read<CachedList<OpsReport>>('reports');
      if (cached != null) {
        reports.assignAll(cached.items);
        _reportPage = cached.page;
        reportsHasMore.value = cached.hasMore;
        if (!refresh) {
          reportsError.value = null;
          reportsLoading.value = false;
          return;
        }
      }
      _reportPage = 1;
    }
    final generation = ++_reportGeneration;
    final page = more ? _reportPage + 1 : 1;
    reportsLoading.value = true;
    reportsError.value = null;
    try {
      final repo = _repository;
      if (repo is! PagedOpsRepositoryContract) return;
      final pages = await Future.wait([
        for (var p = more ? page : 1; p <= page; p++)
          (repo as PagedOpsRepositoryContract).getReports(p),
      ]);
      final result = OpsPage(
        pages.expand((p) => p.items).toList(),
        hasMore: pages.last.hasMore,
      );
      if (generation != _reportGeneration ||
          isClosed ||
          epoch != _cache.epoch) {
        return;
      }
      if (more) {
        final ids = reports.map((r) => r.id).toSet();
        reports.addAll(result.items.where((r) => !ids.contains(r.id)));
      } else {
        reports.assignAll(result.items);
      }
      _reportPage = page;
      reportsHasMore.value = result.hasMore;
      if (page <= 10) {
        _cache.write('reports', CachedList(reports, page, result.hasMore));
      }
    } catch (error) {
      if (generation == _reportGeneration) {
        reportsError.value = error is ApiException
            ? error.message
            : 'Report gagal dimuat. Coba lagi.';
      }
    } finally {
      if (generation == _reportGeneration) reportsLoading.value = false;
    }
  }

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
    _taskGeneration++;
    _reportGeneration++;
    super.onClose();
  }

  Future<OpsTask> taskDetail(OpsTask task) async => task;

  Future<OpsReport> reportDetail(
    OpsReport report, {
    bool refresh = false,
  }) async {
    final key = 'report/${report.id}';
    final cached = _cache.read<OpsReport>(key);
    if (!refresh && cached != null) return cached;
    if (!refresh && report.detailLoaded) {
      _cache.write(key, report);
      return report;
    }
    final repo = _repository;
    if (repo is! ReportDetailRepositoryContract) return report;
    final detail = await (repo as ReportDetailRepositoryContract).getReport(
      report.id,
    );
    if (!isClosed) _cache.write(key, detail);
    return detail;
  }

  final performance = const StaffPerformance().obs;

  int get completedCount => completedToday.value;
  bool get onDuty => ['ON_DUTY'].contains(attendanceStatus.value);
  bool get canWorkTasks => onDuty && checkOutAt.value == null;

  void _replaceTask(String id, OpsTask replacement) {
    final homeIndex = tasks.indexWhere((item) => item.id == id);
    if (homeIndex >= 0) tasks[homeIndex] = replacement;
    final listIndex = taskList.indexWhere((item) => item.id == id);
    if (listIndex >= 0) taskList[listIndex] = replacement;
    _persistActiveTaskList();
  }

  void _persistActiveTaskList() {
    if (_activeTaskKey.isEmpty || _taskPage > 10) return;
    _cache.write(
      _activeTaskKey,
      CachedList(taskList.toList(), _taskPage, tasksHasMore.value),
    );
  }

  bool _sameDate(DateTime left, DateTime right) =>
      left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;

  bool _visibleInActiveTaskQuery(DateTime scheduledAt) {
    if (taskScope.value == 'all') return true;
    if (taskScope.value == 'range') {
      final from = taskFrom.value, to = taskTo.value;
      if (from == null || to == null) return false;
      final date = DateTime(
        scheduledAt.year,
        scheduledAt.month,
        scheduledAt.day,
      );
      final start = DateTime(from.year, from.month, from.day);
      final end = DateTime(to.year, to.month, to.day);
      return !date.isBefore(start) && !date.isAfter(end);
    }
    return _sameDate(scheduledAt, taskDate.value);
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
      final todayKey =
          'tasks/day/${today.value.toIso8601String().substring(0, 10)}';
      final homeTasks = CachedList(home.tasks, 1, home.tasks.length >= 20);
      _cache.write(todayKey, homeTasks);
      if (!_dateInitialized) {
        taskDate.value = today.value;
        _dateInitialized = true;
        taskScope.value = 'day';
        _activeTaskKey = todayKey;
        taskList.assignAll(home.tasks);
        _taskPage = 1;
        tasksHasMore.value = homeTasks.hasMore;
      } else if (_activeTaskKey == todayKey) {
        taskList.assignAll(home.tasks);
        _taskPage = 1;
        tasksHasMore.value = homeTasks.hasMore;
      }
      reports.assignAll(home.reports);
      _reportPage = 1;
      reportsHasMore.value = home.reports.length >= 20;
      _cache.write(
        'reports',
        CachedList(home.reports, 1, reportsHasMore.value),
      );
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
      _persistActiveTaskList();
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
    if (_sameDate(scheduledAt, today.value)) {
      tasks.insert(0, optimistic);
      assignedCount.value++;
    }
    if (_visibleInActiveTaskQuery(scheduledAt)) {
      taskList.insert(0, optimistic);
      _persistActiveTaskList();
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
      _persistActiveTaskList();
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
