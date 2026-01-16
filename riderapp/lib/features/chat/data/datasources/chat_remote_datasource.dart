import 'dart:io';

import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/chat_group.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/chat_repository.dart';

/// Remote data source for chat API calls
class ChatRemoteDataSource {
  final ApiClient _apiClient;

  ChatRemoteDataSource(this._apiClient);

  /// Get list of conversations
  Future<PaginatedConversations> getConversations({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.conversations,
      queryParameters: {'page': page, 'limit': limit},
    );

    if (response.data['success'] == true) {
      return PaginatedConversations.fromJson(response.data);
    }

    throw DioException(
      requestOptions: response.requestOptions,
      message: response.data['message'] ?? 'Failed to fetch conversations',
    );
  }

  /// Get conversation by ID
  Future<Conversation> getConversationById(String id) async {
    final response = await _apiClient.get(
      ApiEndpoints.getConversation(id),
    );

    if (response.data['success'] == true) {
      return Conversation.fromJson(response.data['data']);
    }

    throw DioException(
      requestOptions: response.requestOptions,
      message: response.data['message'] ?? 'Failed to fetch conversation',
    );
  }

  /// Create a new conversation
  Future<Conversation> createConversation({
    required List<String> participantIds,
    String? title,
    ConversationType type = ConversationType.direct,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.createConversation,
      data: {
        'participantIds': participantIds,
        if (title != null) 'title': title,
        'type': type.name,
      },
    );

    if (response.data['success'] == true) {
      return Conversation.fromJson(response.data['data']);
    }

    throw DioException(
      requestOptions: response.requestOptions,
      message: response.data['message'] ?? 'Failed to create conversation',
    );
  }

  /// Delete conversation
  Future<void> deleteConversation(String id) async {
    final response = await _apiClient.delete(
      ApiEndpoints.deleteConversation(id),
    );

    if (response.data['success'] != true) {
      throw DioException(
        requestOptions: response.requestOptions,
        message: response.data['message'] ?? 'Failed to delete conversation',
      );
    }
  }

  /// Get messages for a conversation
  Future<PaginatedMessages> getMessages(
    String conversationId, {
    int page = 1,
    int limit = 50,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.getMessages(conversationId),
      queryParameters: {'page': page, 'limit': limit},
    );

    if (response.data['success'] == true) {
      return PaginatedMessages.fromJson(response.data);
    }

    throw DioException(
      requestOptions: response.requestOptions,
      message: response.data['message'] ?? 'Failed to fetch messages',
    );
  }

  /// Send a message
  Future<Message> sendMessage(
    String conversationId, {
    required String content,
    MessageType type = MessageType.text,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.sendMessage(conversationId),
      data: {
        'content': content,
        'type': type.name,
      },
    );

    if (response.data['success'] == true) {
      return Message.fromJson(response.data['data']);
    }

    throw DioException(
      requestOptions: response.requestOptions,
      message: response.data['message'] ?? 'Failed to send message',
    );
  }

  /// Send an image message with multipart upload
  Future<Message> sendImageMessage(
    String conversationId, {
    required File imageFile,
    String? caption,
    UploadProgressCallback? onProgress,
  }) async {
    // Get the file name from the path
    final fileName = imageFile.path.split('/').last;

    // Create form data with the image file
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        imageFile.path,
        filename: fileName,
      ),
      'type': 'image',
      if (caption != null && caption.isNotEmpty) 'content': caption,
    });

    // Upload with progress tracking using the uploadFile method
    final response = await _apiClient.uploadFile(
      ApiEndpoints.uploadChatAttachment(conversationId),
      formData: formData,
      onSendProgress: onProgress != null
          ? (sent, total) {
              if (total > 0) {
                onProgress(sent / total);
              }
            }
          : null,
    );

    if (response.data['success'] == true) {
      return Message.fromJson(response.data['data']);
    }

    throw DioException(
      requestOptions: response.requestOptions,
      message: response.data['message'] ?? 'Failed to send image',
    );
  }

  /// Mark conversation as read
  Future<void> markAsRead(String conversationId) async {
    final response = await _apiClient.patch(
      ApiEndpoints.markAsRead(conversationId),
    );

    if (response.data['success'] != true) {
      throw DioException(
        requestOptions: response.requestOptions,
        message: response.data['message'] ?? 'Failed to mark as read',
      );
    }
  }

  /// Get unread count
  Future<int> getUnreadCount() async {
    final response = await _apiClient.get(ApiEndpoints.unreadCount);

    if (response.data['success'] == true) {
      return response.data['data']['count'] as int? ?? 0;
    }

    return 0;
  }

  // ============================================================================
  // ROLE-BASED CHAT GROUPS
  // ============================================================================

  /// Get list of role-based chat groups accessible by user
  Future<List<ChatGroup>> getGroups() async {
    final response = await _apiClient.get(ApiEndpoints.chatGroups);

    if (response.data['success'] == true) {
      final List<dynamic> data = response.data['data'] as List<dynamic>? ?? [];
      return data.map((json) => ChatGroup.fromJson(json)).toList();
    }

    throw DioException(
      requestOptions: response.requestOptions,
      message: response.data['message'] ?? 'Failed to fetch groups',
    );
  }

  /// Join a role-based chat group
  Future<Conversation> joinGroup(String groupId) async {
    final response = await _apiClient.post(
      ApiEndpoints.joinChatGroup(groupId),
    );

    if (response.data['success'] == true) {
      return Conversation.fromJson(response.data['data']);
    }

    throw DioException(
      requestOptions: response.requestOptions,
      message: response.data['message'] ?? 'Failed to join group',
    );
  }

  /// Auto-join all accessible chat groups
  Future<int> autoJoinGroups() async {
    final response = await _apiClient.post(ApiEndpoints.autoJoinChatGroups);

    if (response.data['success'] == true) {
      return response.data['data']['joinedCount'] as int? ?? 0;
    }

    throw DioException(
      requestOptions: response.requestOptions,
      message: response.data['message'] ?? 'Failed to auto-join groups',
    );
  }
}
