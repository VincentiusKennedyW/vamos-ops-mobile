import 'package:get/get.dart';
import 'package:vamos_ops_mobile/app/core/errors/api_exception.dart';
import 'package:vamos_ops_mobile/app/core/services/ops_cache.dart';
import 'package:vamos_ops_mobile/app/core/utils/operational_date.dart';
import 'package:vamos_ops_mobile/app/data/models/ops_page.dart';
import 'package:vamos_ops_mobile/app/data/repositories/ops_repository_contract.dart';
import 'package:vamos_ops_mobile/app/modules/tasks/models/ops_task.dart';

/// Owns task period, pagination and session-cache state. Disposed by StaffController.
class TaskListController {
  TaskListController(this._repository, this._cache, this.tasks);
  final OpsRepositoryContract _repository;
  final OpsCache _cache;
  final List<OpsTask> tasks;
  final taskList = <OpsTask>[].obs;
  final taskDate = DateTime.now().obs;
  final taskScope = 'day'.obs;
  final taskFrom = Rxn<DateTime>(), taskTo = Rxn<DateTime>();
  final tasksLoading = false.obs, tasksHasMore = false.obs;
  final tasksError = RxnString();
  String _activeTaskKey = '';
  int _taskPage = 1, _taskGeneration = 0;
  bool _dateInitialized = false;
  bool _closed = false;
  bool get isClosed => _closed;
  void dispose() {
    _closed = true;
    _taskGeneration++;
  }

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

  void persist() {
    if (_activeTaskKey.isEmpty || _taskPage > 10) return;
    _cache.write(
      _activeTaskKey,
      CachedList(taskList.toList(), _taskPage, tasksHasMore.value),
    );
  }

  bool containsDate(DateTime scheduledAt) {
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
    return sameOperationalDate(scheduledAt, taskDate.value);
  }

  void seedHome(List<OpsTask> items, DateTime today) {
    final todayKey = 'tasks/day/${today.toIso8601String().substring(0, 10)}';
    final homeTasks = CachedList(items, 1, items.length >= 20);
    _cache.write(todayKey, homeTasks);
    if (!_dateInitialized) {
      taskDate.value = today;
      _dateInitialized = true;
      taskScope.value = 'day';
      _activeTaskKey = todayKey;
      taskList.assignAll(items);
      _taskPage = 1;
      tasksHasMore.value = homeTasks.hasMore;
    } else if (_activeTaskKey == todayKey) {
      taskList.assignAll(items);
      _taskPage = 1;
      tasksHasMore.value = homeTasks.hasMore;
    }
  }
}
