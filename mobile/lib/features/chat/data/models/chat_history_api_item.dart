class ChatHistoryApiItem {
  ChatHistoryApiItem({
    required this.id,
    required this.role,
    required this.text,
    required this.date,
  });

  final int id;
  final String role;
  final String text;
  final DateTime date;

  factory ChatHistoryApiItem.fromJson(Map<String, dynamic> json) {
    return ChatHistoryApiItem(
      id: json['id'] as int,
      role: json['role'] as String,
      text: json['text'] as String,
      date: DateTime.parse(json['date'] as String).toLocal(),
    );
  }
}
