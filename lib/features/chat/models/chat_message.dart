import 'package:chat_app_ai/features/chat/models/chat_attachment.dart';

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.createdAt,
    this.attachments = const [],
  });

  final String id;
  final String text;
  final bool isUser;
  final DateTime createdAt;
  final List<ChatAttachment> attachments;
}
