import 'package:chat_app_ai/features/chat/services/firebase_ai_service.dart';
import 'package:chat_app_ai/features/chat/models/chat_attachment.dart';
import 'package:chat_app_ai/features/chat/models/chat_message.dart';
import 'package:chat_app_ai/features/chat/models/chat_session.dart';
import 'package:chat_app_ai/features/chat/services/chat_repository.dart';
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
    } catch (_) {
      if (!isClosed) emit(state.copyWith(error: 'somethingWentWrong'));
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
    } catch (_) {
      if (!isClosed) emit(state.copyWith(error: 'somethingWentWrong'));
    }
  }

  Future<void> deleteChat(String chatId) async {
    await _repository.deleteChat(_userId, chatId);
    if (isClosed) return;
    final isCurrentChat = state.chatId == chatId;
    emit(
      state.copyWith(
        chats: state.chats.where((chat) => chat.id != chatId).toList(),
        clearChatId: isCurrentChat,
        messages: isCurrentChat ? const [] : null,
        clearError: true,
      ),
    );
  }

  void startNewChat() {
    if (state.isSending) return;
    emit(
      state.copyWith(clearChatId: true, messages: const [], clearError: true),
    );
  }

  Future<void> editMessage(
    String messageId,
    String text, {
    required List<ChatAttachment> attachments,
  }) async {
    if (state.isSending) return;
    final chatId = state.chatId;
    if (chatId == null) {
      throw StateError('There is no active chat to edit.');
    }
    final messageIndex = state.messages.indexWhere(
      (message) => message.id == messageId && message.isUser,
    );
    if (messageIndex == -1) {
      throw StateError('The message to edit was not found.');
    }
    final originalMessage = state.messages[messageIndex];
    final editedText = text.trim();
    if (editedText.isEmpty && attachments.isEmpty) {
      throw ArgumentError.value(text, 'text', 'Must not be empty.');
    }
    final attachmentsUnchanged =
        attachments.length == originalMessage.attachments.length &&
        List.generate(attachments.length, (index) => index).every(
          (index) =>
              identical(attachments[index], originalMessage.attachments[index]),
        );
    if (editedText == originalMessage.text.trim() && attachmentsUnchanged) {
      return;
    }

    final previousMessages = state.messages.take(messageIndex).toList();
    final editedMessage = ChatMessage(
      id: originalMessage.id,
      text: editedText,
      isUser: true,
      createdAt: DateTime.now(),
      attachments: attachments,
    );
    emit(state.copyWith(isSending: true, clearError: true));
    try {
      final response = await _aiService.generateResponse(
        editedMessage.text,
        editedMessage.attachments
            .map(
              (attachment) => NewChatAttachment(
                name: attachment.name,
                mimeType: attachment.mimeType,
                bytes: attachment.bytes,
              ),
            )
            .toList(growable: false),
        previousMessages,
      );
      if (isClosed) return;
      final assistantMessage = ChatMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        text: response,
        isUser: false,
        createdAt: DateTime.now(),
      );
      final updatedMessages = [
        ...previousMessages,
        editedMessage,
        assistantMessage,
      ];
      await _repository.replaceMessages(_userId, chatId, updatedMessages);
      if (isClosed) return;
      emit(
        state.copyWith(
          messages: updatedMessages,
          isSending: false,
          clearError: true,
        ),
      );
      await loadHistory();
    } finally {
      if (!isClosed && state.isSending) {
        emit(state.copyWith(isSending: false));
      }
    }
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
            error: 'somethingWentWrong',
          ),
        );
      }
    }
  }
}
