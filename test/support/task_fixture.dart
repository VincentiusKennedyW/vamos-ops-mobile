import 'package:vamos_ops_mobile/app/modules/tasks/models/ops_task.dart';

OpsTask task(String id) => OpsTask(
  id: id,
  title: id,
  area: 'Venue',
  time: '08:00',
  kind: TaskKind.routine,
  state: TaskState.pending,
);
