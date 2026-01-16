import 'package:equatable/equatable.dart';

import '../../domain/entities/app_notification.dart';

/// Base state for notifications
sealed class NotificationsState extends Equatable {
  const NotificationsState();

  @override
  List<Object?> get props => [];
}

/// Initial state - no data loaded yet
class NotificationsInitial extends NotificationsState {
  const NotificationsInitial();
}

/// Loading state - fetching notifications
class NotificationsLoading extends NotificationsState {
  const NotificationsLoading();
}

/// Loaded state - notifications are available
class NotificationsLoaded extends NotificationsState {
  final List<AppNotification> notifications;
  final int total;
  final int page;
  final int totalPages;
  final int unreadCount;
  final bool isLoadingMore;
  final bool isMarkingAllRead;
  final String? deletingId;

  const NotificationsLoaded({
    required this.notifications,
    required this.total,
    required this.page,
    required this.totalPages,
    this.unreadCount = 0,
    this.isLoadingMore = false,
    this.isMarkingAllRead = false,
    this.deletingId,
  });

  bool get hasMore => page < totalPages;
  bool get hasUnread => unreadCount > 0;
  bool get isEmpty => notifications.isEmpty;

  NotificationsLoaded copyWith({
    List<AppNotification>? notifications,
    int? total,
    int? page,
    int? totalPages,
    int? unreadCount,
    bool? isLoadingMore,
    bool? isMarkingAllRead,
    String? deletingId,
    bool clearDeletingId = false,
  }) {
    return NotificationsLoaded(
      notifications: notifications ?? this.notifications,
      total: total ?? this.total,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isMarkingAllRead: isMarkingAllRead ?? this.isMarkingAllRead,
      deletingId: clearDeletingId ? null : (deletingId ?? this.deletingId),
    );
  }

  @override
  List<Object?> get props => [
        notifications,
        total,
        page,
        totalPages,
        unreadCount,
        isLoadingMore,
        isMarkingAllRead,
        deletingId,
      ];
}

/// Error state - failed to fetch notifications
class NotificationsError extends NotificationsState {
  final String message;

  const NotificationsError(this.message);

  @override
  List<Object?> get props => [message];
}
