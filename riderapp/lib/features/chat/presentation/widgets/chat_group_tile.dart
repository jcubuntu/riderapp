import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/models/user_model.dart';
import '../../domain/entities/chat_group.dart';

/// Widget for displaying a chat group in the list
class ChatGroupTile extends StatelessWidget {
  final ChatGroup group;
  final UserRole currentUserRole;
  final bool isJoining;
  final VoidCallback? onJoin;
  final VoidCallback? onTap;

  const ChatGroupTile({
    super.key,
    required this.group,
    required this.currentUserRole,
    this.isJoining = false,
    this.onJoin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final canAccess = group.canAccess(currentUserRole);
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: canAccess ? (group.isJoined ? onTap : onJoin) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Group icon
              _buildGroupIcon(context, canAccess),
              const SizedBox(width: 16),

              // Group info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      group.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: canAccess ? null : theme.disabledColor,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Access description
                    Text(
                      _getAccessDescription(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: canAccess
                            ? theme.textTheme.bodySmall?.color
                            : theme.disabledColor,
                      ),
                    ),

                    // Member count
                    const SizedBox(height: 4),
                    Text(
                      'chat.members'.tr(args: [group.participantCount.toString()]),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  ],
                ),
              ),

              // Action button or status
              _buildActionButton(context, canAccess),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupIcon(BuildContext context, bool canAccess) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: canAccess
            ? _getRoleColor().withValues(alpha: 0.1)
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          group.roleIcon,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: canAccess ? _getRoleColor() : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, bool canAccess) {
    if (!canAccess) {
      return Icon(
        Icons.lock_outline,
        color: Theme.of(context).disabledColor,
      );
    }

    if (group.isJoined) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          'chat.joined'.tr(),
          style: const TextStyle(
            color: AppColors.success,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
      );
    }

    if (isJoining) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return ElevatedButton(
      onPressed: onJoin,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text('chat.joinGroup'.tr()),
    );
  }

  String _getAccessDescription() {
    switch (group.minimumRole) {
      case 'rider':
        return 'chat.groupAccess.rider'.tr();
      case 'volunteer':
        return 'chat.groupAccess.volunteer'.tr();
      case 'police':
        return 'chat.groupAccess.police'.tr();
      case 'commander':
        return 'chat.groupAccess.commander'.tr();
      case 'admin':
        return 'chat.groupAccess.admin'.tr();
      default:
        return 'chat.groupAccess.rider'.tr();
    }
  }

  Color _getRoleColor() {
    switch (group.minimumRole) {
      case 'rider':
        return AppColors.info;
      case 'volunteer':
        return AppColors.secondary;
      case 'police':
        return AppColors.warning;
      case 'commander':
        return AppColors.primary;
      case 'admin':
        return AppColors.error;
      default:
        return AppColors.info;
    }
  }
}
