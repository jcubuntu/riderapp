import 'package:equatable/equatable.dart';

import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';

/// Base state for conversations list
sealed class ConversationsState extends Equatable {
  const ConversationsState();

  @override
  List<Object?> get props => [];
}

class ConversationsInitial extends ConversationsState {
  const ConversationsInitial();
}

class ConversationsLoading extends ConversationsState {
  const ConversationsLoading();
}

class ConversationsLoaded extends ConversationsState {
  final List<Conversation> conversations;
  final int total;
  final int page;
  final int totalPages;
  final bool isLoadingMore;

  const ConversationsLoaded({
    required this.conversations,
    required this.total,
    required this.page,
    required this.totalPages,
    this.isLoadingMore = false,
  });

  bool get hasMore => page < totalPages;

  ConversationsLoaded copyWith({
    List<Conversation>? conversations,
    int? total,
    int? page,
    int? totalPages,
    bool? isLoadingMore,
  }) {
    return ConversationsLoaded(
      conversations: conversations ?? this.conversations,
      total: total ?? this.total,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [conversations, total, page, totalPages, isLoadingMore];
}

class ConversationsError extends ConversationsState {
  final String message;

  const ConversationsError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Base state for chat messages
sealed class ChatMessagesState extends Equatable {
  const ChatMessagesState();

  @override
  List<Object?> get props => [];
}

class ChatMessagesInitial extends ChatMessagesState {
  const ChatMessagesInitial();
}

class ChatMessagesLoading extends ChatMessagesState {
  const ChatMessagesLoading();
}

class ChatMessagesLoaded extends ChatMessagesState {
  final Conversation conversation;
  final List<Message> messages;
  final int total;
  final int page;
  final int totalPages;
  final bool isLoadingMore;
  final bool isSending;
  final bool isUploading;
  final double uploadProgress;

  const ChatMessagesLoaded({
    required this.conversation,
    required this.messages,
    required this.total,
    required this.page,
    required this.totalPages,
    this.isLoadingMore = false,
    this.isSending = false,
    this.isUploading = false,
    this.uploadProgress = 0.0,
  });

  bool get hasMore => page < totalPages;

  ChatMessagesLoaded copyWith({
    Conversation? conversation,
    List<Message>? messages,
    int? total,
    int? page,
    int? totalPages,
    bool? isLoadingMore,
    bool? isSending,
    bool? isUploading,
    double? uploadProgress,
  }) {
    return ChatMessagesLoaded(
      conversation: conversation ?? this.conversation,
      messages: messages ?? this.messages,
      total: total ?? this.total,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isSending: isSending ?? this.isSending,
      isUploading: isUploading ?? this.isUploading,
      uploadProgress: uploadProgress ?? this.uploadProgress,
    );
  }

  @override
  List<Object?> get props => [
        conversation,
        messages,
        total,
        page,
        totalPages,
        isLoadingMore,
        isSending,
        isUploading,
        uploadProgress,
      ];
}

class ChatMessagesError extends ChatMessagesState {
  final String message;

  const ChatMessagesError(this.message);

  @override
  List<Object?> get props => [message];
}
