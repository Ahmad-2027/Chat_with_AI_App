import 'package:chat_app_ai/features/chat/data/services/firebase_ai_service.dart';
import 'package:chat_app_ai/features/chat/domain/entities/chat_attachment.dart';
import 'package:chat_app_ai/features/chat/domain/entities/chat_message.dart';
import 'package:chat_app_ai/features/chat/domain/entities/chat_session.dart';
import 'package:chat_app_ai/features/chat/domain/repositories/chat_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChatState {
  const ChatState({
    this.chatId,
    this.messages = const [],
    this.chats = const [],
    this.isSending = false,
    this.error,
  });

  final String? chatId;
  final List<ChatMessage> messages;
  final List<ChatSession> chats;
  final bool isSending;
  final String? error;

  ChatState copyWith({
    String? chatId,
    bool clearChatId = false,
    List<ChatMessage>? messages,
    List<ChatSession>? chats,
    bool? isSending,
    String? error,
    bool clearError = false,
  }) => ChatState(
    chatId: clearChatId ? null : chatId ?? this.chatId,
    messages: messages ?? this.messages,
    chats: chats ?? this.chats,
    isSending: isSending ?? this.isSending,
    error: clearError ? null : error ?? this.error,
  );
}

class ChatCubit extends Cubit<ChatState> {
  ChatCubit(this._repository, this._aiService, this._userId)
    : super(const ChatState());

  final ChatRepository _repository;
  final FirebaseAiService _aiService;
  final String _userId;

  Future<void> loadHistory() async {
    try {
      final chats = await _repository.loadChats(_userId);
      if (!isClosed) emit(state.copyWith(chats: chats));
    } catch (error) {
      if (!isClosed) emit(state.copyWith(error: error.toString()));
    }
  }

  Future<void> loadChat(String chatId) async {
    if (state.isSending) return;
    emit(
      state.copyWith(
        chatId: chatId,
        messages: const [],
        isSending: false,
        clearError: true,
      ),
    );
    try {
      final messages = await _repository.loadMessages(_userId, chatId);
      if (!isClosed && state.chatId == chatId) {
        emit(state.copyWith(messages: messages));
      }
    } catch (error) {
      if (!isClosed) emit(state.copyWith(error: error.toString()));
    }
  }

  void startNewChat() {
    if (state.isSending) return;
    emit(
      state.copyWith(clearChatId: true, messages: const [], clearError: true),
    );
  }

  Future<void> sendMessage(
    String text,
    List<NewChatAttachment> attachments,
  ) async {
    if (state.isSending || (text.trim().isEmpty && attachments.isEmpty)) return;
    final conversationHistory = state.messages;
    emit(state.copyWith(isSending: true, clearError: true));
    var chatId = state.chatId;
    try {
      chatId ??= await _repository.createChat(_userId, text);
      if (isClosed) return;
      final userMessage = ChatMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        text: text.trim(),
        isUser: true,
        createdAt: DateTime.now(),
        attachments: attachments.map(ChatAttachment.fromNew).toList(),
      );
      await _repository.addMessage(_userId, chatId, userMessage);
      if (isClosed) return;
      final updatedMessages = [...state.messages, userMessage];
      emit(
        state.copyWith(
          chatId: chatId,
          messages: updatedMessages,
          isSending: true,
        ),
      );
      final response = await _aiService.generateResponse(
        text,
        attachments,
        conversationHistory,
      );
      if (isClosed) return;
      final assistantMessage = ChatMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        text: response,
        isUser: false,
        createdAt: DateTime.now(),
      );
      await _repository.addMessage(_userId, chatId, assistantMessage);
      if (isClosed) return;
      emit(
        state.copyWith(
          messages: [...updatedMessages, assistantMessage],
          isSending: false,
        ),
      );
      await loadHistory();
    } catch (error) {
      if (!isClosed) {
        debugPrint(error.toString());
        emit(
          state.copyWith(
            chatId: chatId,
            isSending: false,
            error: error.toString(),
          ),
        );
      }
    }
  }
}
