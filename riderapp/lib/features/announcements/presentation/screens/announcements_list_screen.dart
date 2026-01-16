import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/announcement.dart';
import '../providers/announcements_provider.dart';
import '../providers/announcements_state.dart';
import '../widgets/announcement_card.dart';

/// Screen for displaying list of announcements
class AnnouncementsListScreen extends ConsumerStatefulWidget {
  const AnnouncementsListScreen({super.key});

  @override
  ConsumerState<AnnouncementsListScreen> createState() => _AnnouncementsListScreenState();
}

class _AnnouncementsListScreenState extends ConsumerState<AnnouncementsListScreen> {
  final _scrollController = ScrollController();
  AnnouncementPriority? _selectedPriority;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Load announcements on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(announcementsProvider.notifier).loadAnnouncements();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(announcementsProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(announcementsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('announcements.title'.tr()),
        actions: [
          // Filter button
          PopupMenuButton<AnnouncementPriority?>(
            icon: Icon(
              Icons.filter_list,
              color: _selectedPriority != null
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            onSelected: (priority) {
              setState(() => _selectedPriority = priority);
              ref.read(announcementsProvider.notifier).setPriorityFilter(priority);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: null,
                child: Row(
                  children: [
                    if (_selectedPriority == null)
                      const Icon(Icons.check, size: 18),
                    const SizedBox(width: 8),
                    const Text('All'),
                  ],
                ),
              ),
              ...AnnouncementPriority.values.map((priority) => PopupMenuItem(
                    value: priority,
                    child: Row(
                      children: [
                        if (_selectedPriority == priority)
                          const Icon(Icons.check, size: 18),
                        const SizedBox(width: 8),
                        Text(priority.displayName),
                      ],
                    ),
                  )),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(announcementsProvider.notifier).loadAnnouncements(refresh: true);
        },
        child: _buildBody(state),
      ),
    );
  }

  Widget _buildBody(AnnouncementsState state) {
    return switch (state) {
      AnnouncementsInitial() || AnnouncementsLoading() => const Center(
          child: CircularProgressIndicator(),
        ),
      AnnouncementsError(message: final message) => Center(
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
                  ref.read(announcementsProvider.notifier).loadAnnouncements(refresh: true);
                },
                icon: const Icon(Icons.refresh),
                label: Text('common.retry'.tr()),
              ),
            ],
          ),
        ),
      AnnouncementsLoaded(
        announcements: final announcements,
        isLoadingMore: final isLoadingMore,
      ) =>
        announcements.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.announcement_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'announcements.noAnnouncements'.tr(),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              )
            : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.only(top: 8, bottom: 16),
                itemCount: announcements.length + (isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == announcements.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final announcement = announcements[index];
                  return AnnouncementCard(
                    announcement: announcement,
                    onTap: () {
                      context.push('/announcements/${announcement.id}');
                      // Mark as read locally
                      ref
                          .read(announcementsProvider.notifier)
                          .markAsReadLocally(announcement.id);
                    },
                  );
                },
              ),
    };
  }
}
