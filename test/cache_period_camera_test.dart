import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:vamos_ops_mobile/app/core/services/ops_cache.dart';
import 'package:vamos_ops_mobile/app/data/models/ops_area.dart';
import 'package:vamos_ops_mobile/app/data/models/ops_page.dart';
import 'package:vamos_ops_mobile/app/data/repositories/ops_repository_contract.dart';
import 'package:vamos_ops_mobile/app/modules/reports/models/ops_report.dart';
import 'package:vamos_ops_mobile/app/modules/staff/controllers/staff_controller.dart';
import 'package:vamos_ops_mobile/app/modules/tasks/models/ops_task.dart';

import 'support/fake_ops_repository.dart' show FakeOpsRepository;
import 'support/task_fixture.dart' show task;
import 'support/tracking_camera.dart';

class PeriodRepository extends FakeOpsRepository
    implements PagedOpsRepositoryContract, AreasRepositoryContract {
  final pending = <Completer<OpsPage<OpsTask>>>[];
  final queries = <({String? from, String? to, bool allDates})>[];
  @override
  Future<OpsPage<OpsTask>> getTasks(
    String date,
    int page,
    String status, {
    String? from,
    String? to,
    bool allDates = false,
  }) {
    queries.add((from: from, to: to, allDates: allDates));
    final completer = Completer<OpsPage<OpsTask>>();
    pending.add(completer);
    return completer.future;
  }

  @override
  Future<OpsPage<OpsReport>> getReports(int page) async => OpsPage([]);
  @override
  Future<OpsTask> getTask(String id) async => task(id);
  @override
  Future<List<OpsArea>> getAreas() async => [
    const OpsArea('area-1', 'Court 1'),
  ];
}

void main() {
  test(
    'cached query is shown immediately and refresh failure retains records',
    () async {
      final repo = PeriodRepository(), cache = OpsCache();
      final c = StaffController(repo, cache: cache);
      var future = c.loadTasks(date: DateTime(2026, 9, 7));
      repo.pending.last.complete(OpsPage([task('today')]));
      await future;
      future = c.loadTasks(scope: 'all');
      expect(repo.queries.last.allDates, true);
      repo.pending.last.complete(OpsPage([task('history')]));
      await future;
      final queryCount = repo.queries.length;
      await c.loadTasks(date: DateTime(2026, 9, 7));
      expect(c.taskList.single.id, 'today');
      expect(repo.queries.length, queryCount);
      future = c.loadTasks(date: DateTime(2026, 9, 7), refresh: true);
      repo.pending.last.completeError(Exception('offline'));
      await future;
      expect(c.taskList.single.id, 'today');
      expect(c.tasksError.value, isNotNull);
      future = c.loadTasks(
        scope: 'range',
        from: DateTime(2026, 9, 1),
        to: DateTime(2026, 9, 7),
      );
      expect(repo.queries.last, (
        from: '2026-09-01',
        to: '2026-09-07',
        allDates: false,
      ));
      repo.pending.last.complete(OpsPage([]));
      await future;
    },
  );
  test(
    'session cache clearing prevents in-flight data from returning',
    () async {
      final repo = PeriodRepository(), cache = OpsCache();
      final c = StaffController(repo, cache: cache);
      final future = c.loadTasks(scope: 'all');
      cache.clear();
      repo.pending.last.complete(OpsPage([task('old-account')]));
      await future;
      expect(c.taskList, isEmpty);
      cache.write('value', 'private');
      cache.clear();
      expect(cache.read<String>('value'), isNull);
    },
  );
  test('cache is bounded and controller closure discards late data', () async {
    final cache = OpsCache();
    for (var i = 0; i < 25; i++) {
      cache.write('$i', i);
    }
    expect(cache.read<int>('0'), isNull);
    expect(cache.read<int>('24'), 24);
    final repo = PeriodRepository(), c = StaffController(PeriodRepository());
    c.onDelete();
    final other = StaffController(repo);
    final future = other.loadTasks();
    other.onDelete();
    repo.pending.last.complete(OpsPage([task('late')]));
    await future;
    expect(other.taskList, isEmpty);
  });
  test(
    'attendance requests front camera while task and report use rear',
    () async {
      final camera = TrackingCamera();
      final c = StaffController(FakeOpsRepository(), cameraService: camera);
      await c.clockIn();
      await c.clockOut();
      await c.captureTaskEvidence('task', description: '');
      await c.createReport(
        title: 'Temuan',
        description: 'Temuan baru',
        category: 'INFO',
        areaId: 'area-1',
      );
      expect(camera.frontRequests, [true, true, false, false]);
    },
  );
  test('master areas are available and cached for report form', () async {
    final cache = OpsCache();
    final c = StaffController(PeriodRepository(), cache: cache);
    await c.loadAreas();
    expect(c.areas.single.name, 'Court 1');
    expect(c.areasError.value, isNull);
    expect(cache.read<List<OpsArea>>('areas')!.single.id, 'area-1');
    cache.clear();
  });
}
