import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/stats_provider.dart';
import '../widgets/stat_card.dart';

/// Screen for displaying system statistics (admin+)
class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Fetch stats on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardStatsProvider.notifier).fetchDashboard();
      ref.read(userSummaryProvider.notifier).fetchUserSummary();
      ref.read(incidentSummaryProvider.notifier).fetchIncidentSummary();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshAll,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Users'),
            Tab(text: 'Incidents'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(context),
          _buildUsersTab(context),
          _buildIncidentsTab(context),
        ],
      ),
    );
  }

  void _refreshAll() {
    ref.read(dashboardStatsProvider.notifier).refresh();
    ref.read(userSummaryProvider.notifier).refresh();
    ref.read(incidentSummaryProvider.notifier).refresh();
  }

  Widget _buildOverviewTab(BuildContext context) {
    final dashboardState = ref.watch(dashboardStatsProvider);

    switch (dashboardState) {
      case DashboardStatsInitial():
      case DashboardStatsLoading():
        return const Center(child: CircularProgressIndicator());

      case DashboardStatsError(message: final message):
        return _buildErrorView(message, () {
          ref.read(dashboardStatsProvider.notifier).refresh();
        });

      case DashboardStatsLoaded(stats: final stats):
        return RefreshIndicator(
          onRefresh: () => ref.read(dashboardStatsProvider.notifier).refresh(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User stats
                _buildSectionTitle(context, 'Users Overview'),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.3,
                  children: [
                    StatCard(
                      title: 'Total Users',
                      value: stats.users.total.toString(),
                      icon: Icons.people,
                      color: Colors.blue,
                    ),
                    StatCard(
                      title: 'Pending Approval',
                      value: stats.users.pending.toString(),
                      icon: Icons.hourglass_empty,
                      color: Colors.orange,
                    ),
                    StatCard(
                      title: 'Active Riders',
                      value: stats.users.riders.toString(),
                      icon: Icons.two_wheeler,
                      color: Colors.teal,
                    ),
                    StatCard(
                      title: 'Police Officers',
                      value: stats.users.police.toString(),
                      icon: Icons.local_police,
                      color: Colors.indigo,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Incident stats
                _buildSectionTitle(context, 'Incidents Overview'),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.3,
                  children: [
                    StatCard(
                      title: 'Total Incidents',
                      value: stats.incidents.total.toString(),
                      icon: Icons.report,
                      color: Colors.red,
                    ),
                    StatCard(
                      title: 'Today',
                      value: stats.incidents.today.toString(),
                      icon: Icons.today,
                      color: Colors.purple,
                    ),
                    StatCard(
                      title: 'Investigating',
                      value: stats.incidents.investigating.toString(),
                      icon: Icons.search,
                      color: Colors.amber,
                    ),
                    StatCard(
                      title: 'Resolved',
                      value: stats.incidents.resolved.toString(),
                      icon: Icons.check_circle,
                      color: Colors.green,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Alerts section
                _buildSectionTitle(context, 'Alerts'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        title: 'Unread Notifications',
                        value: stats.unreadNotifications.toString(),
                        icon: Icons.notifications,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        title: 'Active SOS',
                        value: stats.activeSosAlerts.toString(),
                        icon: Icons.sos,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
    }
  }

  Widget _buildUsersTab(BuildContext context) {
    final userSummaryState = ref.watch(userSummaryProvider);

    switch (userSummaryState) {
      case UserSummaryInitial():
      case UserSummaryLoading():
        return const Center(child: CircularProgressIndicator());

      case UserSummaryError(message: final message):
        return _buildErrorView(message, () {
          ref.read(userSummaryProvider.notifier).refresh();
        });

      case UserSummaryLoaded(summary: final summary):
        return RefreshIndicator(
          onRefresh: () => ref.read(userSummaryProvider.notifier).refresh(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Total users card
                LargeStatCard(
                  title: 'Total Users',
                  value: summary.total.toString(),
                  description: 'All registered users in the system',
                  icon: Icons.people,
                  color: Colors.blue,
                ),

                const SizedBox(height: 24),

                // By status
                _buildSectionTitle(context, 'By Status'),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.4,
                  children: [
                    StatCard(
                      title: 'Approved',
                      value: summary.approved.toString(),
                      subtitle:
                          '${_formatPercentage(summary.approved, summary.total)}%',
                      icon: Icons.check_circle,
                      color: Colors.green,
                    ),
                    StatCard(
                      title: 'Pending',
                      value: summary.pending.toString(),
                      subtitle:
                          '${_formatPercentage(summary.pending, summary.total)}%',
                      icon: Icons.hourglass_empty,
                      color: Colors.orange,
                    ),
                    StatCard(
                      title: 'Rejected',
                      value: summary.rejected.toString(),
                      subtitle:
                          '${_formatPercentage(summary.rejected, summary.total)}%',
                      icon: Icons.cancel,
                      color: Colors.red,
                    ),
                    StatCard(
                      title: 'Suspended',
                      value: summary.suspended.toString(),
                      subtitle:
                          '${_formatPercentage(summary.suspended, summary.total)}%',
                      icon: Icons.block,
                      color: Colors.grey,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Approval rate
                _buildSectionTitle(context, 'Metrics'),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Approval Rate',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              '${summary.approvalRate.toStringAsFixed(1)}%',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: _getApprovalRateColor(
                                        summary.approvalRate),
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: summary.approvalRate / 100,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation(
                            _getApprovalRateColor(summary.approvalRate),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
    }
  }

  Widget _buildIncidentsTab(BuildContext context) {
    final incidentSummaryState = ref.watch(incidentSummaryProvider);

    switch (incidentSummaryState) {
      case IncidentSummaryInitial():
      case IncidentSummaryLoading():
        return const Center(child: CircularProgressIndicator());

      case IncidentSummaryError(message: final message):
        return _buildErrorView(message, () {
          ref.read(incidentSummaryProvider.notifier).refresh();
        });

      case IncidentSummaryLoaded(summary: final summary):
        return RefreshIndicator(
          onRefresh: () => ref.read(incidentSummaryProvider.notifier).refresh(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Total incidents card
                LargeStatCard(
                  title: 'Total Incidents',
                  value: summary.total.toString(),
                  description: 'All reported incidents',
                  icon: Icons.report,
                  color: Colors.red,
                ),

                const SizedBox(height: 24),

                // By status
                _buildSectionTitle(context, 'By Status'),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.4,
                  children: [
                    StatCard(
                      title: 'Reported',
                      value: summary.reported.toString(),
                      subtitle:
                          '${_formatPercentage(summary.reported, summary.total)}%',
                      icon: Icons.flag,
                      color: Colors.orange,
                    ),
                    StatCard(
                      title: 'Acknowledged',
                      value: summary.acknowledged.toString(),
                      subtitle:
                          '${_formatPercentage(summary.acknowledged, summary.total)}%',
                      icon: Icons.visibility,
                      color: Colors.blue,
                    ),
                    StatCard(
                      title: 'Investigating',
                      value: summary.investigating.toString(),
                      subtitle:
                          '${_formatPercentage(summary.investigating, summary.total)}%',
                      icon: Icons.search,
                      color: Colors.amber,
                    ),
                    StatCard(
                      title: 'Resolved',
                      value: summary.resolved.toString(),
                      subtitle:
                          '${_formatPercentage(summary.resolved, summary.total)}%',
                      icon: Icons.check_circle,
                      color: Colors.green,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Metrics
                _buildSectionTitle(context, 'Metrics'),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Resolution rate
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Resolution Rate',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              '${summary.resolutionRate.toStringAsFixed(1)}%',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: _getResolutionRateColor(
                                        summary.resolutionRate),
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: summary.resolutionRate / 100,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation(
                            _getResolutionRateColor(summary.resolutionRate),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Average resolution time
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Avg. Resolution Time',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              _formatDuration(summary.averageResolutionTime),
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
    }
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildErrorView(String message, VoidCallback onRetry) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: colorScheme.error),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  String _formatPercentage(int value, int total) {
    if (total == 0) return '0';
    return ((value / total) * 100).toStringAsFixed(1);
  }

  Color _getApprovalRateColor(double rate) {
    if (rate >= 80) return Colors.green;
    if (rate >= 50) return Colors.orange;
    return Colors.red;
  }

  Color _getResolutionRateColor(double rate) {
    if (rate >= 80) return Colors.green;
    if (rate >= 50) return Colors.orange;
    return Colors.red;
  }

  String _formatDuration(double hours) {
    if (hours < 1) {
      return '${(hours * 60).round()} min';
    } else if (hours < 24) {
      return '${hours.toStringAsFixed(1)} hrs';
    } else {
      final days = hours / 24;
      return '${days.toStringAsFixed(1)} days';
    }
  }
}
