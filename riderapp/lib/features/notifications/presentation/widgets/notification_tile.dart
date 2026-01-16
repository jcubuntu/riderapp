import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/app_notification.dart';

/// Widget to display a single notification item
class NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;
  final bool isDeleting;

  const NotificationTile({
    super.key,
    required this.notification,
    this.onTap,
    this.onDismiss,
    this.isDeleting = false,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss?.call(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.error,
        child: const Icon(
          Icons.delete_outline,
          color: Colors.white,
        ),
      ),
      child: Stack(
        children: [
          InkWell(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: notification.isRead
                    ? Colors.white
                    : AppColors.primary.withValues(alpha: 0.05),
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.border,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon based on notification type
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _getTypeColor(notification.type).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getTypeIcon(notification.type),
                      color: _getTypeColor(notification.type),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Unread indicator
                            if (!notification.isRead) ...[
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            // Title
                            Expanded(
                              child: Text(
                                notification.title,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: notification.isRead
                                          ? FontWeight.normal
                                          : FontWeight.w600,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Body
                        Text(
                          notification.body,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        // Time ago
                        Text(
                          _formatTimeAgo(notification.createdAt),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                        ),
                      ],
                    ),
                  ),
                  // Chevron for navigation
                  if (notification.hasTarget)
                    Icon(
                      Icons.chevron_right,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                ],
              ),
            ),
          ),
          // Loading overlay when deleting
          if (isDeleting)
            Positioned.fill(
              child: Container(
                color: Colors.white.withValues(alpha: 0.7),
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Get icon based on notification type
  IconData _getTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.chat:
        return Icons.chat_bubble_outline;
      case NotificationType.incident:
        return Icons.warning_amber_outlined;
      case NotificationType.announcement:
        return Icons.campaign_outlined;
      case NotificationType.sos:
        return Icons.sos;
      case NotificationType.approval:
        return Icons.verified_user_outlined;
      case NotificationType.system:
        return Icons.info_outline;
    }
  }

  /// Get color based on notification type
  Color _getTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.chat:
        return AppColors.primary;
      case NotificationType.incident:
        return AppColors.warning;
      case NotificationType.announcement:
        return AppColors.info;
      case NotificationType.sos:
        return AppColors.error;
      case NotificationType.approval:
        return AppColors.success;
      case NotificationType.system:
        return AppColors.textSecondary;
    }
  }

  /// Format time ago string
  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'common.justNow'.tr();
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return 'common.minutesAgo'.tr(namedArgs: {'count': minutes.toString()});
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return 'common.hoursAgo'.tr(namedArgs: {'count': hours.toString()});
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return 'common.daysAgo'.tr(namedArgs: {'count': days.toString()});
    } else {
      // Format as date for older notifications
      return DateFormat('MMM d, yyyy').format(dateTime);
    }
  }
}
