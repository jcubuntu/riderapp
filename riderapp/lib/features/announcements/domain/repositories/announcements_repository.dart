import '../entities/announcement.dart';

/// Abstract repository interface for announcements
abstract class AnnouncementsRepository {
  /// Get list of announcements with optional filters
  Future<PaginatedAnnouncements> getAnnouncements({
    int page = 1,
    int limit = 10,
    AnnouncementPriority? priority,
    AnnouncementCategory? category,
  });

  /// Get announcement by ID
  Future<Announcement> getAnnouncementById(String id);

  /// Mark announcement as read
  Future<void> markAsRead(String id);

  /// Get unread announcements count
  Future<int> getUnreadCount();
}
