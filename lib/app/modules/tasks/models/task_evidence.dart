class TaskEvidence {
  const TaskEvidence({
    required this.id,
    required this.phase,
    required this.description,
    required this.createdAt,
  });
  final String id, phase, description;
  final DateTime createdAt;
  factory TaskEvidence.fromJson(Map<String, dynamic> json) => TaskEvidence(
    id: json['id'].toString(),
    phase: json['phase'].toString(),
    description: json['description']?.toString() ?? '',
    createdAt: DateTime.parse(json['createdAt'].toString()),
  );
}
