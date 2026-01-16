import 'package:equatable/equatable.dart';

import '../notifications/notification_state.dart';

/// Types of deep links supported by the app
enum DeepLinkType {
  chat,
  incident,
  announcement,
  sos,
  approval,
  unknown,
}

/// Represents a pending deep link navigation
class PendingDeepLink extends Equatable {
  final DeepLinkType type;
  final String? targetId;
  final String? action;
  final Map<String, dynamic>? extra;
  final DateTime createdAt;

  PendingDeepLink({
    required this.type,
    this.targetId,
    this.action,
    this.extra,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Create from notification data map
  factory PendingDeepLink.fromNotificationData(Map<String, dynamic> data) {
    final typeString = data['type'] as String? ?? '';
    final type = _parseDeepLinkType(typeString);

    return PendingDeepLink(
      type: type,
      targetId: data['targetId'] as String? ?? data['target_id'] as String?,
      action: data['action'] as String?,
      extra: data,
    );
  }

  /// Create from NotificationPayload
  factory PendingDeepLink.fromNotificationPayload(NotificationPayload payload) {
    final type = _parseDeepLinkType(payload.type);

    // Extract target ID based on notification type
    String? targetId;
    switch (type) {
      case DeepLinkType.chat:
        targetId = payload.data['conversationId'] as String? ??
            payload.data['conversation_id'] as String?;
        break;
      case DeepLinkType.incident:
        targetId = payload.data['incidentId'] as String? ??
            payload.data['incident_id'] as String?;
        break;
      case DeepLinkType.announcement:
        targetId = payload.data['announcementId'] as String? ??
            payload.data['announcement_id'] as String?;
        break;
      case DeepLinkType.sos:
        targetId = payload.data['sosId'] as String? ??
            payload.data['sos_id'] as String? ??
            payload.data['incidentId'] as String?;
        break;
      case DeepLinkType.approval:
        targetId = payload.data['userId'] as String? ??
            payload.data['user_id'] as String?;
        break;
      case DeepLinkType.unknown:
        targetId = payload.data['targetId'] as String? ??
            payload.data['target_id'] as String?;
        break;
    }

    return PendingDeepLink(
      type: type,
      targetId: targetId,
      action: payload.data['action'] as String?,
      extra: payload.data,
      createdAt: payload.receivedAt,
    );
  }

  /// Parse deep link type from string
  static DeepLinkType _parseDeepLinkType(String typeString) {
    switch (typeString.toLowerCase()) {
      case 'chat':
      case 'message':
      case 'conversation':
        return DeepLinkType.chat;
      case 'incident':
      case 'report':
        return DeepLinkType.incident;
      case 'announcement':
      case 'news':
        return DeepLinkType.announcement;
      case 'sos':
      case 'emergency':
        return DeepLinkType.sos;
      case 'approval':
      case 'user_approved':
      case 'user_rejected':
      case 'pending_approval':
        return DeepLinkType.approval;
      default:
        return DeepLinkType.unknown;
    }
  }

  /// Check if the deep link is still valid (not expired)
  /// Deep links expire after 5 minutes
  bool get isValid {
    final expirationTime = createdAt.add(const Duration(minutes: 5));
    return DateTime.now().isBefore(expirationTime);
  }

  /// Check if this deep link has a target ID
  bool get hasTargetId => targetId != null && targetId!.isNotEmpty;

  @override
  List<Object?> get props => [type, targetId, action, createdAt];

  @override
  String toString() {
    return 'PendingDeepLink(type: $type, targetId: $targetId, action: $action)';
  }
}

/// State for the deep link handler
sealed class DeepLinkState extends Equatable {
  const DeepLinkState();
}

/// Initial state - no deep link pending
class DeepLinkInitial extends DeepLinkState {
  const DeepLinkInitial();

  @override
  List<Object?> get props => [];
}

/// Deep link pending - waiting to be processed
class DeepLinkPending extends DeepLinkState {
  final PendingDeepLink deepLink;

  const DeepLinkPending(this.deepLink);

  @override
  List<Object?> get props => [deepLink];
}

/// Deep link is being processed
class DeepLinkProcessing extends DeepLinkState {
  final PendingDeepLink deepLink;

  const DeepLinkProcessing(this.deepLink);

  @override
  List<Object?> get props => [deepLink];
}

/// Deep link was processed successfully
class DeepLinkProcessed extends DeepLinkState {
  final PendingDeepLink deepLink;
  final String? navigatedTo;

  const DeepLinkProcessed(this.deepLink, {this.navigatedTo});

  @override
  List<Object?> get props => [deepLink, navigatedTo];
}

/// Deep link processing failed
class DeepLinkFailed extends DeepLinkState {
  final PendingDeepLink deepLink;
  final String error;

  const DeepLinkFailed(this.deepLink, this.error);

  @override
  List<Object?> get props => [deepLink, error];
}
