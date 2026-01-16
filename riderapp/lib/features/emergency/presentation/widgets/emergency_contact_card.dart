import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/emergency_contact.dart';

/// Card widget for displaying an emergency contact
class EmergencyContactCard extends StatelessWidget {
  final EmergencyContact contact;

  const EmergencyContactCard({
    super.key,
    required this.contact,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getCategoryColor(contact.category, colorScheme),
          child: Icon(
            _getCategoryIcon(contact.category),
            color: Colors.white,
          ),
        ),
        title: Text(
          contact.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: contact.isDefault ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              contact.phone,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (contact.description != null && contact.description!.isNotEmpty)
              Text(
                contact.description!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: FilledButton.icon(
          onPressed: () => _makeCall(context, contact.phone),
          icon: const Icon(Icons.call, size: 18),
          label: Text('emergency.call'.tr()),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        ),
        isThreeLine: contact.description != null && contact.description!.isNotEmpty,
      ),
    );
  }

  Future<void> _makeCall(BuildContext context, String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot make phone call')),
        );
      }
    }
  }

  IconData _getCategoryIcon(EmergencyContactCategory category) {
    switch (category) {
      case EmergencyContactCategory.police:
        return Icons.local_police;
      case EmergencyContactCategory.hospital:
        return Icons.local_hospital;
      case EmergencyContactCategory.fire:
        return Icons.local_fire_department;
      case EmergencyContactCategory.rescue:
        return Icons.health_and_safety;
      case EmergencyContactCategory.insurance:
        return Icons.shield;
      case EmergencyContactCategory.other:
        return Icons.phone;
    }
  }

  Color _getCategoryColor(EmergencyContactCategory category, ColorScheme colorScheme) {
    switch (category) {
      case EmergencyContactCategory.police:
        return Colors.blue;
      case EmergencyContactCategory.hospital:
        return Colors.red;
      case EmergencyContactCategory.fire:
        return Colors.orange;
      case EmergencyContactCategory.rescue:
        return Colors.green;
      case EmergencyContactCategory.insurance:
        return Colors.purple;
      case EmergencyContactCategory.other:
        return colorScheme.primary;
    }
  }
}
