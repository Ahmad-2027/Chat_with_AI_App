import 'package:chat_app_ai/features/chat/domain/entities/chat_attachment.dart';

import 'local_attachment_opener_stub.dart'
    if (dart.library.io) 'local_attachment_opener_io.dart'
    as platform;

class LocalAttachmentOpener {
  Future<void> open(ChatAttachment attachment) =>
      platform.openAttachment(attachment);
}
