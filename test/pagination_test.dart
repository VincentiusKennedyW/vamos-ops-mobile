import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:vamos_ops_mobile/app/core/errors/api_exception.dart';
import 'package:vamos_ops_mobile/app/data/repositories/ops_repository.dart';
import 'package:vamos_ops_mobile/app/modules/staff/controllers/staff_controller.dart';
import 'package:vamos_ops_mobile/data.dart';
import 'staff_controller_test.dart' show FakeOpsRepository;

OpsTask task(String id) => OpsTask(
  id: id,
  title: id,
  area: 'Venue',
  time: '08:00',
  kind: TaskKind.routine,
  state: TaskState.pending,
);

class PagedFake extends FakeOpsRepository
    implements PagedOpsRepositoryContract, ReportDetailRepositoryContract {
  final calls = <String>[];
  final responses = <String, Completer<OpsPage<OpsTask>>>{};
  bool failReports = false;
  int taskDetailCalls = 0;
  int reportListCalls = 0;
  int reportDetailCalls = 0;
  @override
  Future<OpsPage<OpsTask>> getTasks(
    String date,
    int page,
    String status, {
    String? from,
    String? to,
    bool allDates = false,
  }) {
    final key = '$date/$page/$status';
    calls.add(key);
    return responses
        .putIfAbsent(key, () => Completer<OpsPage<OpsTask>>())
        .future;
  }

  @override
  Future<OpsTask> getTask(String id) async {
    taskDetailCalls++;
    return task(id);
  }

  @override
  Future<OpsReport> getReport(String id) async {
    reportDetailCalls++;
    return OpsReport(
      id: id,
      number: 'RPT-1',
      title: 'Report',
      category: 'INFO',
      area: 'Venue',
      status: 'OPEN',
      description: 'Detail report',
      priority: 'HIGH',
      evidenceCount: 1,
      evidence: [
        ReportEvidence(
          id: 'photo-1',
          createdAt: DateTime(2026, 9, 7),
          fileName: 'photo.jpg',
        ),
      ],
      detailLoaded: true,
      createdAt: DateTime(2026, 9, 7),
    );
  }

  @override
  Future<OpsPage<OpsReport>> getReports(int page) async {
    reportListCalls++;
    if (failReports) throw const ApiException('offline');
    return OpsPage([
      OpsReport(
        id: 'report-$page',
        title: 'Report',
        category: 'INFO',
        number: '$page',
        status: 'OPEN',
        area: 'Venue',
        createdAt: DateTime(2026, 9, 7),
      ),
    ], hasMore: page == 1);
  }
}

void main() {
  test(
    'home response seeds task and report lists without duplicate requests',
    () async {
      final repo = PagedFake();
      final controller = StaffController(repo);
      await controller.refreshHome();
      expect(controller.taskList.single.id, 'task-api');
      expect(repo.calls, isEmpty);
      expect(repo.reportListCalls, 0);
    },
  );
  test(
    'date change discards stale responses and pagination appends unique records',
    () async {
      final repo = PagedFake();
      final controller = StaffController(repo);
      final old = controller.loadTasks(date: DateTime(2026, 9, 6));
      final current = controller.loadTasks(date: DateTime(2026, 9, 7));
      repo.responses['2026-09-07/1/all']!.complete(
        OpsPage([task('a')], hasMore: true),
      );
      await current;
      repo.responses['2026-09-06/1/all']!.complete(OpsPage([task('old')]));
      await old;
      expect(controller.taskList.map((t) => t.id), ['a']);
      final more = controller.loadTasks(more: true);
      repo.responses['2026-09-07/2/all']!.complete(
        OpsPage([task('a'), task('b')]),
      );
      await more;
      expect(controller.taskList.map((t) => t.id), ['a', 'b']);
      expect(controller.tasksHasMore.value, isFalse);
      await controller.loadTasks(more: true);
      expect(repo.calls.length, 3);
    },
  );
  test('failed next report page retains records and can retry', () async {
    final repo = PagedFake();
    final controller = StaffController(repo);
    await controller.loadReports();
    repo.failReports = true;
    await controller.loadReports(more: true);
    expect(controller.reports.single.id, 'report-1');
    expect(controller.reportsError.value, 'offline');
    repo.failReports = false;
    await controller.loadReports(more: true);
    expect(controller.reports.map((r) => r.id), ['report-1', 'report-2']);
    expect(controller.reportsHasMore.value, isFalse);
  });
  test('task detail uses list data without another API request', () async {
    final repo = PagedFake();
    final controller = StaffController(repo);
    final item = task('cached-task');
    expect(await controller.taskDetail(item), same(item));
    expect(await controller.taskDetail(item), same(item));
    expect(repo.taskDetailCalls, 0);
  });
  test('report detail is requested once then served from cache', () async {
    final repo = PagedFake();
    final controller = StaffController(repo);
    final summary = OpsReport(
      id: 'report-1',
      number: 'RPT-1',
      title: 'Report',
      category: 'INFO',
      area: 'Venue',
      status: 'OPEN',
      createdAt: DateTime(2026, 9, 7),
    );
    final first = await controller.reportDetail(summary);
    final second = await controller.reportDetail(summary);
    expect(first.description, 'Detail report');
    expect(second.evidence.single.id, 'photo-1');
    expect(repo.reportDetailCalls, 1);
  });
  test('detail payloads parse stored evidence', () {
    final item = OpsTask.fromJson({
      'id': 'done',
      'title': 'Done',
      'status': 'DONE',
      'evidence': [
        {
          'id': 'photo',
          'phase': 'AFTER',
          'description': '',
          'createdAt': '2026-09-07T01:00:00Z',
        },
      ],
    });
    expect(item.state, TaskState.done);
    expect(item.evidence.single.id, 'photo');
    expect(item.evidence.single.description, '');
    expect(item.copyWith(state: TaskState.done).evidence.single.id, 'photo');
    final report = OpsReport.fromJson({
      'id': 'report',
      'number': 'RPT-1',
      'title': 'Temuan',
      'description': 'Lampu berkedip',
      'category': 'DAMAGE',
      'priority': 'HIGH',
      'status': 'OPEN',
      'area': 'Court 1',
      'createdAt': '2026-09-07T01:00:00Z',
      'evidenceCount': 1,
      'evidence': [
        {
          'id': 'report-photo',
          'fileName': 'lamp.jpg',
          'createdAt': '2026-09-07T01:05:00Z',
        },
      ],
    });
    expect(report.detailLoaded, isTrue);
    expect(report.description, 'Lampu berkedip');
    expect(report.priority, 'HIGH');
    expect(report.evidence.single.fileName, 'lamp.jpg');
  });
}
