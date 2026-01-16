import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/announcement.dart';
import '../providers/announcements_provider.dart';
import '../providers/announcements_state.dart';

/// Screen for displaying announcement detail
class AnnouncementDetailScreen extends ConsumerWidget {
  final String announcementId;

  const AnnouncementDetailScreen({
    super.key,
    required this.announcementId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(announcementDetailProvider(announcementId));

    return Scaffold(
      appBar: AppBar(
        title: Text('announcements.detail'.tr()),
      ),
      body: _buildBody(context, ref, state),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, AnnouncementDetailState state) {
    return switch (state) {
      AnnouncementDetailInitial() ||
      AnnouncementDetailLoading() =>
        const Center(child: CircularProgressIndicator()),
      AnnouncementDetailError(message: final message) => Center(
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
                  ref.read(announcementDetailProvider(announcementId).notifier).loadAnnouncement();
                },
                icon: const Icon(Icons.refresh),
                label: Text('common.retry'.tr()),
              ),
            ],
          ),
        ),
      AnnouncementDetailLoaded(announcement: final announcement) =>
        _buildContent(context, announcement),
    };
  }

  Widget _buildContent(BuildContext context, Announcement announcement) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Priority and category badges
          Row(
            children: [
              _buildPriorityBadge(context, announcement.priority),
              const SizedBox(width: 8),
              _buildCategoryBadge(context, announcement.category),
            ],
          ),

          const SizedBox(height: 16),

          // Title
          Text(
            announcement.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          // Meta information
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                if (announcement.author?.name != null)
                  _buildMetaRow(
                    context,
                    Icons.person_outline,
                    'announcements.author'.tr(),
                    announcement.author!.name!,
                  ),
                _buildMetaRow(
                  context,
                  Icons.schedule,
                  'announcements.publishedOn'.tr(),
                  DateFormat('MMMM d, y • HH:mm').format(
                    announcement.publishedAt ?? announcement.createdAt,
                  ),
                ),
                _buildMetaRow(
                  context,
                  Icons.group_outlined,
                  'announcements.audience'.tr(),
                  announcement.targetAudience.displayName,
                ),
                if (announcement.viewCount > 0)
                  _buildMetaRow(
                    context,
                    Icons.visibility_outlined,
                    'Views',
                    '${announcement.viewCount}',
                  ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Content
          Text(
            announcement.content,
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.6,
            ),
          ),

          // Attachment if exists
          if (announcement.hasAttachment) ...[
            const SizedBox(height: 24),
            Card(
              child: ListTile(
                leading: const Icon(Icons.attachment),
                title: Text(announcement.attachmentName ?? 'Attachment'),
                subtitle: const Text('Tap to download'),
                trailing: const Icon(Icons.download),
                onTap: () {
                  // TODO: Handle attachment download
                },
              ),
            ),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildMetaRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityBadge(BuildContext context, AnnouncementPriority priority) {
    final color = _getPriorityColor(priority);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        priority.displayName,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildCategoryBadge(BuildContext context, AnnouncementCategory category) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        category.displayName,
        style: TextStyle(
          fontSize: 12,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Color _getPriorityColor(AnnouncementPriority priority) {
    switch (priority) {
      case AnnouncementPriority.urgent:
        return Colors.red;
      case AnnouncementPriority.high:
        return Colors.orange;
      case AnnouncementPriority.normal:
        return Colors.blue;
      case AnnouncementPriority.low:
        return Colors.grey;
    }
  }
}
