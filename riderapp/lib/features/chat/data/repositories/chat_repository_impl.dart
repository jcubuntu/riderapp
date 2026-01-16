import 'dart:io';

import '../../domain/entities/chat_group.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_datasource.dart';

/// Implementation of ChatRepository
class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource _remoteDataSource;

  ChatRepositoryImpl(this._remoteDataSource);

  @override
  Future<PaginatedConversations> getConversations({
    int page = 1,
    int limit = 20,
  }) {
    return _remoteDataSource.getConversations(page: page, limit: limit);
  }

  @override
  Future<Conversation> getConversationById(String id) {
    return _remoteDataSource.getConversationById(id);
  }

  @override
  Future<Conversation> createConversation({
    required List<String> participantIds,
    String? title,
    ConversationType type = ConversationType.direct,
  }) {
    return _remoteDataSource.createConversation(
      participantIds: participantIds,
      title: title,
      type: type,
    );
  }

  @override
  Future<void> deleteConversation(String id) {
    return _remoteDataSource.deleteConversation(id);
  }

  @override
  Future<PaginatedMessages> getMessages(
    String conversationId, {
    int page = 1,
    int limit = 50,
  }) {
    return _remoteDataSource.getMessages(
      conversationId,
      page: page,
      limit: limit,
    );
  }

  @override
  Future<Message> sendMessage(
    String conversationId, {
    required String content,
    MessageType type = MessageType.text,
  }) {
    return _remoteDataSource.sendMessage(
      conversationId,
      content: content,
      type: type,
    );
  }

  @override
  Future<Message> sendImageMessage(
    String conversationId, {
    required File imageFile,
    String? caption,
    UploadProgressCallback? onProgress,
  }) {
    return _remoteDataSource.sendImageMessage(
      conversationId,
      imageFile: imageFile,
      caption: caption,
      onProgress: onProgress,
    );
  }

  @override
  Future<void> markAsRead(String conversationId) {
    return _remoteDataSource.markAsRead(conversationId);
  }

  @override
  Future<int> getUnreadCount() {
    return _remoteDataSource.getUnreadCount();
  }

  // ============================================================================
  // ROLE-BASED CHAT GROUPS
  // ============================================================================

  @override
  Future<List<ChatGroup>> getGroups() {
    return _remoteDataSource.getGroups();
  }

  @override
  Future<Conversation> joinGroup(String groupId) {
    return _remoteDataSource.joinGroup(groupId);
  }

  @override
  Future<int> autoJoinGroups() {
    return _remoteDataSource.autoJoinGroups();
  }
}
