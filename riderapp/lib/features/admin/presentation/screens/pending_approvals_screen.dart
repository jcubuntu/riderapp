import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/user_model.dart';
import '../../domain/entities/pending_user.dart';
import '../providers/admin_provider.dart';
import '../providers/admin_state.dart';
import '../widgets/approval_card.dart';

/// Screen for managing pending user approvals (police+)
class PendingApprovalsScreen extends ConsumerStatefulWidget {
  const PendingApprovalsScreen({super.key});

  @override
  ConsumerState<PendingApprovalsScreen> createState() =>
      _PendingApprovalsScreenState();
}

class _PendingApprovalsScreenState
    extends ConsumerState<PendingApprovalsScreen> {
  final Set<String> _processingUsers = {};

  @override
  void initState() {
    super.initState();
    // Fetch pending users on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pendingApprovalsProvider.notifier).fetchPendingUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final pendingState = ref.watch(pendingApprovalsProvider);

    // Listen for action results
    ref.listen<UserActionState>(userActionProvider, (previous, next) {
      if (next is UserActionSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _processingUsers.clear();
        });
      } else if (next is UserActionError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: colorScheme.error,
          ),
        );
        setState(() {
          _processingUsers.clear();
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Approvals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(pendingApprovalsProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: _buildBody(context, pendingState),
    );
  }

  Widget _buildBody(BuildContext context, PendingApprovalsState state) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (state) {
      case PendingApprovalsInitial():
      case PendingApprovalsLoading():
        return const Center(child: CircularProgressIndicator());

      case PendingApprovalsError(message: final message):
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: TextStyle(color: colorScheme.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  ref.read(pendingApprovalsProvider.notifier).refresh();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        );

      case PendingApprovalsLoaded(pendingUsers: final pendingUsers):
        if (pendingUsers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 80,
                  color: Colors.green.withValues(alpha: 0.7),
                ),
                const SizedBox(height: 16),
                Text(
                  'All caught up!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'No pending approvals at the moment.',
                  style: TextStyle(color: colorScheme.outline),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.read(pendingApprovalsProvider.notifier).refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: pendingUsers.length,
            itemBuilder: (context, index) {
              final user = pendingUsers[index];
              final isProcessing = _processingUsers.contains(user.id);

              return ApprovalCard(
                user: user,
                isLoading: isProcessing,
                onApprove: () => _showApproveDialog(context, user),
                onReject: () => _showRejectDialog(context, user),
                onTap: () => _showUserDetails(context, user),
              );
            },
          ),
        );
    }
  }

  void _showApproveDialog(BuildContext context, PendingUser user) {
    UserRole? selectedRole = user.role;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Approve User'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Approve ${user.fullName}?'),
              const SizedBox(height: 16),
              const Text(
                'Assign Role:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              RadioGroup<UserRole>(
                groupValue: selectedRole,
                onChanged: (value) {
                  setDialogState(() {
                    selectedRole = value;
                  });
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: UserRole.values
                      .where((r) => r != UserRole.superAdmin) // Only super_admin can create super_admin
                      .map((role) {
                    return RadioListTile<UserRole>(
                      title: Text(role.displayName),
                      value: role,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                _approveUser(user.id, selectedRole);
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text('Approve'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRejectDialog(BuildContext context, PendingUser user) {
    final reasonController = TextEditingController();
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reject ${user.fullName}?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                hintText: 'Enter rejection reason...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _rejectUser(user.id, reasonController.text);
            },
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _approveUser(String userId, UserRole? role) async {
    setState(() {
      _processingUsers.add(userId);
    });

    final success = await ref.read(userActionProvider.notifier).approveUser(
          userId,
          assignRole: role,
        );

    if (success) {
      ref.read(pendingApprovalsProvider.notifier).removeUser(userId);
    }
  }

  void _rejectUser(String userId, String? reason) async {
    setState(() {
      _processingUsers.add(userId);
    });

    final success = await ref.read(userActionProvider.notifier).rejectUser(
          userId,
          reason: reason?.isNotEmpty == true ? reason : null,
        );

    if (success) {
      ref.read(pendingApprovalsProvider.notifier).removeUser(userId);
    }
  }

  void _showUserDetails(BuildContext context, PendingUser user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // User info
              Center(
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: Colors.orange.withValues(alpha: 0.2),
                  backgroundImage: user.profileImageUrl != null
                      ? NetworkImage(user.profileImageUrl!)
                      : null,
                  child: user.profileImageUrl == null
                      ? Text(
                          user.fullName.isNotEmpty
                              ? user.fullName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 32,
                            color: Colors.orange,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  user.fullName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Pending Approval',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Details
              _buildDetailRow(context, 'Phone', user.phone, Icons.phone),
              _buildDetailRow(
                context,
                'Requested Role',
                user.role.displayName,
                Icons.badge,
              ),
              if (user.idCardNumber != null)
                _buildDetailRow(
                  context,
                  'ID Card',
                  user.idCardNumber!,
                  Icons.credit_card,
                ),
              if (user.affiliation != null)
                _buildDetailRow(
                  context,
                  'Affiliation',
                  user.affiliation!,
                  Icons.business,
                ),
              if (user.address != null)
                _buildDetailRow(
                  context,
                  'Address',
                  user.address!,
                  Icons.location_on,
                ),
              _buildDetailRow(
                context,
                'Registered',
                user.createdAt.toString().substring(0, 16),
                Icons.calendar_today,
              ),

              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showRejectDialog(context, user);
                      },
                      icon: const Icon(Icons.close),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showApproveDialog(context, user);
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Approve'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.outline),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
