import 'package:vamos_ops_mobile/app/data/models/staff_performance.dart';
import 'package:vamos_ops_mobile/app/modules/reports/models/ops_report.dart';
import 'package:vamos_ops_mobile/app/modules/tasks/models/ops_task.dart';

class StaffHomeData {
  const StaffHomeData({
    required this.userName,
    required this.userRole,
    required this.attendanceStatus,
    required this.checkInAt,
    this.checkOutAt,
    required this.tasks,
    required this.reports,
    this.venueName = '',
    this.today,
    this.assignedCount,
    this.completedCount,
    this.performance = const StaffPerformance(),
  });

  factory StaffHomeData.fromJson(Map<String, dynamic> json) {
    final user = (json['user'] as Map?)?.cast<String, dynamic>() ?? const {};
    final attendance = (json['attendance'] as Map?)?.cast<String, dynamic>();
    return StaffHomeData(
      userName: user['name']?.toString() ?? 'Andi Saputra',
      userRole: user['role']?.toString() ?? 'Crew Padel',
      venueName: user['venue']?.toString() ?? '',
      attendanceStatus:
          attendance?['attendanceStatus']?.toString() ?? 'NOT_CHECKED_IN',
      checkInAt: DateTime.tryParse(attendance?['checkInAt']?.toString() ?? ''),
      checkOutAt: DateTime.tryParse(
        attendance?['checkOutAt']?.toString() ?? '',
      ),
      tasks: ((json['tasks'] as List?) ?? const [])
          .map(
            (item) => OpsTask.fromJson((item as Map).cast<String, dynamic>()),
          )
          .toList(),
      reports: ((json['reports'] as List?) ?? const [])
          .map(
            (item) => OpsReport.fromJson((item as Map).cast<String, dynamic>()),
          )
          .toList(),
      today: DateTime.tryParse(json['today']?.toString() ?? ''),
      assignedCount: (json['stats'] as Map?)?['assigned'] as int?,
      completedCount: (json['stats'] as Map?)?['completed'] as int?,
      performance: StaffPerformance.fromJson(
        (json['stats'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
    );
  }

  final String userName;
  final String userRole;
  final String attendanceStatus;
  final DateTime? checkInAt;
  final DateTime? checkOutAt;
  final List<OpsTask> tasks;
  final List<OpsReport> reports;
  final String venueName;
  final DateTime? today;
  final int? assignedCount, completedCount;
  final StaffPerformance performance;
}
