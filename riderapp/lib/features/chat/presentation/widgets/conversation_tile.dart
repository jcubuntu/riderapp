import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';

/// Tile widget for displaying a conversation in the list
class ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final String currentUserId;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const ConversationTile({
    super.key,
    required this.conversation,
    required this.currentUserId,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasUnread = conversation.unreadCount > 0;

    return ListTile(
      onTap: onTap,
      onLongPress: onLongPress,
      leading: _buildAvatar(context),
      title: Row(
        children: [
          Expanded(
            child: Text(
              conversation.getDisplayName(currentUserId),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatTime(conversation.lastMessage?.sentAt ?? conversation.updatedAt),
            style: theme.textTheme.bodySmall?.copyWith(
              color: hasUnread ? colorScheme.primary : colorScheme.onSurfaceVariant,
              fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              _getLastMessagePreview(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: hasUnread
                    ? colorScheme.onSurface
                    : colorScheme.onSurfaceVariant,
                fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (hasUnread) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                conversation.unreadCount > 99
                    ? '99+'
                    : conversation.unreadCount.toString(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final avatarUrl = conversation.getAvatarUrl(currentUserId);
    final colorScheme = Theme.of(context).colorScheme;
    final displayName = conversation.getDisplayName(currentUserId);

    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return CircleAvatar(
        backgroundImage: NetworkImage(avatarUrl),
        radius: 24,
      );
    }

    // Generate avatar with initials
    final initials = displayName.isNotEmpty
        ? displayName.split(' ').take(2).map((s) => s.isNotEmpty ? s[0] : '').join().toUpperCase()
        : '?';

    return CircleAvatar(
      radius: 24,
      backgroundColor: colorScheme.primaryContainer,
      child: Text(
        initials,
        style: TextStyle(
          color: colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getLastMessagePreview() {
    final lastMessage = conversation.lastMessage;
    if (lastMessage == null) {
      return 'No messages yet';
    }

    final isFromMe = lastMessage.sender.id == currentUserId;
    final prefix = isFromMe ? 'You: ' : '';

    switch (lastMessage.type) {
      case MessageType.image:
        return '$prefix📷 Photo';
      case MessageType.file:
        return '$prefix📎 File';
      case MessageType.system:
        return lastMessage.content;
      case MessageType.text:
        return '$prefix${lastMessage.content}';
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return DateFormat('HH:mm').format(dateTime);
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return DateFormat('EEE').format(dateTime);
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }
}
