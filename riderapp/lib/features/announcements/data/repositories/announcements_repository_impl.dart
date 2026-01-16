import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcements_repository.dart';
import '../datasources/announcements_remote_datasource.dart';

/// Implementation of AnnouncementsRepository
class AnnouncementsRepositoryImpl implements AnnouncementsRepository {
  final AnnouncementsRemoteDataSource _remoteDataSource;

  AnnouncementsRepositoryImpl(this._remoteDataSource);

  @override
  Future<PaginatedAnnouncements> getAnnouncements({
    int page = 1,
    int limit = 10,
    AnnouncementPriority? priority,
    AnnouncementCategory? category,
  }) {
    return _remoteDataSource.getAnnouncements(
      page: page,
      limit: limit,
      priority: priority,
      category: category,
    );
  }

  @override
  Future<Announcement> getAnnouncementById(String id) {
    return _remoteDataSource.getAnnouncementById(id);
  }

  @override
  Future<void> markAsRead(String id) {
    return _remoteDataSource.markAsRead(id);
  }

  @override
  Future<int> getUnreadCount() {
    return _remoteDataSource.getUnreadCount();
  }
}
