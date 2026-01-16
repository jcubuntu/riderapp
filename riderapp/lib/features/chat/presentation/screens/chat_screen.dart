import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/providers/auth_state.dart';
import '../providers/chat_provider.dart';
import '../providers/chat_state.dart';
import '../widgets/chat_input.dart';
import '../widgets/message_bubble.dart';

/// Screen for chat messages
class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;

  const ChatScreen({
    super.key,
    required this.conversationId,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Load more when scrolling to top (older messages)
    if (_scrollController.position.pixels <=
        _scrollController.position.minScrollExtent + 100) {
      ref.read(chatMessagesProvider(widget.conversationId).notifier).loadMore();
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  String _getCurrentUserId() {
    final authState = ref.read(authProvider);
    if (authState is AuthAuthenticated) {
      return authState.user.id;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatMessagesProvider(widget.conversationId));
    final currentUserId = _getCurrentUserId();

    return Scaffold(
      appBar: AppBar(
        title: _buildTitle(state, currentUserId),
      ),
      body: Column(
        children: [
          Expanded(child: _buildBody(state, currentUserId)),
          _buildInput(state),
        ],
      ),
    );
  }

  Widget _buildTitle(ChatMessagesState state, String currentUserId) {
    if (state is ChatMessagesLoaded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            state.conversation.getDisplayName(currentUserId),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(
            '${state.conversation.participants.length} participants',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      );
    }
    return Text('chat.title'.tr());
  }

  Widget _buildBody(ChatMessagesState state, String currentUserId) {
    return switch (state) {
      ChatMessagesInitial() || ChatMessagesLoading() => const Center(
          child: CircularProgressIndicator(),
        ),
      ChatMessagesError(message: final message) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'errors.unknown'.tr(),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  ref
                      .read(chatMessagesProvider(widget.conversationId).notifier)
                      .loadMessages();
                },
                icon: const Icon(Icons.refresh),
                label: Text('common.retry'.tr()),
              ),
            ],
          ),
        ),
      ChatMessagesLoaded(
        messages: final messages,
        isLoadingMore: final isLoadingMore,
      ) =>
        messages.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'chat.noMessages'.tr(),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              )
            : Stack(
                children: [
                  ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(bottom: 8),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isFromMe = message.sender.id == currentUserId;

                      // Show time if first message or different day
                      final showDate = index == 0 ||
                          !_isSameDay(
                            messages[index - 1].sentAt,
                            message.sentAt,
                          );

                      return Column(
                        children: [
                          if (showDate) _buildDateHeader(message.sentAt),
                          MessageBubble(
                            message: message,
                            isFromMe: isFromMe,
                            showAvatar: !isFromMe,
                          ),
                        ],
                      );
                    },
                  ),
                  if (isLoadingMore)
                    Positioned(
                      top: 8,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
    };
  }

  Widget _buildDateHeader(DateTime date) {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    String text;
    if (_isSameDay(date, now)) {
      text = 'chat.today'.tr();
    } else if (_isSameDay(date, yesterday)) {
      text = 'chat.yesterday'.tr();
    } else {
      text = DateFormat('MMMM d, y').format(date);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildInput(ChatMessagesState state) {
    final isSending = state is ChatMessagesLoaded && state.isSending;
    final isUploading = state is ChatMessagesLoaded && state.isUploading;
    final uploadProgress =
        state is ChatMessagesLoaded ? state.uploadProgress : 0.0;

    return ChatInput(
      isSending: isSending,
      isUploading: isUploading,
      uploadProgress: uploadProgress,
      onSend: (content) async {
        await ref
            .read(chatMessagesProvider(widget.conversationId).notifier)
            .sendMessage(content);

        // Scroll to bottom after sending
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      },
      onSendImage: (File file, String? caption) async {
        try {
          await ref
              .read(chatMessagesProvider(widget.conversationId).notifier)
              .sendImageMessage(file, caption: caption);

          // Scroll to bottom after sending
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('chat.sendImageFailed'.tr()),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        }
      },
    );
  }
}
