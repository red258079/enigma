class TaskModel {
  final String id;
  final String title;
  final String? description;
  final String phase; // preparation, adaptation, sustain
  final String pillar; // sleep, physical, mental, social, career
  bool isCompleted;
  final int orderIndex;

  TaskModel({
    required this.id,
    required this.title,
    this.description,
    required this.phase,
    required this.pillar,
    this.isCompleted = false,
    this.orderIndex = 0,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      phase: json['phase'] ?? 'adaptation',
      pillar: json['pillar'] ?? 'general',
      isCompleted: json['is_completed'] ?? false,
      orderIndex: json['order_index'] ?? 0,
    );
  }
}
