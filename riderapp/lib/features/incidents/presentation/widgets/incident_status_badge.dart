import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/incident.dart';

/// A badge widget to display incident status
class IncidentStatusBadge extends StatelessWidget {
  final IncidentStatus status;
  final bool isLarge;

  const IncidentStatusBadge({
    super.key,
    required this.status,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLarge ? 12 : 8,
        vertical: isLarge ? 6 : 4,
      ),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(isLarge ? 8 : 4),
      ),
      child: Text(
        _getLocalizedStatus(),
        style: TextStyle(
          color: _getTextColor(),
          fontSize: isLarge ? 14 : 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _getLocalizedStatus() {
    switch (status) {
      case IncidentStatus.pending:
        return 'incidents.status.pending'.tr();
      case IncidentStatus.reviewing:
        return 'incidents.status.reviewing'.tr();
      case IncidentStatus.verified:
        return 'incidents.status.verified'.tr();
      case IncidentStatus.resolved:
        return 'incidents.status.resolved'.tr();
      case IncidentStatus.rejected:
        return 'incidents.status.rejected'.tr();
    }
  }

  Color _getBackgroundColor() {
    switch (status) {
      case IncidentStatus.pending:
        return Colors.orange.shade100;
      case IncidentStatus.reviewing:
        return Colors.blue.shade100;
      case IncidentStatus.verified:
        return Colors.teal.shade100;
      case IncidentStatus.resolved:
        return Colors.green.shade100;
      case IncidentStatus.rejected:
        return Colors.red.shade100;
    }
  }

  Color _getTextColor() {
    switch (status) {
      case IncidentStatus.pending:
        return Colors.orange.shade800;
      case IncidentStatus.reviewing:
        return Colors.blue.shade800;
      case IncidentStatus.verified:
        return Colors.teal.shade800;
      case IncidentStatus.resolved:
        return Colors.green.shade800;
      case IncidentStatus.rejected:
        return Colors.red.shade800;
    }
  }
}

/// A badge widget to display incident priority
class IncidentPriorityBadge extends StatelessWidget {
  final IncidentPriority priority;
  final bool isLarge;

  const IncidentPriorityBadge({
    super.key,
    required this.priority,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLarge ? 12 : 8,
        vertical: isLarge ? 6 : 4,
      ),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(isLarge ? 8 : 4),
        border: Border.all(color: _getBorderColor(), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getIcon(),
            size: isLarge ? 16 : 12,
            color: _getTextColor(),
          ),
          const SizedBox(width: 4),
          Text(
            _getLocalizedPriority(),
            style: TextStyle(
              color: _getTextColor(),
              fontSize: isLarge ? 14 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _getLocalizedPriority() {
    switch (priority) {
      case IncidentPriority.low:
        return 'incidents.priority.low'.tr();
      case IncidentPriority.medium:
        return 'incidents.priority.medium'.tr();
      case IncidentPriority.high:
        return 'incidents.priority.high'.tr();
      case IncidentPriority.critical:
        return 'incidents.priority.critical'.tr();
    }
  }

  IconData _getIcon() {
    switch (priority) {
      case IncidentPriority.low:
        return Icons.arrow_downward;
      case IncidentPriority.medium:
        return Icons.remove;
      case IncidentPriority.high:
        return Icons.arrow_upward;
      case IncidentPriority.critical:
        return Icons.priority_high;
    }
  }

  Color _getBackgroundColor() {
    switch (priority) {
      case IncidentPriority.low:
        return Colors.grey.shade100;
      case IncidentPriority.medium:
        return Colors.yellow.shade50;
      case IncidentPriority.high:
        return Colors.orange.shade50;
      case IncidentPriority.critical:
        return Colors.red.shade50;
    }
  }

  Color _getBorderColor() {
    switch (priority) {
      case IncidentPriority.low:
        return Colors.grey.shade300;
      case IncidentPriority.medium:
        return Colors.yellow.shade700;
      case IncidentPriority.high:
        return Colors.orange.shade700;
      case IncidentPriority.critical:
        return Colors.red.shade700;
    }
  }

  Color _getTextColor() {
    switch (priority) {
      case IncidentPriority.low:
        return Colors.grey.shade700;
      case IncidentPriority.medium:
        return Colors.yellow.shade900;
      case IncidentPriority.high:
        return Colors.orange.shade900;
      case IncidentPriority.critical:
        return Colors.red.shade900;
    }
  }
}

/// A badge widget to display incident category
class IncidentCategoryBadge extends StatelessWidget {
  final IncidentCategory category;
  final bool isLarge;

  const IncidentCategoryBadge({
    super.key,
    required this.category,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLarge ? 12 : 8,
        vertical: isLarge ? 6 : 4,
      ),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(isLarge ? 8 : 4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getIcon(),
            size: isLarge ? 16 : 12,
            color: _getTextColor(),
          ),
          const SizedBox(width: 4),
          Text(
            _getLocalizedCategory(),
            style: TextStyle(
              color: _getTextColor(),
              fontSize: isLarge ? 14 : 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getLocalizedCategory() {
    switch (category) {
      case IncidentCategory.intelligence:
        return 'incidents.categories.intelligence'.tr();
      case IncidentCategory.accident:
        return 'incidents.categories.accident'.tr();
      case IncidentCategory.general:
        return 'incidents.categories.general'.tr();
    }
  }

  IconData _getIcon() {
    switch (category) {
      case IncidentCategory.intelligence:
        return Icons.lightbulb_outline;
      case IncidentCategory.accident:
        return Icons.car_crash;
      case IncidentCategory.general:
        return Icons.help_outline;
    }
  }

  Color _getBackgroundColor() {
    switch (category) {
      case IncidentCategory.intelligence:
        return Colors.purple.shade100;
      case IncidentCategory.accident:
        return Colors.red.shade100;
      case IncidentCategory.general:
        return Colors.blue.shade100;
    }
  }

  Color _getTextColor() {
    switch (category) {
      case IncidentCategory.intelligence:
        return Colors.purple.shade800;
      case IncidentCategory.accident:
        return Colors.red.shade800;
      case IncidentCategory.general:
        return Colors.blue.shade800;
    }
  }
}
