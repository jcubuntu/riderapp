import 'package:flutter/material.dart';

import '../../../../shared/models/user_model.dart';

/// A list tile widget for displaying user information
class UserListTile extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onChangeRole;
  final VoidCallback? onChangeStatus;
  final bool showActions;

  const UserListTile({
    super.key,
    required this.user,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onChangeRole,
    this.onChangeStatus,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: _getRoleColor(user.role).withValues(alpha: 0.2),
                backgroundImage: user.profileImageUrl != null
                    ? NetworkImage(user.profileImageUrl!)
                    : null,
                child: user.profileImageUrl == null
                    ? Text(
                        user.fullName.isNotEmpty
                            ? user.fullName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: _getRoleColor(user.role),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),

              // User info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      user.fullName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Phone
                    Row(
                      children: [
                        Icon(
                          Icons.phone_outlined,
                          size: 14,
                          color: colorScheme.outline,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          user.phone,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Role and Status badges
                    Row(
                      children: [
                        _buildRoleBadge(context),
                        const SizedBox(width: 8),
                        _buildStatusBadge(context),
                      ],
                    ),
                  ],
                ),
              ),

              // Actions
              if (showActions)
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: colorScheme.outline,
                  ),
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        onEdit?.call();
                        break;
                      case 'role':
                        onChangeRole?.call();
                        break;
                      case 'status':
                        onChangeStatus?.call();
                        break;
                      case 'delete':
                        onDelete?.call();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    if (onEdit != null)
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined),
                            SizedBox(width: 12),
                            Text('Edit'),
                          ],
                        ),
                      ),
                    if (onChangeRole != null)
                      const PopupMenuItem(
                        value: 'role',
                        child: Row(
                          children: [
                            Icon(Icons.badge_outlined),
                            SizedBox(width: 12),
                            Text('Change Role'),
                          ],
                        ),
                      ),
                    if (onChangeStatus != null)
                      const PopupMenuItem(
                        value: 'status',
                        child: Row(
                          children: [
                            Icon(Icons.toggle_on_outlined),
                            SizedBox(width: 12),
                            Text('Change Status'),
                          ],
                        ),
                      ),
                    if (onDelete != null) ...[
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outlined,
                              color: colorScheme.error,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Delete',
                              style: TextStyle(color: colorScheme.error),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleBadge(BuildContext context) {
    final color = _getRoleColor(user.role);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        user.role.displayName,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    final color = _getStatusColor(user.status);
    final icon = _getStatusIcon(user.status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            user.status.displayName,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.rider:
        return Colors.blue;
      case UserRole.volunteer:
        return Colors.teal;
      case UserRole.police:
        return Colors.indigo;
      case UserRole.commander:
        return Colors.purple;
      case UserRole.admin:
        return Colors.purple;
      case UserRole.superAdmin:
        return Colors.deepOrange;
    }
  }

  Color _getStatusColor(UserStatus status) {
    switch (status) {
      case UserStatus.pending:
        return Colors.orange;
      case UserStatus.approved:
        return Colors.green;
      case UserStatus.rejected:
        return Colors.red;
      case UserStatus.suspended:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(UserStatus status) {
    switch (status) {
      case UserStatus.pending:
        return Icons.hourglass_empty;
      case UserStatus.approved:
        return Icons.check_circle_outline;
      case UserStatus.rejected:
        return Icons.cancel_outlined;
      case UserStatus.suspended:
        return Icons.block_outlined;
    }
  }
}
