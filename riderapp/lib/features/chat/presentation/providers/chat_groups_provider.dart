import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/chat_group.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/repositories/chat_repository.dart';
import 'chat_provider.dart';

// =============================================================================
// STATE CLASSES
// =============================================================================

/// Base state for chat groups list
sealed class ChatGroupsState extends Equatable {
  const ChatGroupsState();

  @override
  List<Object?> get props => [];
}

class ChatGroupsInitial extends ChatGroupsState {
  const ChatGroupsInitial();
}

class ChatGroupsLoading extends ChatGroupsState {
  const ChatGroupsLoading();
}

class ChatGroupsLoaded extends ChatGroupsState {
  final List<ChatGroup> groups;
  final String? joiningGroupId;

  const ChatGroupsLoaded({
    required this.groups,
    this.joiningGroupId,
  });

  bool get isJoining => joiningGroupId != null;

  ChatGroupsLoaded copyWith({
    List<ChatGroup>? groups,
    String? joiningGroupId,
    bool clearJoining = false,
  }) {
    return ChatGroupsLoaded(
      groups: groups ?? this.groups,
      joiningGroupId: clearJoining ? null : (joiningGroupId ?? this.joiningGroupId),
    );
  }

  @override
  List<Object?> get props => [groups, joiningGroupId];
}

class ChatGroupsError extends ChatGroupsState {
  final String message;

  const ChatGroupsError(this.message);

  @override
  List<Object?> get props => [message];
}

// =============================================================================
// PROVIDERS
// =============================================================================

/// Provider for chat groups state
final chatGroupsProvider =
    StateNotifierProvider<ChatGroupsNotifier, ChatGroupsState>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  return ChatGroupsNotifier(repository);
});

// =============================================================================
// NOTIFIER
// =============================================================================

/// Notifier for managing chat groups state
class ChatGroupsNotifier extends StateNotifier<ChatGroupsState> {
  final ChatRepository _repository;

  ChatGroupsNotifier(this._repository) : super(const ChatGroupsInitial());

  /// Load available chat groups
  Future<void> loadGroups() async {
    state = const ChatGroupsLoading();

    try {
      final groups = await _repository.getGroups();
      state = ChatGroupsLoaded(groups: groups);
    } catch (e) {
      state = ChatGroupsError(e.toString());
    }
  }

  /// Join a specific group and return the conversation
  Future<Conversation?> joinGroup(String groupId) async {
    final currentState = state;
    if (currentState is! ChatGroupsLoaded) return null;

    // Set joining state
    state = currentState.copyWith(joiningGroupId: groupId);

    try {
      final conversation = await _repository.joinGroup(groupId);

      // Update group as joined
      final updatedGroups = currentState.groups.map((g) {
        if (g.id == groupId) {
          return g.copyWith(isJoined: true);
        }
        return g;
      }).toList();

      state = ChatGroupsLoaded(groups: updatedGroups);

      return conversation;
    } catch (e) {
      // Reset to previous state on error
      state = currentState.copyWith(clearJoining: true);
      rethrow;
    }
  }

  /// Refresh groups list
  Future<void> refresh() async {
    await loadGroups();
  }
}
