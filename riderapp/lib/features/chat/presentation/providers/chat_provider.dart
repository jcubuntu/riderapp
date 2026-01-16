import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/socket/socket_events.dart';
import '../../../../core/socket/socket_provider.dart';
import '../../../../core/socket/socket_service.dart';
import '../../data/datasources/chat_remote_datasource.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/chat_repository.dart';
import 'chat_state.dart';

/// Provider for ChatRepository
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final apiClient = ApiClient();
  final dataSource = ChatRemoteDataSource(apiClient);
  return ChatRepositoryImpl(dataSource);
});

/// Provider for conversations list state
final conversationsProvider =
    StateNotifierProvider<ConversationsNotifier, ConversationsState>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  final socketService = ref.watch(socketServiceProvider);
  return ConversationsNotifier(repository, socketService, ref);
});

/// Provider for chat messages state (per conversation)
final chatMessagesProvider = StateNotifierProvider.family<ChatMessagesNotifier,
    ChatMessagesState, String>((ref, conversationId) {
  final repository = ref.watch(chatRepositoryProvider);
  final socketService = ref.watch(socketServiceProvider);
  return ChatMessagesNotifier(repository, socketService, conversationId);
});

/// Provider for unread count
final unreadMessagesCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(chatRepositoryProvider);
  return repository.getUnreadCount();
});

/// Notifier for conversations list
class ConversationsNotifier extends StateNotifier<ConversationsState> {
  final ChatRepository _repository;
  final SocketService _socketService;
  // ignore: unused_field - Reserved for future use (e.g., invalidating other providers)
  final Ref _ref;

  ConversationsNotifier(this._repository, this._socketService, this._ref)
      : super(const ConversationsInitial()) {
    _setupSocketListeners();
  }

  /// Setup socket event listeners for real-time updates
  void _setupSocketListeners() {
    // Listen for new messages to update conversation list
    _socketService.on(SocketEvents.newMessage, _handleNewMessage);

    // Listen for conversation updates
    _socketService.on(SocketEvents.conversationUpdated, _handleConversationUpdated);

    // Listen for new conversations
    _socketService.on(SocketEvents.newConversation, _handleNewConversation);
  }

  /// Handle incoming new message
  void _handleNewMessage(dynamic data) {
    try {
      final messageData = data as Map<String, dynamic>?;
      if (messageData == null) return;

      final message = Message.fromJson(messageData);
      updateConversation(message.conversationId, message);

      _log('New message received for conversation: ${message.conversationId}');
    } catch (e) {
      _log('Error handling new message: $e');
    }
  }

  /// Handle conversation updated event
  void _handleConversationUpdated(dynamic data) {
    try {
      final updateData = data as Map<String, dynamic>?;
      if (updateData == null) return;

      // Refresh conversation list to get updated data
      loadConversations(refresh: true);
    } catch (e) {
      _log('Error handling conversation update: $e');
    }
  }

  /// Handle new conversation created
  void _handleNewConversation(dynamic data) {
    // Refresh to include new conversation
    loadConversations(refresh: true);
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[ConversationsNotifier] $message');
    }
  }

  /// Load conversations
  Future<void> loadConversations({bool refresh = false}) async {
    if (refresh || state is ConversationsInitial || state is ConversationsError) {
      state = const ConversationsLoading();
    }

    try {
      final result = await _repository.getConversations();

      state = ConversationsLoaded(
        conversations: result.conversations,
        total: result.total,
        page: result.page,
        totalPages: result.totalPages,
      );
    } catch (e) {
      state = ConversationsError(e.toString());
    }
  }

  /// Load more conversations
  Future<void> loadMore() async {
    final currentState = state;
    if (currentState is! ConversationsLoaded ||
        !currentState.hasMore ||
        currentState.isLoadingMore) {
      return;
    }

    state = currentState.copyWith(isLoadingMore: true);

    try {
      final result = await _repository.getConversations(
        page: currentState.page + 1,
      );

      state = ConversationsLoaded(
        conversations: [...currentState.conversations, ...result.conversations],
        total: result.total,
        page: result.page,
        totalPages: result.totalPages,
      );
    } catch (e) {
      state = currentState.copyWith(isLoadingMore: false);
    }
  }

  /// Update conversation in list after new message
  void updateConversation(String conversationId, Message message) {
    final currentState = state;
    if (currentState is ConversationsLoaded) {
      final updatedList = currentState.conversations.map((c) {
        if (c.id == conversationId) {
          return c.copyWith(
            lastMessage: message,
            updatedAt: message.sentAt,
          );
        }
        return c;
      }).toList();

      // Sort by updated time
      updatedList.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      state = currentState.copyWith(conversations: updatedList);
    }
  }

  /// Remove conversation from list
  void removeConversation(String conversationId) {
    final currentState = state;
    if (currentState is ConversationsLoaded) {
      final updatedList = currentState.conversations
          .where((c) => c.id != conversationId)
          .toList();

      state = currentState.copyWith(
        conversations: updatedList,
        total: currentState.total - 1,
      );
    }
  }

  @override
  void dispose() {
    // Remove socket listeners
    _socketService.off(SocketEvents.newMessage, _handleNewMessage);
    _socketService.off(SocketEvents.conversationUpdated, _handleConversationUpdated);
    _socketService.off(SocketEvents.newConversation, _handleNewConversation);
    super.dispose();
  }
}

/// Notifier for chat messages
class ChatMessagesNotifier extends StateNotifier<ChatMessagesState> {
  final ChatRepository _repository;
  final SocketService _socketService;
  final String _conversationId;
  Timer? _typingTimer;
  bool _isTyping = false;

  ChatMessagesNotifier(this._repository, this._socketService, this._conversationId)
      : super(const ChatMessagesInitial()) {
    _setupSocketListeners();
    _joinConversation();
    loadMessages();
  }

  /// Setup socket event listeners
  void _setupSocketListeners() {
    // Listen for new messages in this conversation
    _socketService.on(SocketEvents.newMessage, _handleNewMessage);

    // Listen for read receipts
    _socketService.on(SocketEvents.messageReadReceipt, _handleReadReceipt);
  }

  /// Join the conversation room for real-time updates
  void _joinConversation() {
    _socketService.joinConversation(_conversationId);
  }

  /// Leave the conversation room
  void _leaveConversation() {
    _socketService.leaveConversation(_conversationId);
  }

  /// Handle incoming new message
  void _handleNewMessage(dynamic data) {
    try {
      final messageData = data as Map<String, dynamic>?;
      if (messageData == null) return;

      final message = Message.fromJson(messageData);

      // Only process if for this conversation
      if (message.conversationId != _conversationId) return;

      // Add message if not already exists
      addReceivedMessage(message);

      // Mark as read since user is viewing this conversation
      _socketService.markMessagesRead(_conversationId);

      _log('New message received: ${message.id}');
    } catch (e) {
      _log('Error handling new message: $e');
    }
  }

  /// Handle read receipt
  void _handleReadReceipt(dynamic data) {
    try {
      final receiptData = data as Map<String, dynamic>?;
      if (receiptData == null) return;

      final conversationId = receiptData['conversationId'] as String?;
      if (conversationId != _conversationId) return;

      // Update message read status
      final currentState = state;
      if (currentState is ChatMessagesLoaded) {
        final updatedMessages = currentState.messages.map((m) {
          return m.copyWith(isRead: true);
        }).toList();

        state = currentState.copyWith(messages: updatedMessages);
      }
    } catch (e) {
      _log('Error handling read receipt: $e');
    }
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[ChatMessagesNotifier] $message');
    }
  }

  /// Load messages
  Future<void> loadMessages() async {
    state = const ChatMessagesLoading();

    try {
      final conversation = await _repository.getConversationById(_conversationId);
      final result = await _repository.getMessages(_conversationId);

      // Mark as read
      await _repository.markAsRead(_conversationId);

      state = ChatMessagesLoaded(
        conversation: conversation,
        messages: result.messages.reversed.toList(), // Oldest first for chat
        total: result.total,
        page: result.page,
        totalPages: result.totalPages,
      );
    } catch (e) {
      state = ChatMessagesError(e.toString());
    }
  }

  /// Load older messages
  Future<void> loadMore() async {
    final currentState = state;
    if (currentState is! ChatMessagesLoaded ||
        !currentState.hasMore ||
        currentState.isLoadingMore) {
      return;
    }

    state = currentState.copyWith(isLoadingMore: true);

    try {
      final result = await _repository.getMessages(
        _conversationId,
        page: currentState.page + 1,
      );

      state = currentState.copyWith(
        messages: [...result.messages.reversed, ...currentState.messages],
        page: result.page,
        totalPages: result.totalPages,
        isLoadingMore: false,
      );
    } catch (e) {
      state = currentState.copyWith(isLoadingMore: false);
    }
  }

  /// Send a message
  Future<void> sendMessage(String content) async {
    final currentState = state;
    if (currentState is! ChatMessagesLoaded || currentState.isSending) {
      return;
    }

    if (content.trim().isEmpty) return;

    // Stop typing indicator before sending
    stopTyping();

    state = currentState.copyWith(isSending: true);

    try {
      final message = await _repository.sendMessage(
        _conversationId,
        content: content.trim(),
      );

      state = currentState.copyWith(
        messages: [...currentState.messages, message],
        total: currentState.total + 1,
        isSending: false,
      );

      // Also emit via socket for real-time delivery
      _socketService.sendMessage(
        conversationId: _conversationId,
        content: content.trim(),
      );
    } catch (e) {
      state = currentState.copyWith(isSending: false);
      rethrow;
    }
  }

  /// Send an image message
  Future<void> sendImageMessage(File imageFile, {String? caption}) async {
    final currentState = state;
    if (currentState is! ChatMessagesLoaded ||
        currentState.isSending ||
        currentState.isUploading) {
      return;
    }

    // Stop typing indicator before sending
    stopTyping();

    state = currentState.copyWith(
      isUploading: true,
      uploadProgress: 0.0,
    );

    try {
      final message = await _repository.sendImageMessage(
        _conversationId,
        imageFile: imageFile,
        caption: caption,
        onProgress: (progress) {
          // Update upload progress
          final currentState = state;
          if (currentState is ChatMessagesLoaded) {
            state = currentState.copyWith(uploadProgress: progress);
          }
        },
      );

      // Get the latest state after upload
      final latestState = state;
      if (latestState is ChatMessagesLoaded) {
        state = latestState.copyWith(
          messages: [...latestState.messages, message],
          total: latestState.total + 1,
          isUploading: false,
          uploadProgress: 0.0,
        );
      }

      _log('Image message sent: ${message.id}');
    } catch (e) {
      _log('Failed to send image: $e');
      final latestState = state;
      if (latestState is ChatMessagesLoaded) {
        state = latestState.copyWith(
          isUploading: false,
          uploadProgress: 0.0,
        );
      }
      rethrow;
    }
  }

  /// Start typing indicator
  void startTyping() {
    if (_isTyping) {
      // Reset timer
      _typingTimer?.cancel();
    } else {
      _isTyping = true;
      _socketService.startTyping(_conversationId);
    }

    // Auto-stop typing after 3 seconds of no input
    _typingTimer = Timer(const Duration(seconds: 3), () {
      stopTyping();
    });
  }

  /// Stop typing indicator
  void stopTyping() {
    if (_isTyping) {
      _isTyping = false;
      _typingTimer?.cancel();
      _typingTimer = null;
      _socketService.stopTyping(_conversationId);
    }
  }

  /// Called when user is typing (debounced)
  void onUserTyping() {
    startTyping();
  }

  /// Add received message (from socket)
  void addReceivedMessage(Message message) {
    final currentState = state;
    if (currentState is ChatMessagesLoaded) {
      // Check if message already exists
      if (currentState.messages.any((m) => m.id == message.id)) {
        return;
      }

      state = currentState.copyWith(
        messages: [...currentState.messages, message],
        total: currentState.total + 1,
      );
    }
  }

  @override
  void dispose() {
    // Stop typing if active
    stopTyping();

    // Leave conversation room
    _leaveConversation();

    // Remove socket listeners
    _socketService.off(SocketEvents.newMessage, _handleNewMessage);
    _socketService.off(SocketEvents.messageReadReceipt, _handleReadReceipt);

    super.dispose();
  }
}
