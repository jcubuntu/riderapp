import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../navigation/app_router.dart';
import '../../../../shared/providers/stats_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class CommanderHomeScreen extends ConsumerStatefulWidget {
  const CommanderHomeScreen({super.key});

  @override
  ConsumerState<CommanderHomeScreen> createState() => _CommanderHomeScreenState();
}

class _CommanderHomeScreenState extends ConsumerState<CommanderHomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(dashboardStatsProvider.notifier).fetchDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final dashboardState = ref.watch(dashboardStatsProvider);

    int pendingReports = 0;
    int todayIncidents = 0;
    int pendingApprovals = 0;
    int totalUsers = 0;

    if (dashboardState is DashboardStatsLoaded) {
      pendingReports = dashboardState.stats.incidents.pending +
          dashboardState.stats.incidents.investigating;
      todayIncidents = dashboardState.stats.incidents.today;
      pendingApprovals = dashboardState.stats.users.pending;
      totalUsers = dashboardState.stats.users.total;
    }

    final isLoading = dashboardState is DashboardStatsLoading;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text('home.commander.title'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push(AppRoutes.notifications),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push(AppRoutes.profile),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authProvider.notifier).logout(),
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
              // Welcome card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'home.commander.welcome'.tr(namedArgs: {
                        'name': user?.fullName ?? 'Commander',
                      }),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'home.commander.subtitle'.tr(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Stats cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      icon: Icons.pending_actions,
                      label: 'home.commander.pendingReports'.tr(),
                      value: pendingReports.toString(),
                      color: AppColors.warning,
                      isLoading: isLoading,
                      onTap: () => context.push(AppRoutes.incidents),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      icon: Icons.today,
                      label: 'home.commander.todayIncidents'.tr(),
                      value: todayIncidents.toString(),
                      color: AppColors.info,
                      isLoading: isLoading,
                      onTap: () => context.push(AppRoutes.incidents),
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
                      icon: Icons.person_add,
                      label: 'home.commander.pendingApprovals'.tr(),
                      value: pendingApprovals.toString(),
                      color: AppColors.error,
                      isLoading: isLoading,
                      onTap: () => context.push(AppRoutes.pendingApprovals),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      icon: Icons.people,
                      label: 'home.commander.totalUsers'.tr(),
                      value: totalUsers.toString(),
                      color: AppColors.primary,
                      isLoading: isLoading,
                      onTap: () => context.push(AppRoutes.userManagement),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Quick Actions
              Text(
                'home.commander.quickActions'.tr(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),

              const SizedBox(height: 16),

              // Action Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.3,
                children: [
                  _buildActionCard(
                    context,
                    icon: Icons.report,
                    label: 'home.commander.viewIncidents'.tr(),
                    color: AppColors.info,
                    onTap: () => context.push(AppRoutes.incidents),
                  ),
                  _buildActionCard(
                    context,
                    icon: Icons.person_add,
                    label: 'home.commander.approveUsers'.tr(),
                    color: AppColors.warning,
                    onTap: () => context.push(AppRoutes.pendingApprovals),
                  ),
                  _buildActionCard(
                    context,
                    icon: Icons.chat,
                    label: 'home.commander.chat'.tr(),
                    color: AppColors.primary,
                    onTap: () => context.push(AppRoutes.chat),
                  ),
                  _buildActionCard(
                    context,
                    icon: Icons.campaign,
                    label: 'home.commander.announcements'.tr(),
                    color: AppColors.success,
                    onTap: () => context.push(AppRoutes.announcements),
                  ),
                ],
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
              break;
            case 1:
              context.push(AppRoutes.incidents);
              break;
            case 2:
              context.push(AppRoutes.chat);
              break;
            case 3:
              context.push(AppRoutes.userManagement);
              break;
            case 4:
              context.push(AppRoutes.profile);
              break;
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard),
            label: 'home.commander.title'.tr(),
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
            icon: const Icon(Icons.people),
            label: 'admin.userManagement'.tr(),
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
    VoidCallback? onTap,
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
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
