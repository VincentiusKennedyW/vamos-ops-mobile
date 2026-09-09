import 'package:vamos_ops_mobile/app/data/models/json_values.dart';
import 'package:vamos_ops_mobile/app/modules/reports/models/report_evidence.dart';

class OpsReport {
  const OpsReport({
    required this.id,
    required this.number,
    required this.title,
    required this.category,
    required this.area,
    required this.status,
    required this.createdAt,
    this.description = '',
    this.priority = 'NORMAL',
    this.evidenceCount = 0,
    this.evidence = const [],
    this.detailLoaded = false,
  });

  factory OpsReport.fromJson(Map<String, dynamic> json) => OpsReport(
    id: json['id'].toString(),
    number: json['number']?.toString() ?? '',
    title: json['title']?.toString() ?? '',
    category: json['category']?.toString() ?? 'INFO',
    area: json['area']?.toString() ?? 'Venue',
    status: json['status']?.toString() ?? 'OPEN',
    description: json['description']?.toString() ?? '',
    priority: json['priority']?.toString() ?? 'NORMAL',
    evidenceCount: intValue(json['evidenceCount']),
    evidence: ((json['evidence'] as List?) ?? const [])
        .map(
          (item) =>
              ReportEvidence.fromJson((item as Map).cast<String, dynamic>()),
        )
        .toList(),
    detailLoaded: json.containsKey('evidence'),
    createdAt:
        DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
        DateTime.now(),
  );

  final String id;
  final String number;
  final String title;
  final String category;
  final String area;
  final String status;
  final String description;
  final String priority;
  final int evidenceCount;
  final List<ReportEvidence> evidence;
  final bool detailLoaded;
  final DateTime createdAt;
}
