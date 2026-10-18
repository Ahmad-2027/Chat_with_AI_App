import 'dart:io';
import 'dart:typed_data';

import 'package:chat_app_ai/features/chat/services/hive_chat_repository.dart';
import 'package:chat_app_ai/features/chat/models/chat_attachment.dart';
import 'package:chat_app_ai/features/chat/models/chat_message.dart';
import 'package:hive_ce/hive.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory hiveDirectory;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp('aura_hive_test_');
    Hive.init(hiveDirectory.path);
  });

  tearDown(() async {
    await Hive.close();
    await hiveDirectory.delete(recursive: true);
  });

  test(
    'persists chat messages and attachments separately per account',
    () async {
      final repository = HiveChatRepository();
      final chatId = await repository.createChat('account-one', 'Hello Aura');
      final attachmentBytes = Uint8List.fromList([0, 1, 2, 255]);
      final userMessage = ChatMessage(
        id: 'message-1',
        text: 'Hello Aura',
        isUser: true,
        createdAt: DateTime.utc(2026, 10, 18),
        attachments: [
          ChatAttachment.fromNew(
            NewChatAttachment(
              name: 'image.png',
              mimeType: 'image/png',
              bytes: attachmentBytes,
            ),
          ),
        ],
      );
      final assistantMessage = ChatMessage(
        id: 'message-2',
        text: 'Hello!',
        isUser: false,
        createdAt: DateTime.utc(2026, 10, 18, 0, 1),
      );

      await repository.addMessage('account-one', chatId, userMessage);
      await repository.addMessage('account-one', chatId, assistantMessage);
      expect(await repository.loadChats('account-two'), isEmpty);

      await Hive.close();
      Hive.init(hiveDirectory.path);
      final restoredRepository = HiveChatRepository();
      final restoredChats = await restoredRepository.loadChats('account-one');
      final restoredMessages = await restoredRepository.loadMessages(
        'account-one',
        chatId,
      );

      expect(restoredChats.single.title, 'Hello Aura');
      expect(restoredChats.single.preview, 'Hello!');
      expect(restoredMessages, hasLength(2));
      expect(restoredMessages.last.text, 'Hello!');
      expect(restoredMessages.first.attachments.single.bytes, attachmentBytes);
      expect(restoredMessages.first.attachments.single.name, 'image.png');
    },
  );

  test('replaces edited turns and deletes individual chats', () async {
    final repository = HiveChatRepository();
    final chatId = await repository.createChat(
      'account-one',
      'Original question',
    );
    final originalQuestion = ChatMessage(
      id: 'user-1',
      text: 'Original question',
      isUser: true,
      createdAt: DateTime.utc(2026, 10, 18),
    );
    final originalResponse = ChatMessage(
      id: 'assistant-1',
      text: 'Old response',
      isUser: false,
      createdAt: DateTime.utc(2026, 10, 18, 0, 1),
    );
    final laterQuestion = ChatMessage(
      id: 'user-2',
      text: 'A later question',
      isUser: true,
      createdAt: DateTime.utc(2026, 10, 18, 0, 2),
    );
    final laterResponse = ChatMessage(
      id: 'assistant-2',
      text: 'A later response',
      isUser: false,
      createdAt: DateTime.utc(2026, 10, 18, 0, 3),
    );
    await repository.addMessage('account-one', chatId, originalQuestion);
    await repository.addMessage('account-one', chatId, originalResponse);
    await repository.addMessage('account-one', chatId, laterQuestion);
    await repository.addMessage('account-one', chatId, laterResponse);

    final editedQuestion = ChatMessage(
      id: originalQuestion.id,
      text: 'Updated question',
      isUser: true,
      createdAt: DateTime.utc(2026, 10, 19),
    );
    final regeneratedResponse = ChatMessage(
      id: 'assistant-3',
      text: 'New response',
      isUser: false,
      createdAt: DateTime.utc(2026, 10, 19, 0, 1),
    );
    await repository.replaceMessages('account-one', chatId, [
      editedQuestion,
      regeneratedResponse,
    ]);

    final messages = await repository.loadMessages('account-one', chatId);
    expect(messages.map((message) => message.id), ['user-1', 'assistant-3']);
    expect(messages.first.text, 'Updated question');
    final chat = (await repository.loadChats('account-one')).single;
    expect(chat.title, 'Updated question');
    expect(chat.preview, 'New response');

    final otherAccountChat = await repository.createChat(
      'account-two',
      'Another account',
    );
    await repository.deleteChat('account-one', chatId);
    expect(await repository.loadChats('account-one'), isEmpty);
    expect(
      (await repository.loadChats('account-two')).single.id,
      otherAccountChat,
    );
    await expectLater(
      repository.loadMessages('account-one', chatId),
      throwsStateError,
    );
  });
}
