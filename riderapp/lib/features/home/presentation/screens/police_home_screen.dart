import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/providers/stats_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class PoliceHomeScreen extends ConsumerStatefulWidget {
  const PoliceHomeScreen({super.key});

  @override
  ConsumerState<PoliceHomeScreen> createState() => _PoliceHomeScreenState();
}

class _PoliceHomeScreenState extends ConsumerState<PoliceHomeScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch dashboard stats on init
    Future.microtask(() {
      ref.read(dashboardStatsProvider.notifier).fetchDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch user for reactivity
    ref.watch(currentUserProvider);

    // Watch stats
    final dashboardState = ref.watch(dashboardStatsProvider);

    // Extract values from state
    int pendingReports = 0;
    int todayIncidents = 0;
    int unreadNotifications = 0;

    if (dashboardState is DashboardStatsLoaded) {
      pendingReports = dashboardState.stats.incidents.pending +
          dashboardState.stats.incidents.investigating;
      todayIncidents = dashboardState.stats.incidents.today;
      unreadNotifications = dashboardState.stats.unreadNotifications;
    }

    final isLoading = dashboardState is DashboardStatsLoading;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text('home.police.title'.tr()),
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
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Stats cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      icon: Icons.pending_actions,
                      label: 'home.police.pendingReports'.tr(),
                      value: pendingReports.toString(),
                      color: AppColors.warning,
                      isLoading: isLoading,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      icon: Icons.today,
                      label: 'home.police.todayIncidents'.tr(),
                      value: todayIncidents.toString(),
                      color: AppColors.info,
                      isLoading: isLoading,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      icon: Icons.message,
                      label: 'home.police.newMessages'.tr(),
                      value: unreadNotifications.toString(),
                      color: AppColors.primary,
                      isLoading: isLoading,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Recent incidents
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'incidents.title'.tr(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  TextButton(
                    onPressed: () {
                      // TODO: Navigate to all incidents
                    },
                    child: Text('common.next'.tr()),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Placeholder incident cards
              _buildIncidentCard(
                context,
                category: 'intelligence',
                title: 'Suspicious activity',
                location: 'Lat Phrao',
                time: '10 min ago',
              ),
              const SizedBox(height: 8),
              _buildIncidentCard(
                context,
                category: 'accident',
                title: 'Traffic accident',
                location: 'Ratchada',
                time: '25 min ago',
              ),
              const SizedBox(height: 8),
              _buildIncidentCard(
                context,
                category: 'general',
                title: 'General assistance request',
                location: 'Sukhumvit',
                time: '1 hour ago',
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        onTap: (index) {
          switch (index) {
            case 0:
              // Already on home, do nothing
              break;
            case 1:
              context.push('/incidents');
              break;
            case 2:
              context.push('/chat');
              break;
            case 3:
              context.push('/announcements');
              break;
            case 4:
              context.push('/profile');
              break;
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard),
            label: 'home.police.title'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.report),
            label: 'incidents.title'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.chat),
            label: 'chat.title'.tr(),
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

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isLoading = false,
  }) {
    return Container(
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
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                )
              : Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentCard(
    BuildContext context, {
    required String category,
    required String title,
    required String location,
    required String time,
  }) {
    Color categoryColor;
    IconData categoryIcon;

    switch (category) {
      case 'intelligence':
        categoryColor = AppColors.info;
        categoryIcon = Icons.lightbulb_outline;
        break;
      case 'accident':
        categoryColor = AppColors.error;
        categoryIcon = Icons.car_crash;
        break;
      default:
        categoryColor = AppColors.textSecondary;
        categoryIcon = Icons.help_outline;
    }

    return Container(
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
              color: categoryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              categoryIcon,
              color: categoryColor,
            ),
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
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      location,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      time,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
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
    );
  }
}
