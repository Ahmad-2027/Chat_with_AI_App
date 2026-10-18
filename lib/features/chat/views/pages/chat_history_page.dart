import 'package:chat_app_ai/core/localization/app_strings.dart';
import 'package:chat_app_ai/features/chat/cubit/chat_cubit.dart';
import 'package:chat_app_ai/features/chat/views/widgets/chat_history_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChatHistoryPage extends StatelessWidget {
  const ChatHistoryPage({required this.onChatSelected, super.key});

  final ValueChanged<String> onChatSelected;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return BlocBuilder<ChatCubit, ChatState>(
      builder: (context, state) {
        if (state.chats.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.forum_outlined,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    strings.text('noChats'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 7),
                  Text(
                    strings.text('emptyHistory'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (state.error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      strings.text(state.error!),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: context.read<ChatCubit>().loadHistory,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: state.chats.length,
            separatorBuilder: (_, _) => const SizedBox(height: 9),
            itemBuilder: (context, index) => ChatHistoryTile(
              chat: state.chats[index],
              onTap: () => onChatSelected(state.chats[index].id),
              onDelete: state.isSending
                  ? null
                  : () => _confirmDelete(context, state.chats[index].id),
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, String chatId) async {
    final strings = AppStrings.of(context);
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.text('deleteChatTitle')),
        content: Text(strings.text('deleteChatWarning')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.text('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              strings.text('delete'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (shouldDelete != true || !context.mounted) return;
    try {
      await context.read<ChatCubit>().deleteChat(chatId);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(strings.text('somethingWentWrong')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
