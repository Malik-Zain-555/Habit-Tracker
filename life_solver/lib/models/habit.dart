class Habit {
  final String id;
  final String title;
  final String description;
  final int currentStreak;
  final DateTime? lastCompleted;

  Habit({
    required this.id,
    required this.title,
    required this.description,
    required this.currentStreak,
    this.lastCompleted,
  });

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['_id'],
      title: json['title'],
      description: json['description'] ?? '',
      currentStreak: json['currentStreak'],
      lastCompleted: json['lastCompleted'] != null
          ? DateTime.parse(json['lastCompleted'])
          : null,
    );
  }
}
