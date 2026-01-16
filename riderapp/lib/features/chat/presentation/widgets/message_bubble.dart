import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../domain/entities/message.dart';
import 'image_message_viewer.dart';

/// Message bubble widget for chat
class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isFromMe;
  final bool showAvatar;
  final bool showTime;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isFromMe,
    this.showAvatar = true,
    this.showTime = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // System messages are centered
    if (message.type == MessageType.system) {
      return _buildSystemMessage(context);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment:
            isFromMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isFromMe && showAvatar) ...[
            _buildAvatar(context),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isFromMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                _buildMessageContent(context, colorScheme),
                if (showTime)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat('HH:mm').format(message.sentAt),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (isFromMe) ...[
                          const SizedBox(width: 4),
                          Icon(
                            message.isRead ? Icons.done_all : Icons.done,
                            size: 14,
                            color: message.isRead
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (isFromMe && showAvatar) ...[
            const SizedBox(width: 8),
            const SizedBox(width: 32), // Placeholder for alignment
          ],
        ],
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context, ColorScheme colorScheme) {
    // For image messages, use a different layout
    if (message.type == MessageType.image) {
      return _buildImageMessage(context, colorScheme);
    }

    // For other message types, use the standard bubble
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: isFromMe
            ? colorScheme.primary
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isFromMe ? 16 : 4),
          bottomRight: Radius.circular(isFromMe ? 4 : 16),
        ),
      ),
      child: _buildContent(context),
    );
  }

  Widget _buildImageMessage(BuildContext context, ColorScheme colorScheme) {
    final imageUrl = message.thumbnailUrl ?? message.attachmentUrl;

    return GestureDetector(
      onTap: () {
        if (message.attachmentUrl != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ImageMessageViewer(
                imageUrl: message.attachmentUrl!,
                heroTag: 'image_${message.id}',
                senderName: message.sender.name,
                sentAt: message.sentAt,
              ),
            ),
          );
        }
      },
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.65,
        ),
        decoration: BoxDecoration(
          color: isFromMe
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isFromMe ? 16 : 4),
            bottomRight: Radius.circular(isFromMe ? 4 : 16),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            if (imageUrl != null)
              Hero(
                tag: 'image_${message.id}',
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (context, url) => _buildImagePlaceholder(context),
                  errorWidget: (context, url, error) =>
                      _buildImageError(context, colorScheme),
                ),
              )
            else
              _buildImageError(context, colorScheme),

            // Caption (if any)
            if (message.content.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  message.content,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isFromMe
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface,
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: double.infinity,
        height: 200,
        color: Colors.white,
      ),
    );
  }

  Widget _buildImageError(BuildContext context, ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      height: 150,
      color: colorScheme.errorContainer,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image,
            color: colorScheme.onErrorContainer,
            size: 40,
          ),
          const SizedBox(height: 8),
          Text(
            'Image failed to load',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onErrorContainer,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sender = message.sender;

    if (sender.avatarUrl != null && sender.avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        backgroundImage: CachedNetworkImageProvider(sender.avatarUrl!),
        radius: 16,
      );
    }

    final initials = sender.name?.isNotEmpty == true
        ? sender.name!
            .split(' ')
            .take(2)
            .map((s) => s.isNotEmpty ? s[0] : '')
            .join()
            .toUpperCase()
        : '?';

    return CircleAvatar(
      radius: 16,
      backgroundColor: colorScheme.secondaryContainer,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: 12,
          color: colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textColor = isFromMe ? colorScheme.onPrimary : colorScheme.onSurface;

    switch (message.type) {
      case MessageType.image:
        // This case is now handled by _buildImageMessage
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.attachmentUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: message.attachmentUrl!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      _buildImagePlaceholder(context),
                  errorWidget: (context, url, error) =>
                      _buildImageError(context, colorScheme),
                ),
              ),
            if (message.content.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                message.content,
                style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
              ),
            ],
          ],
        );

      case MessageType.file:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.attach_file, color: textColor, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.attachmentName ?? 'File',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: textColor,
                      decoration: TextDecoration.underline,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (message.attachmentSize != null)
                    Text(
                      _formatFileSize(message.attachmentSize!),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: textColor.withValues(alpha: 0.7),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );

      case MessageType.text:
      case MessageType.system:
        return Text(
          message.content,
          style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
        );
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Widget _buildSystemMessage(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message.content,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
