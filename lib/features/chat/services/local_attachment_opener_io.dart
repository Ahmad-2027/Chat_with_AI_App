import 'dart:io';

import 'package:chat_app_ai/features/chat/models/chat_attachment.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

const _channel = MethodChannel('aura/local_attachment_opener');

Future<void> openAttachment(ChatAttachment attachment) async {
  final directory = Directory(
    '${(await getTemporaryDirectory()).path}'
    '${Platform.pathSeparator}aura_chat_attachments',
  );

  await directory.create(recursive: true);

  final safeName = attachment.name.replaceAll(
    RegExp(r'[^a-zA-Z0-9._-]'),
    '_',
  );

  final file = File(
    '${directory.path}${Platform.pathSeparator}'
    '${DateTime.now().microsecondsSinceEpoch}_$safeName',
  );

  await file.writeAsBytes(attachment.bytes, flush: true);

  if (Platform.isAndroid || Platform.isIOS) {
    await _channel.invokeMethod<void>('openFile', {
      'path': file.path,
      'mimeType': attachment.mimeType,
    });
    return;
  }

  final (executable, arguments) = switch (Platform.operatingSystem) {
    'windows' => ('cmd', ['/c', 'start', '', file.path]),
    'macos' => ('open', [file.path]),
    'linux' => ('xdg-open', [file.path]),
    _ => throw UnsupportedError(
        'Opening attachments is not supported on this platform.',
      ),
  };

  final process = await Process.start(executable, arguments);
  final exitCode = await process.exitCode;

  if (exitCode != 0) {
    throw ProcessException(
      executable,
      arguments,
      'File opener exited with $exitCode.',
      exitCode,
    );
  }
}