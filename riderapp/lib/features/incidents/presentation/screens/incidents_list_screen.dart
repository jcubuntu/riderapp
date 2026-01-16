import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../navigation/app_router.dart';
import '../../domain/entities/incident.dart';
import '../providers/incidents_provider.dart';
import '../providers/incidents_state.dart';
import '../widgets/incident_card.dart';

/// Screen to display list of incidents
class IncidentsListScreen extends ConsumerStatefulWidget {
  /// If true, shows only user's own incidents
  final bool isMyIncidents;

  const IncidentsListScreen({
    super.key,
    this.isMyIncidents = false,
  });

  @override
  ConsumerState<IncidentsListScreen> createState() =>
      _IncidentsListScreenState();
}

class _IncidentsListScreenState extends ConsumerState<IncidentsListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  // Filter state
  IncidentCategory? _selectedCategory;
  IncidentStatus? _selectedStatus;
  IncidentPriority? _selectedPriority;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Load incidents on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadIncidents();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  void _loadIncidents() {
    final notifier = widget.isMyIncidents
        ? ref.read(myIncidentsListProvider.notifier)
        : ref.read(incidentsListProvider.notifier);

    notifier.loadIncidents(
      search: _searchController.text.isNotEmpty ? _searchController.text : null,
      category: _selectedCategory,
      status: _selectedStatus,
      priority: _selectedPriority,
    );
  }

  void _loadMore() {
    final state = widget.isMyIncidents
        ? ref.read(myIncidentsListProvider)
        : ref.read(incidentsListProvider);

    if (state is IncidentsListLoaded && !state.isLoadingMore) {
      final notifier = widget.isMyIncidents
          ? ref.read(myIncidentsListProvider.notifier)
          : ref.read(incidentsListProvider.notifier);
      notifier.loadMore();
    }
  }

  Future<void> _onRefresh() async {
    final notifier = widget.isMyIncidents
        ? ref.read(myIncidentsListProvider.notifier)
        : ref.read(incidentsListProvider.notifier);
    await notifier.refresh();
  }

  void _onSearch(String query) {
    _loadIncidents();
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _FilterSheet(
        selectedCategory: _selectedCategory,
        selectedStatus: _selectedStatus,
        selectedPriority: _selectedPriority,
        onApply: (category, status, priority) {
          setState(() {
            _selectedCategory = category;
            _selectedStatus = status;
            _selectedPriority = priority;
          });
          _loadIncidents();
        },
        onClear: () {
          setState(() {
            _selectedCategory = null;
            _selectedStatus = null;
            _selectedPriority = null;
          });
          _loadIncidents();
        },
      ),
    );
  }

  void _navigateToIncidentDetail(String incidentId) {
    context.push('${AppRoutes.incidents}/$incidentId');
  }

  void _navigateToCreateIncident() {
    context.push(AppRoutes.createIncident);
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.isMyIncidents
        ? ref.watch(myIncidentsListProvider)
        : ref.watch(incidentsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isMyIncidents
              ? 'incidents.myReports'.tr()
              : 'incidents.title'.tr(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterSheet,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'common.search'.tr(),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearch('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onSubmitted: _onSearch,
              textInputAction: TextInputAction.search,
            ),
          ),
        ),
      ),
      body: _buildBody(state),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreateIncident,
        icon: const Icon(Icons.add),
        label: Text('incidents.create'.tr()),
      ),
    );
  }

  Widget _buildBody(IncidentsListState state) {
    return switch (state) {
      IncidentsListInitial() => const IncidentsLoadingShimmer(),
      IncidentsListLoading() => const IncidentsLoadingShimmer(),
      IncidentsListError(message: final message) => _buildErrorState(message),
      IncidentsListLoaded(
        incidents: final incidents,
        isLoadingMore: final isLoadingMore,
      ) =>
        incidents.isEmpty
            ? IncidentsEmptyState(
                isMyIncidents: widget.isMyIncidents,
                onCreatePressed: _navigateToCreateIncident,
              )
            : _buildIncidentsList(incidents, isLoadingMore),
    };
  }

  Widget _buildErrorState(String message) {
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
              onPressed: _loadIncidents,
              icon: const Icon(Icons.refresh),
              label: Text('common.retry'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncidentsList(List<Incident> incidents, bool isLoadingMore) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        itemCount: incidents.length + (isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == incidents.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final incident = incidents[index];
          return IncidentCard(
            incident: incident,
            showReporter: !widget.isMyIncidents,
            onTap: () => _navigateToIncidentDetail(incident.id),
          );
        },
      ),
    );
  }
}

/// Bottom sheet for filtering incidents
class _FilterSheet extends StatefulWidget {
  final IncidentCategory? selectedCategory;
  final IncidentStatus? selectedStatus;
  final IncidentPriority? selectedPriority;
  final void Function(
    IncidentCategory? category,
    IncidentStatus? status,
    IncidentPriority? priority,
  ) onApply;
  final VoidCallback onClear;

  const _FilterSheet({
    this.selectedCategory,
    this.selectedStatus,
    this.selectedPriority,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late IncidentCategory? _category;
  late IncidentStatus? _status;
  late IncidentPriority? _priority;

  @override
  void initState() {
    super.initState();
    _category = widget.selectedCategory;
    _status = widget.selectedStatus;
    _priority = widget.selectedPriority;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text(
                  'Filter Incidents',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _category = null;
                      _status = null;
                      _priority = null;
                    });
                  },
                  child: const Text('Clear All'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Category filter
            Text(
              'Category',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildFilterChip(
                  label: 'incidents.categories.intelligence'.tr(),
                  selected: _category == IncidentCategory.intelligence,
                  onSelected: (selected) {
                    setState(() {
                      _category =
                          selected ? IncidentCategory.intelligence : null;
                    });
                  },
                ),
                _buildFilterChip(
                  label: 'incidents.categories.accident'.tr(),
                  selected: _category == IncidentCategory.accident,
                  onSelected: (selected) {
                    setState(() {
                      _category = selected ? IncidentCategory.accident : null;
                    });
                  },
                ),
                _buildFilterChip(
                  label: 'incidents.categories.general'.tr(),
                  selected: _category == IncidentCategory.general,
                  onSelected: (selected) {
                    setState(() {
                      _category = selected ? IncidentCategory.general : null;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Status filter
            Text(
              'Status',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: IncidentStatus.values.map((status) {
                return _buildFilterChip(
                  label: 'incidents.status.${status.name}'.tr(),
                  selected: _status == status,
                  onSelected: (selected) {
                    setState(() {
                      _status = selected ? status : null;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Priority filter
            Text(
              'Priority',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: IncidentPriority.values.map((priority) {
                return _buildFilterChip(
                  label: 'incidents.priority.${priority.name}'.tr(),
                  selected: _priority == priority,
                  onSelected: (selected) {
                    setState(() {
                      _priority = selected ? priority : null;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      widget.onClear();
                      Navigator.pop(context);
                    },
                    child: Text('common.cancel'.tr()),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      widget.onApply(_category, _status, _priority);
                      Navigator.pop(context);
                    },
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required void Function(bool) onSelected,
  }) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
    );
  }
}
