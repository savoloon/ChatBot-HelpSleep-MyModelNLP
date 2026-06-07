class SleepInsight {
  SleepInsight({
    required this.id,
    required this.date,
    required this.duration,
    required this.schedule,
  });

  final int id;
  final DateTime date;
  final double duration;
  final String? schedule;
}
