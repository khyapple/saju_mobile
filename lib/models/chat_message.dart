class ChatMessage {
  final String role; // 'user' | 'assistant'
  final String content;
  final DateTime? createdAt;

  ChatMessage({
    required this.role,
    required this.content,
    this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      role: json['role'] as String,
      content: json['content'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
}
