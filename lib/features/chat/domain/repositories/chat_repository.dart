import 'package:chat_app_ai/features/chat/domain/entities/chat_message.dart';
import 'package:chat_app_ai/features/chat/domain/entities/chat_session.dart';

abstract interface class ChatRepository {
  Future<List<ChatSession>> loadChats(String userId);
  Future<List<ChatMessage>> loadMessages(String userId, String chatId);
  Future<String> createChat(String userId, String firstMessage);
  Future<void> addMessage(
    String userId,
    String chatId,
    ChatMessage message,
  );
}
