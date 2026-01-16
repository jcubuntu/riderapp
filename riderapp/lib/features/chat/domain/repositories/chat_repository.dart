import 'dart:io';

import '../entities/chat_group.dart';
import '../entities/conversation.dart';
import '../entities/message.dart';

/// Upload progress callback type
typedef UploadProgressCallback = void Function(double progress);

/// Abstract repository interface for chat
abstract class ChatRepository {
  /// Get list of conversations
  Future<PaginatedConversations> getConversations({
    int page = 1,
    int limit = 20,
  });

  /// Get conversation by ID
  Future<Conversation> getConversationById(String id);

  /// Create a new conversation
  Future<Conversation> createConversation({
    required List<String> participantIds,
    String? title,
    ConversationType type = ConversationType.direct,
  });

  /// Delete conversation
  Future<void> deleteConversation(String id);

  /// Get messages for a conversation
  Future<PaginatedMessages> getMessages(
    String conversationId, {
    int page = 1,
    int limit = 50,
  });

  /// Send a message
  Future<Message> sendMessage(
    String conversationId, {
    required String content,
    MessageType type = MessageType.text,
  });

  /// Send an image message
  Future<Message> sendImageMessage(
    String conversationId, {
    required File imageFile,
    String? caption,
    UploadProgressCallback? onProgress,
  });

  /// Mark conversation as read
  Future<void> markAsRead(String conversationId);

  /// Get unread count
  Future<int> getUnreadCount();

  // ============================================================================
  // ROLE-BASED CHAT GROUPS
  // ============================================================================

  /// Get list of role-based chat groups accessible by user
  Future<List<ChatGroup>> getGroups();

  /// Join a role-based chat group
  Future<Conversation> joinGroup(String groupId);

  /// Auto-join all accessible chat groups
  Future<int> autoJoinGroups();
}
