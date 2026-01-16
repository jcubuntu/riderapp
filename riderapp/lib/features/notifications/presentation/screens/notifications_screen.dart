import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/app_notification.dart';
import '../providers/notifications_provider.dart';
import '../providers/notifications_state.dart';
import '../widgets/notification_tile.dart';

/// Screen that displays the list of notifications
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Load notifications on init
    Future.microtask(() {
      ref.read(notificationsProvider.notifier).loadNotifications();
    });

    // Add scroll listener for pagination
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(notificationsProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Text('notifications.title'.tr()),
        actions: [
          // Mark all as read button
          if (state is NotificationsLoaded && state.hasUnread)
            IconButton(
              icon: state.isMarkingAllRead
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.done_all),
              tooltip: 'notifications.markAllRead'.tr(),
              onPressed: state.isMarkingAllRead
                  ? null
                  : () {
                      ref.read(notificationsProvider.notifier).markAllAsRead();
                    },
            ),
          // Clear all button
          if (state is NotificationsLoaded && !state.isEmpty)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'clear') {
                  _showClearAllDialog();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      const Icon(Icons.delete_sweep, color: AppColors.error),
                      const SizedBox(width: 8),
                      Text('notifications.clearAll'.tr()),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(NotificationsState state) {
    switch (state) {
      case NotificationsInitial():
      case NotificationsLoading():
        return const Center(
          child: CircularProgressIndicator(),
        );

      case NotificationsError(:final message):
        return _buildErrorState(message);

      case NotificationsLoaded():
        return _buildLoadedState(state);
    }
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'notifications.errorLoading'.tr(),
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(notificationsProvider.notifier).loadNotifications(refresh: true);
              },
              icon: const Icon(Icons.refresh),
              label: Text('common.retry'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadedState(NotificationsLoaded state) {
    if (state.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(notificationsProvider.notifier).refresh();
      },
      child: ListView.builder(
        controller: _scrollController,
        itemCount: state.notifications.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          // Loading indicator at the bottom
          if (index == state.notifications.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          final notification = state.notifications[index];
          return NotificationTile(
            notification: notification,
            isDeleting: state.deletingId == notification.id,
            onTap: () => _handleNotificationTap(notification),
            onDismiss: () => _handleNotificationDismiss(notification),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none_outlined,
              size: 80,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'notifications.empty'.tr(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'notifications.emptyDesc'.tr(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _handleNotificationTap(AppNotification notification) {
    // Mark as read if not already
    if (!notification.isRead) {
      ref.read(notificationsProvider.notifier).markAsRead(notification.id);
    }

    // Navigate based on notification type and target
    if (notification.hasTarget) {
      _navigateToTarget(notification);
    }
  }

  void _navigateToTarget(AppNotification notification) {
    switch (notification.type) {
      case NotificationType.chat:
        context.push('/chat/${notification.targetId}');
        break;
      case NotificationType.incident:
        context.push('/incidents/${notification.targetId}');
        break;
      case NotificationType.announcement:
        context.push('/announcements/${notification.targetId}');
        break;
      case NotificationType.approval:
        // Navigate to profile or pending approvals based on user role
        context.push('/profile');
        break;
      case NotificationType.sos:
        // Navigate to emergency or incident detail
        if (notification.targetId != null) {
          context.push('/incidents/${notification.targetId}');
        }
        break;
      case NotificationType.system:
        // System notifications typically don't have navigation
        break;
    }
  }

  void _handleNotificationDismiss(AppNotification notification) {
    ref.read(notificationsProvider.notifier).deleteNotification(notification.id);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('notifications.deleted'.tr()),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'common.undo'.tr(),
          onPressed: () {
            // Refresh to restore the notification
            ref.read(notificationsProvider.notifier).refresh();
          },
        ),
      ),
    );
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('notifications.clearAllTitle'.tr()),
        content: Text('notifications.clearAllConfirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(notificationsProvider.notifier).clearAllNotifications();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text('notifications.clearAll'.tr()),
          ),
        ],
      ),
    );
  }
}
