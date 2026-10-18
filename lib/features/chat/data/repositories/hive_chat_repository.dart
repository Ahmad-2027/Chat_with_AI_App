import 'dart:math';

import 'package:chat_app_ai/features/chat/domain/entities/chat_attachment.dart';
import 'package:chat_app_ai/features/chat/domain/entities/chat_message.dart';
import 'package:chat_app_ai/features/chat/domain/entities/chat_session.dart';
import 'package:chat_app_ai/features/chat/domain/repositories/chat_repository.dart';
import 'package:hive_ce/hive.dart';

class HiveChatRepository implements ChatRepository {
  static const _boxPrefix = 'chat_history_';

  Future<Box<dynamic>> _boxForUser(String userId) {
    if (userId.trim().isEmpty) {
      throw ArgumentError.value(userId, 'userId', 'Must not be empty.');
    }
    final encodedUserId = userId.codeUnits
        .map((unit) => unit.toRadixString(16).padLeft(4, '0'))
        .join();
    return Hive.openBox<dynamic>('$_boxPrefix$encodedUserId');
  }

  @override
  Future<List<ChatSession>> loadChats(String userId) async {
    final box = await _boxForUser(userId);
    final chats = box.toMap().entries.map((entry) {
      final record = _asMap(entry.value);
      return ChatSession(
        id: entry.key.toString(),
        title: record['title'] as String,
        preview: record['preview'] as String? ?? '',
        updatedAt: _asDateTime(record['updatedAt']),
      );
    }).toList();
    chats.sort((left, right) => right.updatedAt.compareTo(left.updatedAt));
    return chats;
  }

  @override
  Future<List<ChatMessage>> loadMessages(String userId, String chatId) async {
    final box = await _boxForUser(userId);
    final recordValue = box.get(chatId);
    if (recordValue == null) {
      throw StateError('Chat "$chatId" was not found for this account.');
    }
    final record = _asMap(recordValue);
    final storedMessages = record['messages'];
    if (storedMessages is! List) {
      throw const FormatException('Stored chat messages are invalid.');
    }
    return storedMessages
        .map((message) => _messageFromMap(_asMap(message)))
        .toList(growable: false);
  }

  @override
  Future<String> createChat(String userId, String firstMessage) async {
    final box = await _boxForUser(userId);
    final now = DateTime.now();
    final randomSuffix = Random.secure().nextInt(1 << 32);
    final chatId = '${now.microsecondsSinceEpoch}-$randomSuffix';
    final title = firstMessage.trim();
    await box.put(chatId, {
      'title': title.isEmpty ? 'New chat' : _truncate(title, 56),
      'preview': title,
      'updatedAt': now,
      'messages': <Map<String, Object>>[],
    });
    return chatId;
  }

  @override
  Future<void> addMessage(
    String userId,
    String chatId,
    ChatMessage message,
  ) async {
    final box = await _boxForUser(userId);
    final recordValue = box.get(chatId);
    if (recordValue == null) {
      throw StateError('Chat "$chatId" was not found for this account.');
    }
    final record = _asMap(recordValue);
    final storedMessages = record['messages'];
    if (storedMessages is! List) {
      throw const FormatException('Stored chat messages are invalid.');
    }
    final messages = storedMessages.map((value) => _asMap(value)).toList()
      ..add(_messageToMap(message));
    final text = message.text.trim();
    final preview = text.isNotEmpty
        ? text
        : message.attachments.isEmpty
        ? ''
        : message.attachments.first.name;
    await box.put(chatId, {
      ...record,
      'preview': preview,
      'updatedAt': message.createdAt,
      'messages': messages,
    });
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value is! Map) {
      throw const FormatException('Stored chat data is invalid.');
    }
    return Map<String, dynamic>.from(value);
  }

  DateTime _asDateTime(Object? value) {
    if (value is! DateTime) {
      throw const FormatException('Stored chat date is invalid.');
    }
    return value;
  }

  ChatMessage _messageFromMap(Map<String, dynamic> data) {
    final storedAttachments = data['attachments'];
    if (storedAttachments is! List) {
      throw const FormatException('Stored chat attachments are invalid.');
    }
    return ChatMessage(
      id: data['id'] as String,
      text: data['text'] as String,
      isUser: data['isUser'] as bool,
      createdAt: _asDateTime(data['createdAt']),
      attachments: storedAttachments
          .map((value) => ChatAttachment.fromMap(_asMap(value)))
          .toList(growable: false),
    );
  }

  Map<String, Object> _messageToMap(ChatMessage message) => {
    'id': message.id,
    'text': message.text,
    'isUser': message.isUser,
    'createdAt': message.createdAt,
    'attachments': message.attachments
        .map((attachment) => attachment.toMap())
        .toList(growable: false),
  };

  String _truncate(String value, int maxLength) =>
      value.length <= maxLength ? value : '${value.substring(0, maxLength)}…';
}
