import 'package:equatable/equatable.dart';

import 'message.dart';

/// Participant in a conversation
class Participant extends Equatable {
  final String id;
  final String? name;
  final String? phone;
  final String? avatarUrl;
  final String? role;

  const Participant({
    required this.id,
    this.name,
    this.phone,
    this.avatarUrl,
    this.role,
  });

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? json['fullName'] as String?,
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String? ?? json['avatarUrl'] as String?,
      role: json['role'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'avatarUrl': avatarUrl,
        'role': role,
      };

  @override
  List<Object?> get props => [id, name, phone, avatarUrl, role];
}

/// Conversation type
enum ConversationType {
  direct,
  group,
  incident;

  static ConversationType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'group':
        return ConversationType.group;
      case 'incident':
        return ConversationType.incident;
      default:
        return ConversationType.direct;
    }
  }
}

/// Conversation model
class Conversation extends Equatable {
  final String id;
  final String? title;
  final ConversationType type;
  final List<Participant> participants;
  final Message? lastMessage;
  final int unreadCount;
  final String? incidentId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Conversation({
    required this.id,
    this.title,
    this.type = ConversationType.direct,
    required this.participants,
    this.lastMessage,
    this.unreadCount = 0,
    this.incidentId,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Get display name for conversation
  String getDisplayName(String currentUserId) {
    if (title != null && title!.isNotEmpty) {
      return title!;
    }

    // For direct conversations, show the other participant's name
    if (type == ConversationType.direct && participants.isNotEmpty) {
      final otherParticipant = participants.firstWhere(
        (p) => p.id != currentUserId,
        orElse: () => participants.first,
      );
      return otherParticipant.name ?? otherParticipant.phone ?? 'Unknown';
    }

    // For group conversations, show participants names
    final names = participants
        .where((p) => p.id != currentUserId)
        .take(3)
        .map((p) => p.name ?? p.phone ?? 'Unknown')
        .toList();

    if (names.isEmpty) return 'Conversation';
    return names.join(', ');
  }

  /// Get avatar URL for conversation
  String? getAvatarUrl(String currentUserId) {
    if (type == ConversationType.direct && participants.isNotEmpty) {
      final otherParticipant = participants.firstWhere(
        (p) => p.id != currentUserId,
        orElse: () => participants.first,
      );
      return otherParticipant.avatarUrl;
    }
    return null;
  }

  factory Conversation.fromJson(Map<String, dynamic> json) {
    final participantsJson = json['participants'] as List<dynamic>? ?? [];

    return Conversation(
      id: json['id'] as String? ?? '',
      title: json['title'] as String?,
      type: ConversationType.fromString(json['type'] as String? ?? 'direct'),
      participants: participantsJson
          .map((p) => Participant.fromJson(p as Map<String, dynamic>))
          .toList(),
      lastMessage: json['lastMessage'] != null || json['last_message'] != null
          ? Message.fromJson((json['lastMessage'] ?? json['last_message'])
              as Map<String, dynamic>)
          : null,
      unreadCount:
          json['unread_count'] as int? ?? json['unreadCount'] as int? ?? 0,
      incidentId:
          json['incident_id'] as String? ?? json['incidentId'] as String?,
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'type': type.name,
        'participants': participants.map((p) => p.toJson()).toList(),
        'lastMessage': lastMessage?.toJson(),
        'unreadCount': unreadCount,
        'incidentId': incidentId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  Conversation copyWith({
    String? id,
    String? title,
    ConversationType? type,
    List<Participant>? participants,
    Message? lastMessage,
    int? unreadCount,
    String? incidentId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Conversation(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      incidentId: incidentId ?? this.incidentId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        type,
        participants,
        lastMessage,
        unreadCount,
        incidentId,
        createdAt,
        updatedAt,
      ];
}

/// Paginated conversations result
class PaginatedConversations extends Equatable {
  final List<Conversation> conversations;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  const PaginatedConversations({
    required this.conversations,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  bool get hasNextPage => page < totalPages;

  factory PaginatedConversations.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as List<dynamic>? ?? [];
    final pagination = json['pagination'] as Map<String, dynamic>? ?? {};

    return PaginatedConversations(
      conversations: data
          .where((e) => e != null)
          .map((e) => Conversation.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: pagination['total'] as int? ?? 0,
      page: pagination['page'] as int? ?? 1,
      limit: pagination['limit'] as int? ?? 20,
      totalPages: pagination['totalPages'] as int? ?? 1,
    );
  }

  @override
  List<Object?> get props => [conversations, total, page, limit, totalPages];
}
