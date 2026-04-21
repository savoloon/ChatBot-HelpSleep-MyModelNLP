enum MessageAuthor { user, assistant }

enum ChatMessageStatus { pending, sent, failed }

class ChatMessage {
  ChatMessage({
    required this.id,
    required this.text,
    required this.author,
    required this.createdAt,
    this.status = ChatMessageStatus.sent,
  });

  final String id;
  final String text;
  final MessageAuthor author;
  final DateTime createdAt;
  final ChatMessageStatus status;

  ChatMessage copyWith({
    String? id,
    String? text,
    MessageAuthor? author,
    DateTime? createdAt,
    ChatMessageStatus? status,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      author: author ?? this.author,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }
}
