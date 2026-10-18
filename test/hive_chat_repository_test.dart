import 'dart:io';
import 'dart:typed_data';

import 'package:chat_app_ai/features/chat/data/repositories/hive_chat_repository.dart';
import 'package:chat_app_ai/features/chat/domain/entities/chat_attachment.dart';
import 'package:chat_app_ai/features/chat/domain/entities/chat_message.dart';
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
}
