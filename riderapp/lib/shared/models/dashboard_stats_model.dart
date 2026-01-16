// Dashboard statistics models for RiderApp.
// These models represent the statistics returned from the Stats API.

/// Dashboard overview statistics
class DashboardStats {
  final IncidentCounts incidents;
  final UserCounts users;
  final List<RecentIncident> recentIncidents;
  final List<RecentAnnouncement> recentAnnouncements;
  final int unreadNotifications;
  final int activeSosAlerts;

  DashboardStats({
    required this.incidents,
    required this.users,
    required this.recentIncidents,
    required this.recentAnnouncements,
    required this.unreadNotifications,
    required this.activeSosAlerts,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      incidents: IncidentCounts.fromJson(
        json['incidents'] as Map<String, dynamic>? ?? {},
      ),
      users: UserCounts.fromJson(
        json['users'] as Map<String, dynamic>? ?? {},
      ),
      recentIncidents: (json['recentIncidents'] as List<dynamic>? ?? [])
          .map((e) => RecentIncident.fromJson(e as Map<String, dynamic>))
          .toList(),
      recentAnnouncements: (json['recentAnnouncements'] as List<dynamic>? ?? [])
          .map((e) => RecentAnnouncement.fromJson(e as Map<String, dynamic>))
          .toList(),
      unreadNotifications: json['unreadNotifications'] as int? ?? 0,
      activeSosAlerts: json['activeSosAlerts'] as int? ?? 0,
    );
  }

  factory DashboardStats.empty() {
    return DashboardStats(
      incidents: IncidentCounts.empty(),
      users: UserCounts.empty(),
      recentIncidents: [],
      recentAnnouncements: [],
      unreadNotifications: 0,
      activeSosAlerts: 0,
    );
  }
}

/// Incident count statistics
class IncidentCounts {
  final int total;
  final int today;
  final int pending;
  final int investigating;
  final int resolved;

  IncidentCounts({
    required this.total,
    required this.today,
    required this.pending,
    required this.investigating,
    required this.resolved,
  });

  factory IncidentCounts.fromJson(Map<String, dynamic> json) {
    return IncidentCounts(
      total: json['total'] as int? ?? 0,
      today: json['today'] as int? ?? 0,
      pending: json['pending'] as int? ?? 0,
      investigating: json['investigating'] as int? ?? 0,
      resolved: json['resolved'] as int? ?? 0,
    );
  }

  factory IncidentCounts.empty() {
    return IncidentCounts(
      total: 0,
      today: 0,
      pending: 0,
      investigating: 0,
      resolved: 0,
    );
  }
}

/// User count statistics
class UserCounts {
  final int total;
  final int pending;
  final int approved;
  final int riders;
  final int volunteers;
  final int police;

  UserCounts({
    required this.total,
    required this.pending,
    required this.approved,
    required this.riders,
    required this.volunteers,
    required this.police,
  });

  factory UserCounts.fromJson(Map<String, dynamic> json) {
    return UserCounts(
      total: json['total'] as int? ?? 0,
      pending: json['pending'] as int? ?? 0,
      approved: json['approved'] as int? ?? 0,
      riders: json['riders'] as int? ?? 0,
      volunteers: json['volunteers'] as int? ?? 0,
      police: json['police'] as int? ?? 0,
    );
  }

  factory UserCounts.empty() {
    return UserCounts(
      total: 0,
      pending: 0,
      approved: 0,
      riders: 0,
      volunteers: 0,
      police: 0,
    );
  }
}

/// Recent incident for dashboard
class RecentIncident {
  final String id;
  final String title;
  final String type;
  final String status;
  final String priority;
  final String? location;
  final DateTime createdAt;

  RecentIncident({
    required this.id,
    required this.title,
    required this.type,
    required this.status,
    required this.priority,
    this.location,
    required this.createdAt,
  });

  factory RecentIncident.fromJson(Map<String, dynamic> json) {
    return RecentIncident(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      type: json['type'] as String? ?? 'other',
      status: json['status'] as String? ?? 'reported',
      priority: json['priority'] as String? ?? 'medium',
      location: json['location'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }
}

/// Recent announcement for dashboard
class RecentAnnouncement {
  final String id;
  final String title;
  final String priority;
  final DateTime createdAt;

  RecentAnnouncement({
    required this.id,
    required this.title,
    required this.priority,
    required this.createdAt,
  });

  factory RecentAnnouncement.fromJson(Map<String, dynamic> json) {
    return RecentAnnouncement(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      priority: json['priority'] as String? ?? 'normal',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }
}

/// Incident summary statistics
class IncidentSummary {
  final int total;
  final int reported;
  final int acknowledged;
  final int investigating;
  final int resolved;
  final int closed;
  final double resolutionRate;
  final double averageResolutionTime;

  IncidentSummary({
    required this.total,
    required this.reported,
    required this.acknowledged,
    required this.investigating,
    required this.resolved,
    required this.closed,
    required this.resolutionRate,
    required this.averageResolutionTime,
  });

  factory IncidentSummary.fromJson(Map<String, dynamic> json) {
    return IncidentSummary(
      total: json['total'] as int? ?? 0,
      reported: json['reported'] as int? ?? 0,
      acknowledged: json['acknowledged'] as int? ?? 0,
      investigating: json['investigating'] as int? ?? 0,
      resolved: json['resolved'] as int? ?? 0,
      closed: json['closed'] as int? ?? 0,
      resolutionRate: (json['resolutionRate'] as num?)?.toDouble() ?? 0.0,
      averageResolutionTime:
          (json['averageResolutionTime'] as num?)?.toDouble() ?? 0.0,
    );
  }

  factory IncidentSummary.empty() {
    return IncidentSummary(
      total: 0,
      reported: 0,
      acknowledged: 0,
      investigating: 0,
      resolved: 0,
      closed: 0,
      resolutionRate: 0.0,
      averageResolutionTime: 0.0,
    );
  }
}

/// Statistics by category (type, status, priority, etc.)
class CategoryStats {
  final String category;
  final int count;
  final double percentage;

  CategoryStats({
    required this.category,
    required this.count,
    required this.percentage,
  });

  factory CategoryStats.fromJson(Map<String, dynamic> json) {
    return CategoryStats(
      category: json['category'] as String? ?? json['type'] as String? ?? '',
      count: json['count'] as int? ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Trend data point
class TrendDataPoint {
  final String period;
  final int count;

  TrendDataPoint({
    required this.period,
    required this.count,
  });

  factory TrendDataPoint.fromJson(Map<String, dynamic> json) {
    return TrendDataPoint(
      period: json['period'] as String? ?? '',
      count: json['count'] as int? ?? 0,
    );
  }
}

/// User summary statistics
class UserSummary {
  final int total;
  final int pending;
  final int approved;
  final int rejected;
  final int suspended;
  final int inactive;
  final double approvalRate;

  UserSummary({
    required this.total,
    required this.pending,
    required this.approved,
    required this.rejected,
    required this.suspended,
    required this.inactive,
    required this.approvalRate,
  });

  factory UserSummary.fromJson(Map<String, dynamic> json) {
    return UserSummary(
      total: json['total'] as int? ?? 0,
      pending: json['pending'] as int? ?? 0,
      approved: json['approved'] as int? ?? 0,
      rejected: json['rejected'] as int? ?? 0,
      suspended: json['suspended'] as int? ?? 0,
      inactive: json['inactive'] as int? ?? 0,
      approvalRate: (json['approvalRate'] as num?)?.toDouble() ?? 0.0,
    );
  }

  factory UserSummary.empty() {
    return UserSummary(
      total: 0,
      pending: 0,
      approved: 0,
      rejected: 0,
      suspended: 0,
      inactive: 0,
      approvalRate: 0.0,
    );
  }
}
