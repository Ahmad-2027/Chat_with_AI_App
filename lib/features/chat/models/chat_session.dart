class ChatSession {
  const ChatSession({
    required this.id,
    required this.title,
    required this.updatedAt,
    this.preview = '',
  });

  final String id;
  final String title;
  final DateTime updatedAt;
  final String preview;
}
