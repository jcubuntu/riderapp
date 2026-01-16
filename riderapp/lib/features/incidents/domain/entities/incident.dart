import 'package:equatable/equatable.dart';

/// Incident categories
enum IncidentCategory {
  intelligence,
  accident,
  general;

  String get displayName {
    switch (this) {
      case IncidentCategory.intelligence:
        return 'Intelligence/Tips';
      case IncidentCategory.accident:
        return 'Accident';
      case IncidentCategory.general:
        return 'General Assistance';
    }
  }

  static IncidentCategory fromString(String value) {
    switch (value.toLowerCase()) {
      case 'intelligence':
        return IncidentCategory.intelligence;
      case 'accident':
        return IncidentCategory.accident;
      case 'general':
      default:
        return IncidentCategory.general;
    }
  }
}

/// Incident status
enum IncidentStatus {
  pending,
  reviewing,
  verified,
  resolved,
  rejected;

  String get displayName {
    switch (this) {
      case IncidentStatus.pending:
        return 'Pending';
      case IncidentStatus.reviewing:
        return 'Under Review';
      case IncidentStatus.verified:
        return 'Verified';
      case IncidentStatus.resolved:
        return 'Resolved';
      case IncidentStatus.rejected:
        return 'Rejected';
    }
  }

  static IncidentStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'pending':
        return IncidentStatus.pending;
      case 'reviewing':
        return IncidentStatus.reviewing;
      case 'verified':
        return IncidentStatus.verified;
      case 'resolved':
        return IncidentStatus.resolved;
      case 'rejected':
        return IncidentStatus.rejected;
      default:
        return IncidentStatus.pending;
    }
  }
}

/// Incident priority levels
enum IncidentPriority {
  low,
  medium,
  high,
  critical;

  String get displayName {
    switch (this) {
      case IncidentPriority.low:
        return 'Low';
      case IncidentPriority.medium:
        return 'Medium';
      case IncidentPriority.high:
        return 'High';
      case IncidentPriority.critical:
        return 'Critical';
    }
  }

  static IncidentPriority fromString(String value) {
    switch (value.toLowerCase()) {
      case 'low':
        return IncidentPriority.low;
      case 'medium':
        return IncidentPriority.medium;
      case 'high':
        return IncidentPriority.high;
      case 'critical':
        return IncidentPriority.critical;
      default:
        return IncidentPriority.medium;
    }
  }
}

/// Incident location model
class IncidentLocation extends Equatable {
  final double? latitude;
  final double? longitude;
  final String? address;
  final String? province;
  final String? district;

  const IncidentLocation({
    this.latitude,
    this.longitude,
    this.address,
    this.province,
    this.district,
  });

  bool get hasCoordinates => latitude != null && longitude != null;

  factory IncidentLocation.fromJson(Map<String, dynamic> json) {
    return IncidentLocation(
      latitude: json['location_lat'] != null
          ? double.tryParse(json['location_lat'].toString())
          : json['locationLat'] != null
              ? double.tryParse(json['locationLat'].toString())
              : null,
      longitude: json['location_lng'] != null
          ? double.tryParse(json['location_lng'].toString())
          : json['locationLng'] != null
              ? double.tryParse(json['locationLng'].toString())
              : null,
      address: json['location_address'] as String? ??
          json['locationAddress'] as String?,
      province: json['location_province'] as String? ??
          json['locationProvince'] as String?,
      district: json['location_district'] as String? ??
          json['locationDistrict'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'locationLat': latitude,
      'locationLng': longitude,
      'locationAddress': address,
      'locationProvince': province,
      'locationDistrict': district,
    };
  }

  IncidentLocation copyWith({
    double? latitude,
    double? longitude,
    String? address,
    String? province,
    String? district,
  }) {
    return IncidentLocation(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      province: province ?? this.province,
      district: district ?? this.district,
    );
  }

  @override
  List<Object?> get props => [latitude, longitude, address, province, district];
}

/// Incident attachment model
class IncidentAttachment extends Equatable {
  final String id;
  final String incidentId;
  final String fileName;
  final String? filePath;
  final String fileUrl;
  final String fileType;
  final String? mimeType;
  final int? fileSize;
  final int? width;
  final int? height;
  final int? duration;
  final String? thumbnailUrl;
  final String? description;
  final int sortOrder;
  final bool isPrimary;
  final String? uploadedBy;
  final DateTime createdAt;

  const IncidentAttachment({
    required this.id,
    required this.incidentId,
    required this.fileName,
    this.filePath,
    required this.fileUrl,
    required this.fileType,
    this.mimeType,
    this.fileSize,
    this.width,
    this.height,
    this.duration,
    this.thumbnailUrl,
    this.description,
    this.sortOrder = 0,
    this.isPrimary = false,
    this.uploadedBy,
    required this.createdAt,
  });

  bool get isImage => fileType == 'image';
  bool get isVideo => fileType == 'video';
  bool get isDocument => fileType == 'document';

  factory IncidentAttachment.fromJson(Map<String, dynamic> json) {
    return IncidentAttachment(
      id: json['id'] as String,
      incidentId: json['incident_id'] as String? ??
          json['incidentId'] as String? ??
          '',
      fileName: json['file_name'] as String? ??
          json['fileName'] as String? ??
          '',
      filePath: json['file_path'] as String? ?? json['filePath'] as String?,
      fileUrl: json['file_url'] as String? ?? json['fileUrl'] as String? ?? '',
      fileType: json['file_type'] as String? ??
          json['fileType'] as String? ??
          'image',
      mimeType: json['mime_type'] as String? ?? json['mimeType'] as String?,
      fileSize: json['file_size'] as int? ?? json['fileSize'] as int?,
      width: json['width'] as int?,
      height: json['height'] as int?,
      duration: json['duration'] as int?,
      thumbnailUrl:
          json['thumbnail_url'] as String? ?? json['thumbnailUrl'] as String?,
      description: json['description'] as String?,
      sortOrder: json['sort_order'] as int? ?? json['sortOrder'] as int? ?? 0,
      isPrimary:
          json['is_primary'] as bool? ?? json['isPrimary'] as bool? ?? false,
      uploadedBy:
          json['uploaded_by'] as String? ?? json['uploadedBy'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'incidentId': incidentId,
      'fileName': fileName,
      'filePath': filePath,
      'fileUrl': fileUrl,
      'fileType': fileType,
      'mimeType': mimeType,
      'fileSize': fileSize,
      'width': width,
      'height': height,
      'duration': duration,
      'thumbnailUrl': thumbnailUrl,
      'description': description,
      'sortOrder': sortOrder,
      'isPrimary': isPrimary,
      'uploadedBy': uploadedBy,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        incidentId,
        fileName,
        filePath,
        fileUrl,
        fileType,
        mimeType,
        fileSize,
        width,
        height,
        duration,
        thumbnailUrl,
        description,
        sortOrder,
        isPrimary,
        uploadedBy,
        createdAt,
      ];
}

/// Main Incident model
class Incident extends Equatable {
  final String id;
  final String reportedBy;
  final IncidentCategory category;
  final IncidentStatus status;
  final IncidentPriority priority;
  final String title;
  final String description;
  final IncidentLocation location;
  final DateTime? incidentDate;
  final String? assignedTo;
  final DateTime? assignedAt;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? reviewNotes;
  final String? resolvedBy;
  final DateTime? resolvedAt;
  final String? resolutionNotes;
  final bool isAnonymous;
  final int viewCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Related user names (from API joins)
  final String? reporterName;
  final String? reporterPhone;
  final String? assigneeName;
  final String? assigneePhone;
  final String? reviewerName;
  final String? resolverName;

  // Attachments
  final List<IncidentAttachment> attachments;

  const Incident({
    required this.id,
    required this.reportedBy,
    required this.category,
    required this.status,
    required this.priority,
    required this.title,
    required this.description,
    required this.location,
    this.incidentDate,
    this.assignedTo,
    this.assignedAt,
    this.reviewedBy,
    this.reviewedAt,
    this.reviewNotes,
    this.resolvedBy,
    this.resolvedAt,
    this.resolutionNotes,
    this.isAnonymous = false,
    this.viewCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.reporterName,
    this.reporterPhone,
    this.assigneeName,
    this.assigneePhone,
    this.reviewerName,
    this.resolverName,
    this.attachments = const [],
  });

  /// Check if incident is open (can be updated)
  bool get isOpen =>
      status == IncidentStatus.pending || status == IncidentStatus.reviewing;

  /// Check if incident is closed
  bool get isClosed =>
      status == IncidentStatus.resolved || status == IncidentStatus.rejected;

  /// Check if incident has been assigned
  bool get isAssigned => assignedTo != null;

  /// Get display name for reporter (considering anonymous)
  String get displayReporterName =>
      isAnonymous ? 'Anonymous' : (reporterName ?? 'Unknown');

  factory Incident.fromJson(Map<String, dynamic> json) {
    return Incident(
      id: json['id'] as String,
      reportedBy:
          json['reported_by'] as String? ?? json['reportedBy'] as String? ?? '',
      category: IncidentCategory.fromString(json['category'] as String? ?? ''),
      status: IncidentStatus.fromString(json['status'] as String? ?? ''),
      priority: IncidentPriority.fromString(json['priority'] as String? ?? ''),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      location: IncidentLocation.fromJson(json),
      incidentDate: json['incident_date'] != null
          ? DateTime.parse(json['incident_date'] as String)
          : json['incidentDate'] != null
              ? DateTime.parse(json['incidentDate'] as String)
              : null,
      assignedTo:
          json['assigned_to'] as String? ?? json['assignedTo'] as String?,
      assignedAt: json['assigned_at'] != null
          ? DateTime.parse(json['assigned_at'] as String)
          : json['assignedAt'] != null
              ? DateTime.parse(json['assignedAt'] as String)
              : null,
      reviewedBy:
          json['reviewed_by'] as String? ?? json['reviewedBy'] as String?,
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'] as String)
          : json['reviewedAt'] != null
              ? DateTime.parse(json['reviewedAt'] as String)
              : null,
      reviewNotes:
          json['review_notes'] as String? ?? json['reviewNotes'] as String?,
      resolvedBy:
          json['resolved_by'] as String? ?? json['resolvedBy'] as String?,
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : json['resolvedAt'] != null
              ? DateTime.parse(json['resolvedAt'] as String)
              : null,
      resolutionNotes: json['resolution_notes'] as String? ??
          json['resolutionNotes'] as String?,
      isAnonymous:
          json['is_anonymous'] as bool? ?? json['isAnonymous'] as bool? ?? false,
      viewCount:
          json['view_count'] as int? ?? json['viewCount'] as int? ?? 0,
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
      reporterName:
          json['reporter_name'] as String? ?? json['reporterName'] as String?,
      reporterPhone:
          json['reporter_phone'] as String? ?? json['reporterPhone'] as String?,
      assigneeName:
          json['assignee_name'] as String? ?? json['assigneeName'] as String?,
      assigneePhone:
          json['assignee_phone'] as String? ?? json['assigneePhone'] as String?,
      reviewerName:
          json['reviewer_name'] as String? ?? json['reviewerName'] as String?,
      resolverName:
          json['resolver_name'] as String? ?? json['resolverName'] as String?,
      attachments: json['attachments'] != null
          ? (json['attachments'] as List<dynamic>)
              .map((e) =>
                  IncidentAttachment.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reportedBy': reportedBy,
      'category': category.name,
      'status': status.name,
      'priority': priority.name,
      'title': title,
      'description': description,
      ...location.toJson(),
      'incidentDate': incidentDate?.toIso8601String(),
      'assignedTo': assignedTo,
      'assignedAt': assignedAt?.toIso8601String(),
      'reviewedBy': reviewedBy,
      'reviewedAt': reviewedAt?.toIso8601String(),
      'reviewNotes': reviewNotes,
      'resolvedBy': resolvedBy,
      'resolvedAt': resolvedAt?.toIso8601String(),
      'resolutionNotes': resolutionNotes,
      'isAnonymous': isAnonymous,
      'viewCount': viewCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'reporterName': reporterName,
      'reporterPhone': reporterPhone,
      'assigneeName': assigneeName,
      'assigneePhone': assigneePhone,
      'reviewerName': reviewerName,
      'resolverName': resolverName,
      'attachments': attachments.map((e) => e.toJson()).toList(),
    };
  }

  Incident copyWith({
    String? id,
    String? reportedBy,
    IncidentCategory? category,
    IncidentStatus? status,
    IncidentPriority? priority,
    String? title,
    String? description,
    IncidentLocation? location,
    DateTime? incidentDate,
    String? assignedTo,
    DateTime? assignedAt,
    String? reviewedBy,
    DateTime? reviewedAt,
    String? reviewNotes,
    String? resolvedBy,
    DateTime? resolvedAt,
    String? resolutionNotes,
    bool? isAnonymous,
    int? viewCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? reporterName,
    String? reporterPhone,
    String? assigneeName,
    String? assigneePhone,
    String? reviewerName,
    String? resolverName,
    List<IncidentAttachment>? attachments,
  }) {
    return Incident(
      id: id ?? this.id,
      reportedBy: reportedBy ?? this.reportedBy,
      category: category ?? this.category,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      incidentDate: incidentDate ?? this.incidentDate,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedAt: assignedAt ?? this.assignedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewNotes: reviewNotes ?? this.reviewNotes,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      viewCount: viewCount ?? this.viewCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      reporterName: reporterName ?? this.reporterName,
      reporterPhone: reporterPhone ?? this.reporterPhone,
      assigneeName: assigneeName ?? this.assigneeName,
      assigneePhone: assigneePhone ?? this.assigneePhone,
      reviewerName: reviewerName ?? this.reviewerName,
      resolverName: resolverName ?? this.resolverName,
      attachments: attachments ?? this.attachments,
    );
  }

  @override
  List<Object?> get props => [
        id,
        reportedBy,
        category,
        status,
        priority,
        title,
        description,
        location,
        incidentDate,
        assignedTo,
        assignedAt,
        reviewedBy,
        reviewedAt,
        reviewNotes,
        resolvedBy,
        resolvedAt,
        resolutionNotes,
        isAnonymous,
        viewCount,
        createdAt,
        updatedAt,
        reporterName,
        reporterPhone,
        assigneeName,
        assigneePhone,
        reviewerName,
        resolverName,
        attachments,
      ];
}

/// Incident statistics model
class IncidentStats extends Equatable {
  final Map<String, int> byCategory;
  final Map<String, int> byStatus;
  final Map<String, int> byPriority;
  final List<ProvinceCount> topProvinces;
  final RecentCount recentCount;

  const IncidentStats({
    required this.byCategory,
    required this.byStatus,
    required this.byPriority,
    required this.topProvinces,
    required this.recentCount,
  });

  factory IncidentStats.fromJson(Map<String, dynamic> json) {
    return IncidentStats(
      byCategory: (json['byCategory'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v as int)) ??
          {},
      byStatus: (json['byStatus'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v as int)) ??
          {},
      byPriority: (json['byPriority'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v as int)) ??
          {},
      topProvinces: (json['topProvinces'] as List<dynamic>?)
              ?.map((e) => ProvinceCount.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      recentCount: json['recentCount'] != null
          ? RecentCount.fromJson(json['recentCount'] as Map<String, dynamic>)
          : const RecentCount(),
    );
  }

  @override
  List<Object?> get props =>
      [byCategory, byStatus, byPriority, topProvinces, recentCount];
}

/// Province count for statistics
class ProvinceCount extends Equatable {
  final String province;
  final int count;

  const ProvinceCount({
    required this.province,
    required this.count,
  });

  factory ProvinceCount.fromJson(Map<String, dynamic> json) {
    return ProvinceCount(
      province: json['province'] as String? ?? '',
      count: json['count'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [province, count];
}

/// Recent count for statistics
class RecentCount extends Equatable {
  final int last24h;
  final int last7d;
  final int last30d;
  final int total;

  const RecentCount({
    this.last24h = 0,
    this.last7d = 0,
    this.last30d = 0,
    this.total = 0,
  });

  factory RecentCount.fromJson(Map<String, dynamic> json) {
    return RecentCount(
      last24h: json['last24h'] as int? ?? 0,
      last7d: json['last7d'] as int? ?? 0,
      last30d: json['last30d'] as int? ?? 0,
      total: json['total'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [last24h, last7d, last30d, total];
}

/// Paginated incidents result
class PaginatedIncidents extends Equatable {
  final List<Incident> incidents;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  const PaginatedIncidents({
    required this.incidents,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  bool get hasNextPage => page < totalPages;
  bool get hasPreviousPage => page > 1;

  factory PaginatedIncidents.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as List<dynamic>? ?? [];
    final pagination = json['pagination'] as Map<String, dynamic>? ?? {};

    return PaginatedIncidents(
      incidents: data
          .map((e) => Incident.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: pagination['total'] as int? ?? 0,
      page: pagination['page'] as int? ?? 1,
      limit: pagination['limit'] as int? ?? 10,
      totalPages: pagination['totalPages'] as int? ?? 1,
    );
  }

  @override
  List<Object?> get props => [incidents, total, page, limit, totalPages];
}
