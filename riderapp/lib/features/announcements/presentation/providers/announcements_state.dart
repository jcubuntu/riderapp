import 'package:equatable/equatable.dart';

import '../../domain/entities/announcement.dart';

/// Base state for announcements
sealed class AnnouncementsState extends Equatable {
  const AnnouncementsState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class AnnouncementsInitial extends AnnouncementsState {
  const AnnouncementsInitial();
}

/// Loading state
class AnnouncementsLoading extends AnnouncementsState {
  const AnnouncementsLoading();
}

/// Loaded state with announcements list
class AnnouncementsLoaded extends AnnouncementsState {
  final List<Announcement> announcements;
  final int total;
  final int page;
  final int totalPages;
  final bool isLoadingMore;

  const AnnouncementsLoaded({
    required this.announcements,
    required this.total,
    required this.page,
    required this.totalPages,
    this.isLoadingMore = false,
  });

  bool get hasMore => page < totalPages;

  AnnouncementsLoaded copyWith({
    List<Announcement>? announcements,
    int? total,
    int? page,
    int? totalPages,
    bool? isLoadingMore,
  }) {
    return AnnouncementsLoaded(
      announcements: announcements ?? this.announcements,
      total: total ?? this.total,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [announcements, total, page, totalPages, isLoadingMore];
}

/// Error state
class AnnouncementsError extends AnnouncementsState {
  final String message;

  const AnnouncementsError(this.message);

  @override
  List<Object?> get props => [message];
}

/// State for single announcement detail
sealed class AnnouncementDetailState extends Equatable {
  const AnnouncementDetailState();

  @override
  List<Object?> get props => [];
}

class AnnouncementDetailInitial extends AnnouncementDetailState {
  const AnnouncementDetailInitial();
}

class AnnouncementDetailLoading extends AnnouncementDetailState {
  const AnnouncementDetailLoading();
}

class AnnouncementDetailLoaded extends AnnouncementDetailState {
  final Announcement announcement;

  const AnnouncementDetailLoaded(this.announcement);

  @override
  List<Object?> get props => [announcement];
}

class AnnouncementDetailError extends AnnouncementDetailState {
  final String message;

  const AnnouncementDetailError(this.message);

  @override
  List<Object?> get props => [message];
}
