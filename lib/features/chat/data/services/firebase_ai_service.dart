import 'package:chat_app_ai/features/chat/domain/entities/chat_attachment.dart';
import 'package:chat_app_ai/features/chat/domain/entities/chat_message.dart';
import 'package:firebase_ai/firebase_ai.dart';

class FirebaseAiService {
  FirebaseAiService()
    : _model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-3.8-flash',
      );

  final GenerativeModel _model;

  Future<String> generateResponse(
    String prompt,
    List<NewChatAttachment> attachments,
    List<ChatMessage> history,
  ) async {
    final contents = <Content>[
      for (final message in history)
        if (message.text.trim().isNotEmpty)
          message.isUser
              ? Content.text(message.text)
              : Content.model([TextPart(message.text)]),
    ];
    final parts = <Part>[];
    if (prompt.trim().isNotEmpty) {
      parts.add(TextPart(prompt.trim()));
    } else if (attachments.isNotEmpty) {
      parts.add(const TextPart('Please describe these attachments.'));
    }
    for (final attachment in attachments.where(
      (file) => file.mimeType.startsWith('image/'),
    )) {
      parts.add(InlineDataPart(attachment.mimeType, attachment.bytes));
    }
    contents.add(Content.multi(parts));
    final response = await _model.generateContent(contents);
    final text = response.text?.trim();
    if (text == null || text.isEmpty) {
      throw StateError('The AI returned an empty response.');
    }
    return text;
  }
}
