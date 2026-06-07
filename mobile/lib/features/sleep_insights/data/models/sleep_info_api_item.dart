class SleepInfoApiItem {
  SleepInfoApiItem({
    required this.id,
    required this.userId,
    required this.date,
    required this.duration,
    required this.schedule,
  });

  final int id;
  final int userId;
  final DateTime date;
  final double? duration;
  final String? schedule;

  factory SleepInfoApiItem.fromJson(Map<String, dynamic> json) {
    return SleepInfoApiItem(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      date: DateTime.parse(json['date'] as String).toLocal(),
      duration: (json['duration'] as num?)?.toDouble(),
      schedule: json['schedule'] as String?,
    );
  }
}
