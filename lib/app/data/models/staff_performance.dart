class StaffPerformance {
  const StaffPerformance({
    this.attendanceDays = 0,
    this.taskCompletionRate = 0,
    this.completedTasks = 0,
  });
  factory StaffPerformance.fromJson(Map<String, dynamic> json) =>
      StaffPerformance(
        attendanceDays: (json['attendanceDays'] as num?)?.toInt() ?? 0,
        taskCompletionRate: (json['taskCompletionRate'] as num?)?.toInt() ?? 0,
        completedTasks: (json['completedTasks'] as num?)?.toInt() ?? 0,
      );
  final int attendanceDays, taskCompletionRate, completedTasks;
}
