import 'dart:typed_data';

class NewChatAttachment {
  const NewChatAttachment({
    required this.name,
    required this.mimeType,
    required this.bytes,
  });

  final String name;
  final String mimeType;
  final Uint8List bytes;
}

class ChatAttachment {
  const ChatAttachment({
    required this.name,
    required this.mimeType,
    required this.bytes,
    required this.size,
  });

  final String name;
  final String mimeType;
  final Uint8List bytes;
  final int size;

  factory ChatAttachment.fromNew(NewChatAttachment attachment) =>
      ChatAttachment(
        name: attachment.name,
        mimeType: attachment.mimeType,
        bytes: attachment.bytes,
        size: attachment.bytes.lengthInBytes,
      );

  Map<String, Object> toMap() => {
    'name': name,
    'mimeType': mimeType,
    'bytes': bytes,
    'size': size,
  };

  factory ChatAttachment.fromMap(Map<String, dynamic> map) {
    final storedBytes = map['bytes'];
    if (storedBytes is! List<int>) {
      throw const FormatException('Chat attachment bytes are invalid.');
    }
    final bytes = storedBytes is Uint8List
        ? storedBytes
        : Uint8List.fromList(storedBytes);
    return ChatAttachment(
      name: map['name'] as String? ?? 'attachment',
      mimeType: map['mimeType'] as String? ?? 'application/octet-stream',
      bytes: bytes,
      size: map['size'] as int? ?? bytes.lengthInBytes,
    );
  }
}
