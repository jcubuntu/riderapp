import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/providers/auth_state.dart';
import '../providers/chat_provider.dart';
import '../providers/chat_state.dart';
import '../widgets/conversation_tile.dart';

/// Screen for displaying list of conversations
class ConversationsListScreen extends ConsumerStatefulWidget {
  const ConversationsListScreen({super.key});

  @override
  ConsumerState<ConversationsListScreen> createState() =>
      _ConversationsListScreenState();
}

class _ConversationsListScreenState
    extends ConsumerState<ConversationsListScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(conversationsProvider.notifier).loadConversations();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(conversationsProvider.notifier).loadMore();
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
    final state = ref.watch(conversationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('chat.conversations'.tr()),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref
              .read(conversationsProvider.notifier)
              .loadConversations(refresh: true);
        },
        child: _buildBody(state),
      ),
    );
  }

  Widget _buildBody(ConversationsState state) {
    final currentUserId = _getCurrentUserId();

    return switch (state) {
      ConversationsInitial() || ConversationsLoading() => const Center(
          child: CircularProgressIndicator(),
        ),
      ConversationsError(message: final message) => Center(
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
                      .read(conversationsProvider.notifier)
                      .loadConversations(refresh: true);
                },
                icon: const Icon(Icons.refresh),
                label: Text('common.retry'.tr()),
              ),
            ],
          ),
        ),
      ConversationsLoaded(
        conversations: final conversations,
        isLoadingMore: final isLoadingMore,
      ) =>
        conversations.isEmpty
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
                      'chat.noConversations'.tr(),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'chat.startConversation'.tr(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: conversations.length + (isLoadingMore ? 1 : 0),
                separatorBuilder: (context, index) => const Divider(
                  height: 1,
                  indent: 72,
                ),
                itemBuilder: (context, index) {
                  if (index == conversations.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final conversation = conversations[index];
                  return ConversationTile(
                    conversation: conversation,
                    currentUserId: currentUserId,
                    onTap: () {
                      context.push('/chat/${conversation.id}');
                    },
                    onLongPress: () {
                      _showConversationOptions(context, conversation);
                    },
                  );
                },
              ),
    };
  }

  void _showConversationOptions(
      BuildContext context, dynamic conversation) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: Text(
                'chat.deleteConversation'.tr(),
                style: const TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(conversation);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(dynamic conversation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('chat.deleteConversation'.tr()),
        content: Text('chat.deleteConfirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref
                  .read(conversationsProvider.notifier)
                  .removeConversation(conversation.id);
            },
            child: Text(
              'common.delete'.tr(),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
