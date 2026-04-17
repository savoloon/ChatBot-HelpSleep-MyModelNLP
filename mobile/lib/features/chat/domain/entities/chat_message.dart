enum MessageAuthor { user, assistant }

class ChatMessage {
  ChatMessage({
    required this.id,
    required this.text,
    required this.author,
    required this.createdAt,
  });

  final String id;
  final String text;
  final MessageAuthor author;
  final DateTime createdAt;
}
