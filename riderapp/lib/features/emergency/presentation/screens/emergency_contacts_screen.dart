import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/emergency_contact.dart';
import '../providers/emergency_provider.dart';
import '../providers/emergency_state.dart';
import '../widgets/emergency_contact_card.dart';

/// Screen for displaying emergency contacts
class EmergencyContactsScreen extends ConsumerStatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  ConsumerState<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState
    extends ConsumerState<EmergencyContactsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(emergencyContactsProvider.notifier).loadContacts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(emergencyContactsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('emergency.title'.tr()),
        actions: [
          // SOS button in app bar
          IconButton(
            onPressed: () => context.push('/emergency/sos'),
            icon: const Icon(Icons.sos, color: Colors.red),
            tooltip: 'SOS',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref
              .read(emergencyContactsProvider.notifier)
              .loadContacts(refresh: true);
        },
        child: _buildBody(state),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/emergency/sos'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.sos),
        label: const Text('SOS'),
      ),
    );
  }

  Widget _buildBody(EmergencyContactsState state) {
    return switch (state) {
      EmergencyContactsInitial() ||
      EmergencyContactsLoading() =>
        const Center(child: CircularProgressIndicator()),
      EmergencyContactsError(message: final message) => Center(
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
                  ref
                      .read(emergencyContactsProvider.notifier)
                      .loadContacts(refresh: true);
                },
                icon: const Icon(Icons.refresh),
                label: Text('common.retry'.tr()),
              ),
            ],
          ),
        ),
      EmergencyContactsLoaded(contacts: final contacts) => contacts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.phone_disabled,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'emergency.noContacts'.tr(),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            )
          : _buildContactsList(contacts),
    };
  }

  Widget _buildContactsList(List<EmergencyContact> contacts) {
    final theme = Theme.of(context);

    // Group contacts by category
    final grouped = <EmergencyContactCategory, List<EmergencyContact>>{};
    for (final contact in contacts) {
      grouped.putIfAbsent(contact.category, () => []).add(contact);
    }

    // Sort categories
    final sortedCategories = grouped.keys.toList()
      ..sort((a, b) => a.index.compareTo(b.index));

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: sortedCategories.length,
      itemBuilder: (context, index) {
        final category = sortedCategories[index];
        final categoryContacts = grouped[category]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                category.displayName,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Contacts in this category
            ...categoryContacts
                .map((contact) => EmergencyContactCard(contact: contact)),
          ],
        );
      },
    );
  }
}
