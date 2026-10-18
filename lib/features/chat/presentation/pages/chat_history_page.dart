import 'package:chat_app_ai/core/localization/app_strings.dart';
import 'package:chat_app_ai/features/chat/domain/entities/chat_session.dart';
import 'package:chat_app_ai/features/chat/presentation/cubit/chat_cubit.dart';
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
                      state.error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
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
            itemBuilder: (context, index) => _ChatHistoryTile(
              chat: state.chats[index],
              onTap: () => onChatSelected(state.chats[index].id),
            ),
          ),
        );
      },
    );
  }
}

class _ChatHistoryTile extends StatelessWidget {
  const _ChatHistoryTile({required this.chat, required this.onTap});

  final ChatSession chat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final formattedDate = MaterialLocalizations.of(
      context,
    ).formatMediumDate(chat.updatedAt);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            Icons.chat_bubble_outline_rounded,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          chat.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          chat.preview.isEmpty ? formattedDate : chat.preview,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          formattedDate,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ),
    );
  }
}
