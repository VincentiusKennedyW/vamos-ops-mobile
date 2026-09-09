import 'package:get/get.dart';
import 'package:vamos_ops_mobile/app/core/errors/api_exception.dart';
import 'package:vamos_ops_mobile/app/core/services/ops_cache.dart';
import 'package:vamos_ops_mobile/app/data/models/ops_page.dart';
import 'package:vamos_ops_mobile/app/data/repositories/ops_repository_contract.dart';
import 'package:vamos_ops_mobile/app/modules/reports/models/ops_report.dart';

/// Owns report pagination/detail cache; shares the session cache with staff home.
class ReportListController {
  ReportListController(this._repository, this._cache);
  final OpsRepositoryContract _repository;
  final OpsCache _cache;
  final reports = <OpsReport>[].obs;
  final reportsLoading = false.obs, reportsHasMore = false.obs;
  final reportsError = RxnString();
  int _reportPage = 1, _reportGeneration = 0;
  bool _closed = false;
  bool get isClosed => _closed;
  void dispose() {
    _closed = true;
    _reportGeneration++;
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

  void seedHome(List<OpsReport> items) {
    reports.assignAll(items);
    _reportPage = 1;
    reportsHasMore.value = items.length >= 20;
    _cache.write('reports', CachedList(items, 1, reportsHasMore.value));
  }
}
