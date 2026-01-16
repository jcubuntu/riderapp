import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/providers/stats_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class AdminHomeScreen extends ConsumerStatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  ConsumerState<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends ConsumerState<AdminHomeScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch dashboard stats on init
    Future.microtask(() {
      ref.read(dashboardStatsProvider.notifier).fetchDashboard();
      ref.read(userSummaryProvider.notifier).fetchUserSummary();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch user for reactivity
    ref.watch(currentUserProvider);

    // Watch stats
    final dashboardState = ref.watch(dashboardStatsProvider);
    final userSummaryState = ref.watch(userSummaryProvider);

    // Extract values from states
    int pendingApprovals = 0;
    int totalUsers = 0;
    int totalIncidents = 0;
    int resolvedIncidents = 0;

    if (dashboardState is DashboardStatsLoaded) {
      totalIncidents = dashboardState.stats.incidents.total;
      resolvedIncidents = dashboardState.stats.incidents.resolved;
    }

    if (userSummaryState is UserSummaryLoaded) {
      pendingApprovals = userSummaryState.summary.pending;
      totalUsers = userSummaryState.summary.total;
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        title: Text('home.admin.title'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              context.push('/notifications');
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(dashboardStatsProvider.notifier).refresh();
          await ref.read(userSummaryProvider.notifier).refresh();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Overview stats
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      icon: Icons.person_add,
                      label: 'home.admin.pendingApprovals'.tr(),
                      value: pendingApprovals.toString(),
                      color: AppColors.warning,
                      isLoading: userSummaryState is UserSummaryLoading,
                      onTap: () {
                        // TODO: Navigate to pending approvals
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      icon: Icons.people,
                      label: 'home.admin.totalUsers'.tr(),
                      value: _formatNumber(totalUsers),
                      color: AppColors.primary,
                      isLoading: userSummaryState is UserSummaryLoading,
                      onTap: () {
                        // TODO: Navigate to user management
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      icon: Icons.report,
                      label: 'home.admin.totalIncidents'.tr(),
                      value: _formatNumber(totalIncidents),
                      color: AppColors.info,
                      isLoading: dashboardState is DashboardStatsLoading,
                      onTap: () {
                        // TODO: Navigate to statistics
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      icon: Icons.check_circle,
                      label: 'incidents.status.resolved'.tr(),
                      value: _formatNumber(resolvedIncidents),
                      color: AppColors.success,
                      isLoading: dashboardState is DashboardStatsLoading,
                      onTap: () {
                        // TODO: Navigate to statistics
                      },
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 24),

            // Quick actions
            Text(
              'home.rider.quickActions'.tr(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 16),

            _buildActionTile(
              context,
              icon: Icons.how_to_reg,
              title: 'admin.pendingApprovals'.tr(),
              subtitle: '$pendingApprovals users waiting for approval',
              color: AppColors.warning,
              onTap: () {
                // TODO: Navigate to pending approvals
              },
            ),
            const SizedBox(height: 12),
            _buildActionTile(
              context,
              icon: Icons.manage_accounts,
              title: 'admin.userManagement'.tr(),
              subtitle: 'View and manage all users',
              color: AppColors.primary,
              onTap: () {
                // TODO: Navigate to user management
              },
            ),
            const SizedBox(height: 12),
            _buildActionTile(
              context,
              icon: Icons.analytics,
              title: 'admin.statistics'.tr(),
              subtitle: 'View reports and analytics',
              color: AppColors.info,
              onTap: () {
                // TODO: Navigate to statistics
              },
            ),
            const SizedBox(height: 12),
            _buildActionTile(
              context,
              icon: Icons.campaign,
              title: 'announcements.create'.tr(),
              subtitle: 'Create new announcement',
              color: AppColors.tertiary,
              onTap: () {
                // TODO: Navigate to create announcement
              },
            ),
          ],
        ),
      ),
    ),
    bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primaryDark,
        unselectedItemColor: AppColors.textSecondary,
        onTap: (index) {
          switch (index) {
            case 0:
              // Already on home, do nothing
              break;
            case 1:
              context.push('/admin/users');
              break;
            case 2:
              context.push('/announcements');
              break;
            case 3:
              context.push('/profile');
              break;
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard),
            label: 'home.admin.title'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.people),
            label: 'admin.userManagement'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.campaign),
            label: 'announcements.title'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: 'profile.title'.tr(),
          ),
        ],
      ),
    );
  }

  /// Format number with comma separators
  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(number >= 10000 ? 0 : 1)}K';
    }
    return number.toString();
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: isLoading
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: color,
                          ),
                        )
                      : Text(
                          value,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                        ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
