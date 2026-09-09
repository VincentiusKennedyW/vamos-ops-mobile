class ReportEvidence {
  const ReportEvidence({
    required this.id,
    required this.createdAt,
    this.fileName = '',
  });

  factory ReportEvidence.fromJson(Map<String, dynamic> json) => ReportEvidence(
    id: json['id'].toString(),
    createdAt:
        DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
        DateTime.now(),
    fileName: json['fileName']?.toString() ?? '',
  );

  final String id;
  final DateTime createdAt;
  final String fileName;
}
