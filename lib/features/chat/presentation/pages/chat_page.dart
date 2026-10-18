import 'package:chat_app_ai/core/localization/app_strings.dart';
import 'package:chat_app_ai/features/chat/domain/entities/chat_attachment.dart';
import 'package:chat_app_ai/features/chat/domain/entities/chat_message.dart';
import 'package:chat_app_ai/features/chat/presentation/cubit/chat_cubit.dart';
import 'package:chat_app_ai/features/chat/presentation/services/local_attachment_opener.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _promptController = TextEditingController();
  final _scrollController = ScrollController();
  final _attachments = <NewChatAttachment>[];
  final _attachmentOpener = LocalAttachmentOpener();

  @override
  void dispose() {
    _promptController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    try {
      final files = await FilePicker.pickFiles(type: FileType.any);
      if (!mounted) return;
      final selected = <NewChatAttachment>[];
      for (final file in files) {
        selected.add(
          NewChatAttachment(
            name: file.name,
            mimeType: _mimeType(file.name),
            bytes: await file.readAsBytes(),
          ),
        );
      }
      setState(() => _attachments.addAll(selected));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not read selected files: $error')),
        );
      }
    }
  }

  String _mimeType(String name) {
    final extension = name.split('.').last.toLowerCase();
    return switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      'heic' => 'image/heic',
      'mp4' => 'video/mp4',
      'mov' => 'video/quicktime',
      'webm' => 'video/webm',
      'pdf' => 'application/pdf',
      'txt' => 'text/plain',
      'doc' => 'application/msword',
      'docx' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls' => 'application/vnd.ms-excel',
      'xlsx' =>
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'ppt' => 'application/vnd.ms-powerpoint',
      'pptx' => 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      _ => 'application/octet-stream',
    };
  }

  Future<void> _send(ChatCubit cubit) async {
    final text = _promptController.text.trim();
    if (text.isEmpty && _attachments.isEmpty) return;
    final attachments = List<NewChatAttachment>.of(_attachments);
    _promptController.clear();
    setState(_attachments.clear);
    await cubit.sendMessage(text, attachments);
  }

  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _openAttachment(ChatAttachment attachment) async {
    try {
      await _attachmentOpener.open(attachment);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppStrings.of(context).text('openAttachmentFailed')}: $error',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return BlocConsumer<ChatCubit, ChatState>(
      listenWhen: (previous, current) =>
          !identical(previous.messages, current.messages) ||
          (!previous.isSending && current.isSending) ||
          (current.error != null && previous.error != current.error),
      listener: (context, state) {
        _scrollToLatest();
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error ?? strings.text('aiError')),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        final cubit = context.read<ChatCubit>();
        return Column(
          children: [
            Expanded(
              child: state.messages.isEmpty
                  ? _buildWelcome(strings)
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      itemCount:
                          state.messages.length + (state.isSending ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == state.messages.length) {
                          return _buildThinking(strings);
                        }
                        return _buildMessage(state.messages[index]);
                      },
                    ),
            ),
            _buildComposer(strings, state, cubit),
          ],
        );
      },
    );
  }

  Widget _buildWelcome(AppStrings strings) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
    children: [
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7860EF), Color(0xFF6047D3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 25,
            ),
            const SizedBox(height: 20),
            Text(
              strings.text('welcome'),
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              strings.text('welcomeDescription'),
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
      const SizedBox(height: 26),
      Text(
        strings.text('suggestions'),
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(letterSpacing: 1, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 12),
      for (final key in [
        'suggestionBrainstorm',
        'suggestionExplain',
        'suggestionEmail',
      ])
        Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: OutlinedButton.icon(
            onPressed: () {
              _promptController.text = strings.text(key);
              _promptController.selection = TextSelection.collapsed(
                offset: _promptController.text.length,
              );
            },
            icon: const Icon(Icons.bolt_rounded),
            label: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(strings.text(key)),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
            ),
          ),
        ),
    ],
  );

  Widget _buildMessage(ChatMessage message) {
    final scheme = Theme.of(context).colorScheme;
    final isUser = message.isUser;
    return Align(
      alignment: isUser
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.84,
        ),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUser ? scheme.primary : scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.text.isNotEmpty)
              SelectableText(
                message.text,
                style: TextStyle(
                  color: isUser ? scheme.onPrimary : scheme.onSurface,
                  height: 1.45,
                ),
              ),
            for (final attachment in message.attachments)
              _buildAttachment(attachment),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachment(ChatAttachment attachment) {
    if (attachment.mimeType.startsWith('image/')) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: InkWell(
          onTap: () => _openAttachment(attachment),
          borderRadius: BorderRadius.circular(12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              attachment.bytes,
              width: 220,
              height: 180,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _fileTile(attachment),
            ),
          ),
        ),
      );
    }
    return _fileTile(attachment);
  }

  Widget _fileTile(ChatAttachment attachment) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: InkWell(
      onTap: () => _openAttachment(attachment),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              attachment.mimeType.startsWith('video/')
                  ? Icons.play_circle_outline_rounded
                  : Icons.attach_file_rounded,
            ),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                '${attachment.name} (${_formatFileSize(attachment.size)})',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.open_in_new_rounded, size: 16),
          ],
        ),
      ),
    ),
  );

  String _formatFileSize(int size) {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Widget _buildThinking(AppStrings strings) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const SizedBox.square(
            dimension: 17,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 10),
          Text(strings.text('thinking')),
        ],
      ),
    ),
  );

  Widget _buildComposer(AppStrings strings, ChatState state, ChatCubit cubit) =>
      SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 9, 12, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_attachments.isNotEmpty)
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _attachments.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 6),
                    itemBuilder: (context, index) => InputChip(
                      label: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 145),
                        child: Text(
                          _attachments[index].name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      onDeleted: () =>
                          setState(() => _attachments.removeAt(index)),
                    ),
                  ),
                ),
              Row(
                children: [
                  IconButton(
                    tooltip: strings.text('attach'),
                    onPressed: state.isSending ? null : _pickFiles,
                    icon: const Icon(Icons.add_circle_outline_rounded),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _promptController,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _send(cubit),
                      decoration: InputDecoration(
                        hintText: strings.text('askAnything'),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: state.isSending ? null : () => _send(cubit),
                    icon: state.isSending
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.arrow_upward_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}
