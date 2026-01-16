import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/incident.dart';
import 'incident_status_badge.dart';

/// A card widget to display incident summary
class IncidentCard extends StatelessWidget {
  final Incident incident;
  final VoidCallback? onTap;
  final bool showReporter;

  const IncidentCard({
    super.key,
    required this.incident,
    this.onTap,
    this.showReporter = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with category and priority
              Row(
                children: [
                  IncidentCategoryBadge(category: incident.category),
                  const SizedBox(width: 8),
                  IncidentPriorityBadge(priority: incident.priority),
                  const Spacer(),
                  IncidentStatusBadge(status: incident.status),
                ],
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                incident.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                incident.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Location (if available)
              if (incident.location.address != null &&
                  incident.location.address!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          incident.location.address!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

              // Footer row with reporter and date
              Row(
                children: [
                  if (showReporter && !incident.isAnonymous) ...[
                    Icon(
                      Icons.person_outline,
                      size: 16,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      incident.reporterName ?? 'Unknown',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  if (showReporter && incident.isAnonymous) ...[
                    Icon(
                      Icons.visibility_off_outlined,
                      size: 16,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Anonymous',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  const Spacer(),
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(incident.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),

              // Assigned officer (if any)
              if (incident.isAssigned && incident.assigneeName != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.badge_outlined,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Assigned to: ${incident.assigneeName}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A compact card widget for incident list
class IncidentListTile extends StatelessWidget {
  final Incident incident;
  final VoidCallback? onTap;

  const IncidentListTile({
    super.key,
    required this.incident,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM/yy');

    return ListTile(
      onTap: onTap,
      leading: _buildCategoryIcon(theme),
      title: Text(
        incident.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        incident.description,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IncidentStatusBadge(status: incident.status),
          const SizedBox(height: 4),
          Text(
            dateFormat.format(incident.createdAt),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryIcon(ThemeData theme) {
    final IconData icon;
    final Color color;

    switch (incident.category) {
      case IncidentCategory.intelligence:
        icon = Icons.lightbulb_outline;
        color = Colors.purple;
      case IncidentCategory.accident:
        icon = Icons.car_crash;
        color = Colors.red;
      case IncidentCategory.general:
        icon = Icons.help_outline;
        color = Colors.blue;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }
}

/// Empty state widget for incidents list
class IncidentsEmptyState extends StatelessWidget {
  final bool isMyIncidents;
  final VoidCallback? onCreatePressed;

  const IncidentsEmptyState({
    super.key,
    this.isMyIncidents = false,
    this.onCreatePressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.report_off_outlined,
              size: 80,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              isMyIncidents
                  ? 'You have not reported any incidents yet'
                  : 'No incidents found',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isMyIncidents
                  ? 'Report an incident to get started'
                  : 'Try adjusting your filters',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              textAlign: TextAlign.center,
            ),
            if (onCreatePressed != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onCreatePressed,
                icon: const Icon(Icons.add),
                label: Text('incidents.create'.tr()),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Loading shimmer for incidents list
class IncidentsLoadingShimmer extends StatelessWidget {
  final int itemCount;

  const IncidentsLoadingShimmer({
    super.key,
    this.itemCount = 5,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: itemCount,
      itemBuilder: (context, index) => const _ShimmerCard(),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _shimmerBox(80, 24),
                const SizedBox(width: 8),
                _shimmerBox(60, 24),
                const Spacer(),
                _shimmerBox(70, 24),
              ],
            ),
            const SizedBox(height: 12),
            _shimmerBox(double.infinity, 20),
            const SizedBox(height: 8),
            _shimmerBox(double.infinity, 16),
            _shimmerBox(200, 16),
            const SizedBox(height: 12),
            Row(
              children: [
                const Spacer(),
                _shimmerBox(120, 14),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _shimmerBox(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
