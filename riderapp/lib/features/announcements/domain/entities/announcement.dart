import 'package:equatable/equatable.dart';

/// Announcement categories
enum AnnouncementCategory {
  general,
  safety,
  event,
  alert,
  update,
  maintenance;

  String get displayName {
    switch (this) {
      case AnnouncementCategory.general:
        return 'General';
      case AnnouncementCategory.safety:
        return 'Safety';
      case AnnouncementCategory.event:
        return 'Event';
      case AnnouncementCategory.alert:
        return 'Alert';
      case AnnouncementCategory.update:
        return 'Update';
      case AnnouncementCategory.maintenance:
        return 'Maintenance';
    }
  }

  static AnnouncementCategory fromString(String value) {
    switch (value.toLowerCase()) {
      case 'general':
        return AnnouncementCategory.general;
      case 'safety':
        return AnnouncementCategory.safety;
      case 'event':
        return AnnouncementCategory.event;
      case 'alert':
        return AnnouncementCategory.alert;
      case 'update':
        return AnnouncementCategory.update;
      case 'maintenance':
        return AnnouncementCategory.maintenance;
      default:
        return AnnouncementCategory.general;
    }
  }
}

/// Announcement priority levels
enum AnnouncementPriority {
  low,
  normal,
  high,
  urgent;

  String get displayName {
    switch (this) {
      case AnnouncementPriority.low:
        return 'Low';
      case AnnouncementPriority.normal:
        return 'Normal';
      case AnnouncementPriority.high:
        return 'High';
      case AnnouncementPriority.urgent:
        return 'Urgent';
    }
  }

  static AnnouncementPriority fromString(String value) {
    switch (value.toLowerCase()) {
      case 'low':
        return AnnouncementPriority.low;
      case 'normal':
        return AnnouncementPriority.normal;
      case 'high':
        return AnnouncementPriority.high;
      case 'urgent':
        return AnnouncementPriority.urgent;
      default:
        return AnnouncementPriority.normal;
    }
  }
}

/// Announcement target audience
enum AnnouncementAudience {
  all,
  riders,
  police,
  admin;

  String get displayName {
    switch (this) {
      case AnnouncementAudience.all:
        return 'All Users';
      case AnnouncementAudience.riders:
        return 'Riders';
      case AnnouncementAudience.police:
        return 'Police';
      case AnnouncementAudience.admin:
        return 'Administrators';
    }
  }

  static AnnouncementAudience fromString(String value) {
    switch (value.toLowerCase()) {
      case 'all':
        return AnnouncementAudience.all;
      case 'riders':
        return AnnouncementAudience.riders;
      case 'police':
        return AnnouncementAudience.police;
      case 'admin':
        return AnnouncementAudience.admin;
      default:
        return AnnouncementAudience.all;
    }
  }
}

/// Announcement status
enum AnnouncementStatus {
  draft,
  scheduled,
  published,
  archived;

  String get displayName {
    switch (this) {
      case AnnouncementStatus.draft:
        return 'Draft';
      case AnnouncementStatus.scheduled:
        return 'Scheduled';
      case AnnouncementStatus.published:
        return 'Published';
      case AnnouncementStatus.archived:
        return 'Archived';
    }
  }

  static AnnouncementStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'draft':
        return AnnouncementStatus.draft;
      case 'scheduled':
        return AnnouncementStatus.scheduled;
      case 'published':
        return AnnouncementStatus.published;
      case 'archived':
        return AnnouncementStatus.archived;
      default:
        return AnnouncementStatus.draft;
    }
  }
}

/// Author information model
class AnnouncementAuthor extends Equatable {
  final String id;
  final String? name;
  final String? phone;
  final String? role;

  const AnnouncementAuthor({
    required this.id,
    this.name,
    this.phone,
    this.role,
  });

  factory AnnouncementAuthor.fromJson(Map<String, dynamic> json) {
    return AnnouncementAuthor(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? json['fullName'] as String?,
      phone: json['phone'] as String?,
      role: json['role'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'role': role,
    };
  }

  @override
  List<Object?> get props => [id, name, phone, role];
}

/// Main Announcement model
class Announcement extends Equatable {
  final String id;
  final String title;
  final String content;
  final String? summary;
  final String? imageUrl;
  final String? attachmentUrl;
  final String? attachmentName;
  final AnnouncementCategory category;
  final AnnouncementPriority priority;
  final AnnouncementAudience targetAudience;
  final String? targetProvince;
  final AnnouncementStatus status;
  final DateTime? publishAt;
  final DateTime? expiresAt;
  final int viewCount;
  final bool isPinned;
  final bool isRead;
  final AnnouncementAuthor? author;
  final AnnouncementAuthor? publisher;
  final DateTime? publishedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Announcement({
    required this.id,
    required this.title,
    required this.content,
    this.summary,
    this.imageUrl,
    this.attachmentUrl,
    this.attachmentName,
    required this.category,
    required this.priority,
    required this.targetAudience,
    this.targetProvince,
    required this.status,
    this.publishAt,
    this.expiresAt,
    this.viewCount = 0,
    this.isPinned = false,
    this.isRead = false,
    this.author,
    this.publisher,
    this.publishedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Check if announcement is active
  bool get isActive => status == AnnouncementStatus.published;

  /// Check if announcement has expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Check if announcement has an attachment
  bool get hasAttachment => attachmentUrl != null && attachmentUrl!.isNotEmpty;

  /// Check if announcement has an image
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  /// Get preview text (summary or truncated content)
  String get previewText {
    if (summary != null && summary!.isNotEmpty) {
      return summary!;
    }
    if (content.length <= 150) {
      return content;
    }
    return '${content.substring(0, 150)}...';
  }

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      summary: json['summary'] as String?,
      imageUrl: json['image_url'] as String? ?? json['imageUrl'] as String?,
      attachmentUrl:
          json['attachment_url'] as String? ?? json['attachmentUrl'] as String?,
      attachmentName: json['attachment_name'] as String? ??
          json['attachmentName'] as String?,
      category: AnnouncementCategory.fromString(json['category'] as String? ?? ''),
      priority: AnnouncementPriority.fromString(json['priority'] as String? ?? ''),
      targetAudience: AnnouncementAudience.fromString(
          json['target_audience'] as String? ??
              json['targetAudience'] as String? ??
              ''),
      targetProvince: json['target_province'] as String? ??
          json['targetProvince'] as String?,
      status: AnnouncementStatus.fromString(json['status'] as String? ?? ''),
      publishAt: json['publish_at'] != null
          ? DateTime.parse(json['publish_at'] as String)
          : json['publishAt'] != null
              ? DateTime.parse(json['publishAt'] as String)
              : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : json['expiresAt'] != null
              ? DateTime.parse(json['expiresAt'] as String)
              : null,
      viewCount:
          json['view_count'] as int? ?? json['viewCount'] as int? ?? 0,
      isPinned:
          json['is_pinned'] as bool? ?? json['isPinned'] as bool? ?? false,
      isRead: json['is_read'] as bool? ?? json['isRead'] as bool? ?? false,
      author: json['author'] != null
          ? AnnouncementAuthor.fromJson(json['author'] as Map<String, dynamic>)
          : json['created_by'] != null && json['created_by'] is Map
              ? AnnouncementAuthor.fromJson(
                  json['created_by'] as Map<String, dynamic>)
              : null,
      publisher: json['publisher'] != null
          ? AnnouncementAuthor.fromJson(json['publisher'] as Map<String, dynamic>)
          : json['published_by'] != null && json['published_by'] is Map
              ? AnnouncementAuthor.fromJson(
                  json['published_by'] as Map<String, dynamic>)
              : null,
      publishedAt: json['published_at'] != null
          ? DateTime.parse(json['published_at'] as String)
          : json['publishedAt'] != null
              ? DateTime.parse(json['publishedAt'] as String)
              : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'] as String)
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'summary': summary,
      'imageUrl': imageUrl,
      'attachmentUrl': attachmentUrl,
      'attachmentName': attachmentName,
      'category': category.name,
      'priority': priority.name,
      'targetAudience': targetAudience.name,
      'targetProvince': targetProvince,
      'status': status.name,
      'publishAt': publishAt?.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'viewCount': viewCount,
      'isPinned': isPinned,
      'isRead': isRead,
      'author': author?.toJson(),
      'publisher': publisher?.toJson(),
      'publishedAt': publishedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Announcement copyWith({
    String? id,
    String? title,
    String? content,
    String? summary,
    String? imageUrl,
    String? attachmentUrl,
    String? attachmentName,
    AnnouncementCategory? category,
    AnnouncementPriority? priority,
    AnnouncementAudience? targetAudience,
    String? targetProvince,
    AnnouncementStatus? status,
    DateTime? publishAt,
    DateTime? expiresAt,
    int? viewCount,
    bool? isPinned,
    bool? isRead,
    AnnouncementAuthor? author,
    AnnouncementAuthor? publisher,
    DateTime? publishedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Announcement(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      summary: summary ?? this.summary,
      imageUrl: imageUrl ?? this.imageUrl,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      attachmentName: attachmentName ?? this.attachmentName,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      targetAudience: targetAudience ?? this.targetAudience,
      targetProvince: targetProvince ?? this.targetProvince,
      status: status ?? this.status,
      publishAt: publishAt ?? this.publishAt,
      expiresAt: expiresAt ?? this.expiresAt,
      viewCount: viewCount ?? this.viewCount,
      isPinned: isPinned ?? this.isPinned,
      isRead: isRead ?? this.isRead,
      author: author ?? this.author,
      publisher: publisher ?? this.publisher,
      publishedAt: publishedAt ?? this.publishedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        content,
        summary,
        imageUrl,
        attachmentUrl,
        attachmentName,
        category,
        priority,
        targetAudience,
        targetProvince,
        status,
        publishAt,
        expiresAt,
        viewCount,
        isPinned,
        isRead,
        author,
        publisher,
        publishedAt,
        createdAt,
        updatedAt,
      ];
}

/// Paginated announcements result
class PaginatedAnnouncements extends Equatable {
  final List<Announcement> announcements;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  const PaginatedAnnouncements({
    required this.announcements,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  bool get hasNextPage => page < totalPages;
  bool get hasPreviousPage => page > 1;

  factory PaginatedAnnouncements.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as List<dynamic>? ?? [];
    final pagination = json['pagination'] as Map<String, dynamic>? ?? {};

    return PaginatedAnnouncements(
      announcements: data
          .map((e) => Announcement.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: pagination['total'] as int? ?? 0,
      page: pagination['page'] as int? ?? 1,
      limit: pagination['limit'] as int? ?? 10,
      totalPages: pagination['totalPages'] as int? ?? 1,
    );
  }

  @override
  List<Object?> get props => [announcements, total, page, limit, totalPages];
}

/// Unread count result
class UnreadAnnouncementsCount extends Equatable {
  final int count;

  const UnreadAnnouncementsCount({required this.count});

  factory UnreadAnnouncementsCount.fromJson(Map<String, dynamic> json) {
    return UnreadAnnouncementsCount(
      count: json['count'] as int? ?? json['unreadCount'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [count];
}
