import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/user_model.dart';
import '../providers/admin_provider.dart';
import '../providers/admin_state.dart';
import '../widgets/user_list_tile.dart';

/// Screen for managing all users (admin+)
class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() =>
      _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  final _searchController = TextEditingController();
  UserRole? _selectedRole;
  UserStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    // Fetch users on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userListProvider.notifier).fetchUsers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final userListState = ref.watch(userListProvider);
    final userActionState = ref.watch(userActionProvider);

    // Listen for action results
    ref.listen<UserActionState>(userActionProvider, (previous, next) {
      if (next is UserActionSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: Colors.green,
          ),
        );
        ref.read(userListProvider.notifier).refresh();
      } else if (next is UserActionError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: colorScheme.error,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(userListProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filters
          _buildSearchAndFilters(context),

          // User list
          Expanded(
            child: _buildUserList(context, userListState, userActionState),
          ),

          // Pagination
          if (userListState is UserListLoaded)
            _buildPagination(context, userListState),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by name or phone...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        ref.read(userListProvider.notifier).search('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            ),
            onSubmitted: (value) {
              ref.read(userListProvider.notifier).search(value);
            },
          ),
          const SizedBox(height: 12),

          // Filter chips
          Row(
            children: [
              // Role filter
              Expanded(
                child: DropdownButtonFormField<UserRole?>(
                  initialValue: _selectedRole,
                  decoration: InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All Roles'),
                    ),
                    ...UserRole.values.map((role) {
                      return DropdownMenuItem(
                        value: role,
                        child: Text(role.displayName),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedRole = value;
                    });
                    ref.read(userListProvider.notifier).filterByRole(value);
                  },
                ),
              ),
              const SizedBox(width: 12),

              // Status filter
              Expanded(
                child: DropdownButtonFormField<UserStatus?>(
                  initialValue: _selectedStatus,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All Status'),
                    ),
                    ...UserStatus.values.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(status.displayName),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value;
                    });
                    ref.read(userListProvider.notifier).filterByStatus(value);
                  },
                ),
              ),
            ],
          ),

          // Clear filters button
          if (_selectedRole != null ||
              _selectedStatus != null ||
              _searchController.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedRole = null;
                    _selectedStatus = null;
                    _searchController.clear();
                  });
                  ref.read(userListProvider.notifier).clearFilters();
                },
                icon: const Icon(Icons.clear_all, size: 18),
                label: const Text('Clear Filters'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUserList(
    BuildContext context,
    UserListState state,
    UserActionState actionState,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (state) {
      case UserListInitial():
      case UserListLoading():
        return const Center(child: CircularProgressIndicator());

      case UserListError(message: final message):
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
                  ref.read(userListProvider.notifier).refresh();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        );

      case UserListLoaded(paginatedUsers: final paginatedUsers):
        if (paginatedUsers.users.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 64,
                  color: colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'No users found',
                  style: TextStyle(color: colorScheme.outline),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.read(userListProvider.notifier).refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: paginatedUsers.users.length,
            itemBuilder: (context, index) {
              final user = paginatedUsers.users[index];
              return UserListTile(
                user: user,
                onTap: () => _showUserDetails(context, user),
                onEdit: () => _showEditUserDialog(context, user),
                onChangeRole: () => _showChangeRoleDialog(context, user),
                onChangeStatus: () => _showChangeStatusDialog(context, user),
                onDelete: () => _showDeleteConfirmation(context, user),
              );
            },
          ),
        );
    }
  }

  Widget _buildPagination(BuildContext context, UserListLoaded state) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final paginatedUsers = state.paginatedUsers;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing ${paginatedUsers.users.length} of ${paginatedUsers.total} users',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.outline,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: paginatedUsers.hasPreviousPage
                    ? () => ref.read(userListProvider.notifier).previousPage()
                    : null,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${paginatedUsers.page} / ${paginatedUsers.totalPages}',
                  style: TextStyle(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: paginatedUsers.hasNextPage
                    ? () => ref.read(userListProvider.notifier).nextPage()
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showUserDetails(BuildContext context, UserModel user) {
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
                  backgroundImage: user.profileImageUrl != null
                      ? NetworkImage(user.profileImageUrl!)
                      : null,
                  child: user.profileImageUrl == null
                      ? Text(
                          user.fullName.isNotEmpty
                              ? user.fullName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(fontSize: 32),
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
              const SizedBox(height: 24),

              // Details
              _buildDetailRow(context, 'Phone', user.phone, Icons.phone),
              _buildDetailRow(
                  context, 'Role', user.role.displayName, Icons.badge),
              _buildDetailRow(
                  context, 'Status', user.status.displayName, Icons.toggle_on),
              if (user.idCardNumber != null)
                _buildDetailRow(
                    context, 'ID Card', user.idCardNumber!, Icons.credit_card),
              if (user.affiliation != null)
                _buildDetailRow(
                    context, 'Affiliation', user.affiliation!, Icons.business),
              if (user.address != null)
                _buildDetailRow(
                    context, 'Address', user.address!, Icons.location_on),
              _buildDetailRow(
                context,
                'Registered',
                user.createdAt.toString().substring(0, 16),
                Icons.calendar_today,
              ),
              if (user.lastLoginAt != null)
                _buildDetailRow(
                  context,
                  'Last Login',
                  user.lastLoginAt!.toString().substring(0, 16),
                  Icons.login,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
      BuildContext context, String label, String value, IconData icon) {
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

  void _showEditUserDialog(BuildContext context, UserModel user) {
    final nameController = TextEditingController(text: user.fullName);
    final phoneController = TextEditingController(text: user.phone);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone',
                border: OutlineInputBorder(),
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
              ref.read(userActionProvider.notifier).updateUser(
                user.id,
                {
                  'full_name': nameController.text,
                  'phone': phoneController.text,
                },
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showChangeRoleDialog(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Role'),
        content: RadioGroup<UserRole>(
          groupValue: user.role,
          onChanged: (value) {
            Navigator.pop(context);
            if (value != null && value != user.role) {
              ref.read(userActionProvider.notifier).changeUserRole(
                    user.id,
                    value,
                  );
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: UserRole.values.map((role) {
              return RadioListTile<UserRole>(
                title: Text(role.displayName),
                value: role,
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showChangeStatusDialog(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Status'),
        content: RadioGroup<UserStatus>(
          groupValue: user.status,
          onChanged: (value) {
            Navigator.pop(context);
            if (value != null && value != user.status) {
              ref.read(userActionProvider.notifier).updateUserStatus(
                    user.id,
                    value,
                  );
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: UserStatus.values.map((status) {
              return RadioListTile<UserStatus>(
                title: Text(status.displayName),
                value: status,
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, UserModel user) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
          'Are you sure you want to delete ${user.fullName}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(userActionProvider.notifier).deleteUser(user.id);
            },
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
