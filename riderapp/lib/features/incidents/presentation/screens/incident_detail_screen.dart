import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/incident.dart';
import '../providers/incidents_provider.dart';
import '../providers/incidents_state.dart';
import '../widgets/incident_status_badge.dart';

/// Screen to display incident details
class IncidentDetailScreen extends ConsumerWidget {
  final String incidentId;

  const IncidentDetailScreen({
    super.key,
    required this.incidentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(incidentDetailProvider(incidentId));
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('incidents.title'.tr()),
        actions: _buildAppBarActions(context, ref, state, user),
      ),
      body: _buildBody(context, ref, state, user),
    );
  }

  List<Widget>? _buildAppBarActions(
    BuildContext context,
    WidgetRef ref,
    IncidentDetailState state,
    UserModel? user,
  ) {
    if (state is! IncidentDetailLoaded || user == null) return null;

    final incident = state.incident;
    final canEdit = _canEditIncident(incident, user);
    final canDelete = _canDeleteIncident(user);

    if (!canEdit && !canDelete) return null;

    return [
      PopupMenuButton<String>(
        onSelected: (value) => _handleMenuAction(context, ref, value, incident),
        itemBuilder: (context) => [
          if (canEdit)
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  const Icon(Icons.edit_outlined),
                  const SizedBox(width: 8),
                  Text('common.edit'.tr()),
                ],
              ),
            ),
          if (canDelete)
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Text(
                    'common.delete'.tr(),
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ],
              ),
            ),
        ],
      ),
    ];
  }

  bool _canEditIncident(Incident incident, UserModel user) {
    // User can edit if they own the incident and it's still pending
    if (incident.reportedBy == user.id && incident.isOpen) {
      return true;
    }
    // Admin/Super Admin can always edit
    return user.isAdmin || user.isSuperAdmin;
  }

  bool _canDeleteIncident(UserModel user) {
    return user.isAdmin || user.isSuperAdmin;
  }

  void _handleMenuAction(
    BuildContext context,
    WidgetRef ref,
    String action,
    Incident incident,
  ) {
    switch (action) {
      case 'edit':
        context.push('/incidents/${incident.id}/edit');
        break;
      case 'delete':
        _showDeleteConfirmation(context, ref, incident);
        break;
    }
  }

  void _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    Incident incident,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('common.confirm'.tr()),
        content: const Text('Are you sure you want to delete this incident?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common.cancel'.tr()),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref
                    .read(incidentDetailProvider(incidentId).notifier)
                    .deleteIncident();
                if (context.mounted) {
                  context.pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Incident deleted successfully'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text('common.delete'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    IncidentDetailState state,
    UserModel? user,
  ) {
    return switch (state) {
      IncidentDetailInitial() => const Center(
          child: CircularProgressIndicator(),
        ),
      IncidentDetailLoading() => const Center(
          child: CircularProgressIndicator(),
        ),
      IncidentDetailError(message: final message) => _buildErrorState(
          context,
          ref,
          message,
        ),
      IncidentDetailLoaded(incident: final incident, isUpdating: final isUpdating) =>
        Stack(
          children: [
            _buildIncidentDetail(context, ref, incident, user),
            if (isUpdating)
              Container(
                color: Colors.black26,
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
    };
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
              message,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                ref.read(incidentDetailProvider(incidentId).notifier).refresh();
              },
              icon: const Icon(Icons.refresh),
              label: Text('common.retry'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncidentDetail(
    BuildContext context,
    WidgetRef ref,
    Incident incident,
    UserModel? user,
  ) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd MMMM yyyy, HH:mm');

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(incidentDetailProvider(incidentId).notifier).refresh();
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status and priority badges
            Row(
              children: [
                IncidentCategoryBadge(category: incident.category, isLarge: true),
                const SizedBox(width: 8),
                IncidentPriorityBadge(priority: incident.priority, isLarge: true),
                const Spacer(),
                IncidentStatusBadge(status: incident.status, isLarge: true),
              ],
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              incident.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Description
            _buildSection(
              context,
              title: 'Description',
              icon: Icons.description_outlined,
              child: Text(
                incident.description,
                style: theme.textTheme.bodyLarge,
              ),
            ),
            const SizedBox(height: 16),

            // Location
            if (incident.location.address != null)
              _buildSection(
                context,
                title: 'incidents.form.location'.tr(),
                icon: Icons.location_on_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      incident.location.address!,
                      style: theme.textTheme.bodyLarge,
                    ),
                    if (incident.location.province != null ||
                        incident.location.district != null)
                      Text(
                        [
                          incident.location.district,
                          incident.location.province,
                        ].where((e) => e != null).join(', '),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    if (incident.location.hasCoordinates)
                      TextButton.icon(
                        onPressed: () {
                          // TODO: Open map with coordinates
                        },
                        icon: const Icon(Icons.map, size: 18),
                        label: const Text('View on Map'),
                      ),
                  ],
                ),
              ),
            if (incident.location.address != null) const SizedBox(height: 16),

            // Reporter info (if not anonymous)
            if (!incident.isAnonymous)
              _buildSection(
                context,
                title: 'Reported By',
                icon: Icons.person_outline,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      incident.reporterName ?? 'Unknown',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (incident.reporterPhone != null)
                      Text(
                        incident.reporterPhone!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                  ],
                ),
              ),
            if (incident.isAnonymous)
              _buildSection(
                context,
                title: 'Reported By',
                icon: Icons.visibility_off_outlined,
                child: Text(
                  'Anonymous Report',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Assigned officer
            if (incident.isAssigned)
              _buildSection(
                context,
                title: 'Assigned To',
                icon: Icons.badge_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      incident.assigneeName ?? 'Unknown Officer',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (incident.assignedAt != null)
                      Text(
                        'Assigned on ${dateFormat.format(incident.assignedAt!)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                  ],
                ),
              ),
            if (incident.isAssigned) const SizedBox(height: 16),

            // Review notes (if reviewed)
            if (incident.reviewedBy != null)
              _buildSection(
                context,
                title: 'Review Information',
                icon: Icons.fact_check_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reviewed by ${incident.reviewerName ?? 'Unknown'}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (incident.reviewedAt != null)
                      Text(
                        dateFormat.format(incident.reviewedAt!),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    if (incident.reviewNotes != null &&
                        incident.reviewNotes!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          incident.reviewNotes!,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                  ],
                ),
              ),
            if (incident.reviewedBy != null) const SizedBox(height: 16),

            // Resolution notes (if resolved)
            if (incident.resolvedBy != null)
              _buildSection(
                context,
                title: 'Resolution Information',
                icon: Icons.check_circle_outline,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resolved by ${incident.resolverName ?? 'Unknown'}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (incident.resolvedAt != null)
                      Text(
                        dateFormat.format(incident.resolvedAt!),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    if (incident.resolutionNotes != null &&
                        incident.resolutionNotes!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          incident.resolutionNotes!,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                  ],
                ),
              ),
            if (incident.resolvedBy != null) const SizedBox(height: 16),

            // Timestamps
            _buildSection(
              context,
              title: 'Timeline',
              icon: Icons.access_time,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTimelineItem(
                    'Reported',
                    dateFormat.format(incident.createdAt),
                  ),
                  if (incident.incidentDate != null)
                    _buildTimelineItem(
                      'Incident occurred',
                      dateFormat.format(incident.incidentDate!),
                    ),
                  if (incident.createdAt != incident.updatedAt)
                    _buildTimelineItem(
                      'Last updated',
                      dateFormat.format(incident.updatedAt),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action buttons (for police+ roles)
            if (user != null && _canChangeStatus(user))
              _buildActionButtons(context, ref, incident, user),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  bool _canChangeStatus(UserModel user) {
    return user.isPolice || user.isVolunteer || user.isAdmin || user.isSuperAdmin;
  }

  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    Incident incident,
    UserModel user,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(),
        const SizedBox(height: 16),
        Text(
          'Actions',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        // Status transition buttons based on current status
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _buildStatusButtons(context, ref, incident, user),
        ),
      ],
    );
  }

  List<Widget> _buildStatusButtons(
    BuildContext context,
    WidgetRef ref,
    Incident incident,
    UserModel user,
  ) {
    final buttons = <Widget>[];

    switch (incident.status) {
      case IncidentStatus.pending:
        buttons.add(_buildStatusButton(
          context,
          ref,
          'Start Review',
          IncidentStatus.reviewing,
          Colors.blue,
        ));
        buttons.add(_buildStatusButton(
          context,
          ref,
          'Reject',
          IncidentStatus.rejected,
          Colors.red,
        ));
        break;

      case IncidentStatus.reviewing:
        buttons.add(_buildStatusButton(
          context,
          ref,
          'Verify',
          IncidentStatus.verified,
          Colors.teal,
        ));
        buttons.add(_buildStatusButton(
          context,
          ref,
          'Reject',
          IncidentStatus.rejected,
          Colors.red,
        ));
        break;

      case IncidentStatus.verified:
        buttons.add(_buildStatusButton(
          context,
          ref,
          'Mark Resolved',
          IncidentStatus.resolved,
          Colors.green,
        ));
        break;

      case IncidentStatus.resolved:
      case IncidentStatus.rejected:
        // No actions available for closed incidents
        break;
    }

    return buttons;
  }

  Widget _buildStatusButton(
    BuildContext context,
    WidgetRef ref,
    String label,
    IncidentStatus newStatus,
    Color color,
  ) {
    return FilledButton(
      onPressed: () => _showStatusChangeDialog(context, ref, label, newStatus),
      style: FilledButton.styleFrom(backgroundColor: color),
      child: Text(label),
    );
  }

  void _showStatusChangeDialog(
    BuildContext context,
    WidgetRef ref,
    String action,
    IncidentStatus newStatus,
  ) {
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(action),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to $action this incident?'),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common.cancel'.tr()),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref
                    .read(incidentDetailProvider(incidentId).notifier)
                    .updateStatus(
                      newStatus,
                      notes: notesController.text.isNotEmpty
                          ? notesController.text
                          : null,
                    );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Status updated to ${newStatus.displayName}'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to update status: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text('common.confirm'.tr()),
          ),
        ],
      ),
    );
  }
}
