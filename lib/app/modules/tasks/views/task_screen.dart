import 'package:flutter/material.dart';
import 'package:vamos_ops_mobile/app/core/theme/app_tokens.dart';
import 'package:vamos_ops_mobile/app/modules/tasks/models/ops_task.dart';
import 'package:vamos_ops_mobile/app/modules/tasks/widgets/task_tile.dart';
import 'package:vamos_ops_mobile/app/widgets/page_footer.dart';
import 'package:vamos_ops_mobile/app/widgets/screen_header.dart';

class TaskScreen extends StatefulWidget {
  const TaskScreen({
    super.key,
    required this.tasks,
    required this.onTask,
    required this.onCreate,
    this.date,
    this.today,
    this.loading = false,
    this.hasMore = false,
    this.error,
    this.onDate,
    this.scope = 'day',
    this.rangeFrom,
    this.rangeTo,
    this.onRange,
    this.onAllDates,
    this.onRefresh,
    this.onMore,
  });
  final List<OpsTask> tasks;
  final ValueChanged<OpsTask> onTask;
  final VoidCallback onCreate;
  final DateTime? date, today, rangeFrom, rangeTo;
  final String scope;
  final ValueChanged<DateTimeRange>? onRange;
  final VoidCallback? onAllDates;
  final bool loading, hasMore;
  final String? error;
  final ValueChanged<DateTime>? onDate;
  final Future<void> Function()? onRefresh, onMore;
  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  String filter = 'all';
  @override
  Widget build(BuildContext context) {
    final date = widget.date ?? DateTime.now();
    final today = widget.today ?? DateTime.now();
    final shown = widget.tasks
        .where(
          (t) =>
              filter == 'all' ||
              (filter == 'done'
                  ? t.state == TaskState.done
                  : t.state != TaskState.done),
        )
        .toList();
    return Column(
      children: [
        ScreenHeader(
          title: widget.scope == 'all'
              ? 'Semua task'
              : widget.scope == 'range'
              ? 'Task rentang waktu'
              : DateUtils.isSameDay(date, today)
              ? 'Task hari ini'
              : 'Riwayat task',
          subtitle: 'Task pribadi dan assignment crew',
          action: IconButton.filled(
            key: const Key('create-task-button'),
            tooltip: 'Tambah task',
            onPressed: widget.onCreate,
            icon: const Icon(Icons.add_rounded),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('task-date-picker'),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: date,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(today.year + 5, 12, 31),
                    );
                    if (picked != null) widget.onDate?.call(picked);
                  },
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: Text(
                    MaterialLocalizations.of(context).formatMediumDate(date),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => widget.onDate?.call(today),
                child: const Text('Hari ini'),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Semua waktu'),
                selected: widget.scope == 'all',
                onSelected: (_) => widget.onAllDates?.call(),
              ),
              ChoiceChip(
                label: const Text('Rentang tanggal'),
                selected: widget.scope == 'range',
                onSelected: (_) async {
                  final range = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(today.year + 5, 12, 31),
                    initialDateRange:
                        widget.rangeFrom != null && widget.rangeTo != null
                        ? DateTimeRange(
                            start: widget.rangeFrom!,
                            end: widget.rangeTo!,
                          )
                        : null,
                  );
                  if (range != null) widget.onRange?.call(range);
                },
              ),
            ],
          ),
        ),
        if (widget.scope == 'range' &&
            widget.rangeFrom != null &&
            widget.rangeTo != null)
          Text(
            '${MaterialLocalizations.of(context).formatMediumDate(widget.rangeFrom!)} – ${MaterialLocalizations.of(context).formatMediumDate(widget.rangeTo!)}',
            style: const TextStyle(color: AppColors.onSurfaceMuted),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Wrap(
            spacing: 8,
            children: {'all': 'Semua', 'pending': 'Pending', 'done': 'Selesai'}
                .entries
                .map(
                  (item) => ChoiceChip(
                    label: Text(item.value),
                    selected: filter == item.key,
                    onSelected: (_) {
                      setState(() => filter = item.key);
                    },
                  ),
                )
                .toList(),
          ),
        ),
        if (widget.loading && shown.isEmpty) const LinearProgressIndicator(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: widget.onRefresh ?? () async {},
            child: ListView.builder(
              key: ValueKey(
                'tasks-${widget.scope}-${widget.rangeFrom}-${widget.rangeTo}-${date.toIso8601String()}-$filter',
              ),
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 90),
              itemCount: shown.length + 1,
              itemBuilder: (context, index) {
                if (index == shown.length) {
                  return PageFooter(
                    loading: widget.loading,
                    hasMore: widget.hasMore,
                    error: widget.error,
                    empty: shown.isEmpty,
                    emptyText: 'Belum ada task pada tanggal dan filter ini.',
                    onMore: widget.onMore,
                    onRetry: () => widget.onRefresh?.call(),
                  );
                }
                final task = shown[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TaskTile(
                    task: task,
                    showDate: widget.scope != 'day',
                    onTap: () => widget.onTask(task),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
