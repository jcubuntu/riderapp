import 'dart:io';

import 'package:mocktail/mocktail.dart';

import 'package:riderapp/features/auth/data/repositories/auth_repository.dart';
import 'package:riderapp/features/incidents/domain/entities/incident.dart';
import 'package:riderapp/features/incidents/domain/repositories/incidents_repository.dart';
import 'package:riderapp/features/notifications/domain/entities/app_notification.dart';
import 'package:riderapp/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:riderapp/features/chat/domain/entities/conversation.dart';
import 'package:riderapp/features/chat/domain/entities/message.dart';
import 'package:riderapp/features/chat/domain/repositories/chat_repository.dart';
import 'package:riderapp/core/socket/socket_service.dart';

// ==================== Mock Classes ====================

/// Mock class for AuthRepository
class MockAuthRepository extends Mock implements AuthRepository {}

/// Mock class for IIncidentsRepository
class MockIncidentsRepository extends Mock implements IIncidentsRepository {}

/// Mock class for NotificationsRepository
class MockNotificationsRepository extends Mock implements NotificationsRepository {}

/// Mock class for ChatRepository
class MockChatRepository extends Mock implements ChatRepository {}

/// Mock class for SocketService
class MockSocketService extends Mock implements SocketService {}

// ==================== Fallback Values Registration ====================

/// Register all fallback values for mocktail
void registerFallbackValues() {
  // Register fallback values for enum types used in method parameters
  registerFallbackValue(IncidentCategory.general);
  registerFallbackValue(IncidentStatus.pending);
  registerFallbackValue(IncidentPriority.medium);
  registerFallbackValue(NotificationType.system);
  registerFallbackValue(ConversationType.direct);
  registerFallbackValue(MessageType.text);
  registerFallbackValue(File(''));
}

// ==================== Test Data Factories ====================

/// Factory class for creating test data
class TestDataFactory {
  /// Create a test incident
  static Incident createIncident({
    String id = 'incident-1',
    String title = 'Test Incident',
    String description = 'Test Description',
    IncidentCategory category = IncidentCategory.general,
    IncidentStatus status = IncidentStatus.pending,
    IncidentPriority priority = IncidentPriority.medium,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final now = DateTime.now();
    return Incident(
      id: id,
      reportedBy: 'user-1',
      category: category,
      status: status,
      priority: priority,
      title: title,
      description: description,
      location: const IncidentLocation(),
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
    );
  }

  /// Create a paginated incidents result
  static PaginatedIncidents createPaginatedIncidents({
    List<Incident>? incidents,
    int total = 1,
    int page = 1,
    int limit = 10,
    int totalPages = 1,
  }) {
    return PaginatedIncidents(
      incidents: incidents ?? [createIncident()],
      total: total,
      page: page,
      limit: limit,
      totalPages: totalPages,
    );
  }

  /// Create incident statistics
  static IncidentStats createIncidentStats() {
    return const IncidentStats(
      byCategory: {'general': 5, 'accident': 3},
      byStatus: {'pending': 4, 'resolved': 4},
      byPriority: {'low': 2, 'medium': 4, 'high': 2},
      topProvinces: [],
      recentCount: RecentCount(last24h: 2, last7d: 5, last30d: 8, total: 10),
    );
  }

  /// Create a test notification
  static AppNotification createNotification({
    String id = 'notification-1',
    String title = 'Test Notification',
    String body = 'Test Body',
    NotificationType type = NotificationType.system,
    bool isRead = false,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      type: type,
      isRead: isRead,
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  /// Create paginated notifications result
  static PaginatedNotifications createPaginatedNotifications({
    List<AppNotification>? notifications,
    int total = 1,
    int page = 1,
    int totalPages = 1,
    int unreadCount = 0,
  }) {
    return PaginatedNotifications(
      notifications: notifications ?? [createNotification()],
      total: total,
      page: page,
      limit: 20,
      totalPages: totalPages,
      unreadCount: unreadCount,
    );
  }

  /// Create a test conversation
  static Conversation createConversation({
    String id = 'conversation-1',
    String? title,
    ConversationType type = ConversationType.direct,
    List<Participant>? participants,
    Message? lastMessage,
    int unreadCount = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final now = DateTime.now();
    return Conversation(
      id: id,
      title: title,
      type: type,
      participants: participants ?? [
        const Participant(id: 'user-1', name: 'User 1'),
        const Participant(id: 'user-2', name: 'User 2'),
      ],
      lastMessage: lastMessage,
      unreadCount: unreadCount,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
    );
  }

  /// Create paginated conversations result
  static PaginatedConversations createPaginatedConversations({
    List<Conversation>? conversations,
    int total = 1,
    int page = 1,
    int totalPages = 1,
  }) {
    return PaginatedConversations(
      conversations: conversations ?? [createConversation()],
      total: total,
      page: page,
      limit: 20,
      totalPages: totalPages,
    );
  }

  /// Create a test message
  static Message createMessage({
    String id = 'message-1',
    String conversationId = 'conversation-1',
    String senderId = 'user-1',
    String content = 'Test Message',
    MessageType type = MessageType.text,
    bool isRead = false,
    DateTime? sentAt,
  }) {
    return Message(
      id: id,
      conversationId: conversationId,
      sender: MessageSender(id: senderId, name: 'Test User'),
      content: content,
      type: type,
      isRead: isRead,
      sentAt: sentAt ?? DateTime.now(),
    );
  }

  /// Create paginated messages result
  static PaginatedMessages createPaginatedMessages({
    List<Message>? messages,
    int total = 1,
    int page = 1,
    int totalPages = 1,
  }) {
    return PaginatedMessages(
      messages: messages ?? [createMessage()],
      total: total,
      page: page,
      limit: 50,
      totalPages: totalPages,
    );
  }
}
