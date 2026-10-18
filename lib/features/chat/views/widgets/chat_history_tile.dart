import 'package:chat_app_ai/features/chat/models/chat_session.dart';
import 'package:chat_app_ai/core/localization/app_strings.dart';
import 'package:flutter/material.dart';

class ChatHistoryTile extends StatelessWidget {
  const ChatHistoryTile({
    required this.chat,
    required this.onTap,
    required this.onDelete,
    super.key,
  });

  final ChatSession chat;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final formattedDate = MaterialLocalizations.of(context)
        .formatMediumDate(chat.updatedAt);
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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(formattedDate, style: Theme.of(context).textTheme.labelSmall),
            IconButton(
              tooltip: AppStrings.of(context).text('deleteChat'),
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded),
              color: Theme.of(context).colorScheme.error,
            ),
          ],
        ),
      ),
    );
  }
}
