import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/providers/auth_state.dart';
import '../providers/chat_groups_provider.dart';
import '../widgets/chat_group_tile.dart';

/// Screen for displaying list of chat groups
class ConversationsListScreen extends ConsumerStatefulWidget {
  const ConversationsListScreen({super.key});

  @override
  ConsumerState<ConversationsListScreen> createState() =>
      _ConversationsListScreenState();
}

class _ConversationsListScreenState
    extends ConsumerState<ConversationsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatGroupsProvider.notifier).loadGroups();
    });
  }

  UserRole _getCurrentUserRole() {
    final authState = ref.read(authProvider);
    if (authState is AuthAuthenticated) {
      return authState.user.role;
    }
    return UserRole.rider;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatGroupsProvider);
    final currentUserRole = _getCurrentUserRole();

    return Scaffold(
      appBar: AppBar(
        title: Text('chat.groups'.tr()),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(chatGroupsProvider.notifier).refresh();
        },
        child: _buildGroupsBody(state, currentUserRole),
      ),
    );
  }

  Widget _buildGroupsBody(ChatGroupsState state, UserRole currentUserRole) {
    return switch (state) {
      ChatGroupsInitial() || ChatGroupsLoading() => const Center(
          child: CircularProgressIndicator(),
        ),
      ChatGroupsError(message: final message) => Center(
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
                  ref.read(chatGroupsProvider.notifier).loadGroups();
                },
                icon: const Icon(Icons.refresh),
                label: Text('common.retry'.tr()),
              ),
            ],
          ),
        ),
      ChatGroupsLoaded(groups: final groups, joiningGroupId: final joiningId) =>
        groups.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.group_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'chat.noGroups'.tr(),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  final group = groups[index];
                  return ChatGroupTile(
                    group: group,
                    currentUserRole: currentUserRole,
                    isJoining: joiningId == group.id,
                    onJoin: () => _joinGroup(group.id),
                    onTap: group.isJoined
                        ? () => context.push('/chat/${group.id}')
                        : null,
                  );
                },
              ),
    };
  }

  Future<void> _joinGroup(String groupId) async {
    try {
      final conversation = await ref
          .read(chatGroupsProvider.notifier)
          .joinGroup(groupId);

      if (conversation != null && mounted) {
        // Navigate to the group chat
        context.push('/chat/${conversation.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('chat.joinError'.tr()),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
