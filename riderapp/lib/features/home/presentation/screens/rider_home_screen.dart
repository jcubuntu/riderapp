import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../navigation/app_router.dart';
import '../../../../shared/providers/stats_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class RiderHomeScreen extends ConsumerStatefulWidget {
  const RiderHomeScreen({super.key});

  @override
  ConsumerState<RiderHomeScreen> createState() => _RiderHomeScreenState();
}

class _RiderHomeScreenState extends ConsumerState<RiderHomeScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch dashboard stats on init (for unread notifications count)
    Future.microtask(() {
      ref.read(dashboardStatsProvider.notifier).fetchDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    // Watch stats for notifications badge
    final dashboardState = ref.watch(dashboardStatsProvider);
    int unreadNotifications = 0;

    if (dashboardState is DashboardStatsLoaded) {
      unreadNotifications = dashboardState.stats.unreadNotifications;
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text('home.rider.title'.tr()),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  context.push('/notifications');
                },
              ),
              if (unreadNotifications > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      unreadNotifications > 99
                          ? '99+'
                          : unreadNotifications.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              context.push(AppRoutes.profile);
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
                      'home.rider.welcome'.tr(namedArgs: {
                        'name': user?.fullName ?? 'Rider',
                      }),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'app.tagline'.tr(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Quick Actions
              Text(
                'home.rider.quickActions'.tr(),
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
                children: [
                  _buildActionCard(
                    context,
                    icon: Icons.report_problem,
                    label: 'home.rider.reportIncident'.tr(),
                    color: AppColors.error,
                    onTap: () {
                      context.push(AppRoutes.createIncident);
                    },
                  ),
                  _buildActionCard(
                    context,
                    icon: Icons.list_alt,
                    label: 'home.rider.viewReports'.tr(),
                    color: AppColors.info,
                    onTap: () {
                      context.push(AppRoutes.myIncidents);
                    },
                  ),
                  _buildActionCard(
                    context,
                    icon: Icons.chat,
                    label: 'home.rider.chat'.tr(),
                    color: AppColors.primary,
                    onTap: () {
                      context.push(AppRoutes.chat);
                    },
                  ),
                  _buildActionCard(
                    context,
                    icon: Icons.phone_in_talk,
                    label: 'home.rider.emergency'.tr(),
                    color: AppColors.warning,
                    onTap: () {
                      context.push(AppRoutes.emergency);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Announcements section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'announcements.title'.tr(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  TextButton(
                    onPressed: () {
                      context.push(AppRoutes.announcements);
                    },
                    child: Text('common.viewAll'.tr()),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Placeholder for announcements
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Center(
                  child: Text(
                    'announcements.noAnnouncements'.tr(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.large(
        onPressed: () {
          context.push('/emergency/sos');
        },
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sos, size: 32),
            Text(
              'SOS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
              context.push('/my-incidents');
              break;
            case 2:
              context.push('/chat');
              break;
            case 3:
              context.push('/profile');
              break;
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: 'home.rider.title'.tr(),
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
            icon: const Icon(Icons.person),
            label: 'profile.title'.tr(),
          ),
        ],
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
        padding: const EdgeInsets.all(20),
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
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 32,
                color: color,
              ),
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
