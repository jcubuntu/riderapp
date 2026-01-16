import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/auth/presentation/providers/auth_state.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/pending_approval_screen.dart';
import '../features/home/presentation/screens/rider_home_screen.dart';
import '../features/home/presentation/screens/volunteer_home_screen.dart';
import '../features/home/presentation/screens/police_home_screen.dart';
import '../features/home/presentation/screens/admin_home_screen.dart';
import '../features/home/presentation/screens/super_admin_home_screen.dart';
import '../features/incidents/presentation/screens/incidents_list_screen.dart';
import '../features/incidents/presentation/screens/incident_detail_screen.dart';
import '../features/incidents/presentation/screens/create_incident_screen.dart';
import '../features/announcements/presentation/screens/announcements_list_screen.dart';
import '../features/announcements/presentation/screens/announcement_detail_screen.dart';
import '../features/chat/presentation/screens/conversations_list_screen.dart';
import '../features/chat/presentation/screens/chat_screen.dart';
import '../features/emergency/presentation/screens/emergency_contacts_screen.dart';
import '../features/emergency/presentation/screens/sos_screen.dart';
import '../features/locations/presentation/screens/location_sharing_screen.dart';
import '../features/locations/presentation/screens/nearby_users_screen.dart';
import '../features/admin/presentation/screens/user_management_screen.dart';
import '../features/admin/presentation/screens/pending_approvals_screen.dart';
import '../features/admin/presentation/screens/statistics_screen.dart';
import '../features/admin/presentation/screens/system_config_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/profile/presentation/screens/edit_profile_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/settings/presentation/screens/notification_settings_screen.dart';
import '../features/notifications/presentation/screens/notifications_screen.dart';
import '../shared/models/user_model.dart';

/// Route names
abstract class AppRoutes {
  // Auth routes
  static const String login = '/login';
  static const String register = '/register';
  static const String pendingApproval = '/pending-approval';

  // Home routes
  static const String riderHome = '/rider';
  static const String volunteerHome = '/volunteer';
  static const String policeHome = '/police';
  static const String adminHome = '/admin';
  static const String superAdminHome = '/super-admin';

  // Feature routes (to be added)
  static const String incidents = '/incidents';
  static const String incidentDetail = '/incidents/:id';
  static const String createIncident = '/incidents/create';
  static const String myIncidents = '/my-incidents';
  static const String chat = '/chat';
  static const String chatDetail = '/chat/:id';
  static const String announcements = '/announcements';
  static const String announcementDetail = '/announcements/:id';
  static const String emergency = '/emergency';
  static const String sos = '/emergency/sos';
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String settings = '/settings';
  static const String notificationSettings = '/settings/notifications';
  static const String notifications = '/notifications';

  // Location routes
  static const String locationSharing = '/locations/sharing';
  static const String nearbyUsers = '/locations/nearby';
  static const String activeUsers = '/locations/active';

  // Admin routes
  static const String userManagement = '/admin/users';
  static const String pendingApprovals = '/admin/approvals';
  static const String statistics = '/admin/statistics';
  static const String systemConfig = '/admin/config';
}

/// Router provider
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: AppRoutes.login,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isAuthRoute = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register;
      final isPendingRoute = state.matchedLocation == AppRoutes.pendingApproval;

      // Handle different auth states
      switch (authState) {
        case AuthInitial():
        case AuthLoading():
          // Still loading, stay where we are
          return null;

        case AuthUnauthenticated():
        case AuthError():
          // Not logged in, redirect to login if not on auth route
          if (!isAuthRoute) {
            return AppRoutes.login;
          }
          return null;

        case AuthPendingApproval():
          // Pending approval, redirect to pending screen
          if (!isPendingRoute) {
            return AppRoutes.pendingApproval;
          }
          return null;

        case AuthRejected():
          // Rejected, redirect to login
          if (!isAuthRoute) {
            return AppRoutes.login;
          }
          return null;

        case AuthAuthenticated(user: final user):
          // Authenticated, redirect away from auth routes
          if (isAuthRoute || isPendingRoute) {
            return _getHomeRoute(user.role);
          }
          return null;
      }
    },
    routes: [
      // Auth routes
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.pendingApproval,
        name: 'pending-approval',
        builder: (context, state) => const PendingApprovalScreen(),
      ),

      // Rider routes
      GoRoute(
        path: AppRoutes.riderHome,
        name: 'rider-home',
        builder: (context, state) => const RiderHomeScreen(),
      ),

      // Volunteer routes
      GoRoute(
        path: AppRoutes.volunteerHome,
        name: 'volunteer-home',
        builder: (context, state) => const VolunteerHomeScreen(),
      ),

      // Police routes
      GoRoute(
        path: AppRoutes.policeHome,
        name: 'police-home',
        builder: (context, state) => const PoliceHomeScreen(),
      ),

      // Admin routes
      GoRoute(
        path: AppRoutes.adminHome,
        name: 'admin-home',
        builder: (context, state) => const AdminHomeScreen(),
      ),

      // Super Admin routes
      GoRoute(
        path: AppRoutes.superAdminHome,
        name: 'super-admin-home',
        builder: (context, state) => const SuperAdminHomeScreen(),
      ),

      // Incidents routes
      GoRoute(
        path: AppRoutes.incidents,
        name: 'incidents',
        builder: (context, state) => const IncidentsListScreen(),
      ),
      GoRoute(
        path: AppRoutes.createIncident,
        name: 'create-incident',
        builder: (context, state) => const CreateIncidentScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.incidents}/:id',
        name: 'incident-detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return IncidentDetailScreen(incidentId: id);
        },
      ),
      GoRoute(
        path: '${AppRoutes.incidents}/:id/edit',
        name: 'edit-incident',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return CreateIncidentScreen(incidentId: id);
        },
      ),

      // My Incidents route (for rider home)
      GoRoute(
        path: '/my-incidents',
        name: 'my-incidents',
        builder: (context, state) => const IncidentsListScreen(isMyIncidents: true),
      ),

      // Announcements routes
      GoRoute(
        path: AppRoutes.announcements,
        name: 'announcements',
        builder: (context, state) => const AnnouncementsListScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.announcements}/:id',
        name: 'announcement-detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return AnnouncementDetailScreen(announcementId: id);
        },
      ),

      // Chat routes
      GoRoute(
        path: AppRoutes.chat,
        name: 'chat',
        builder: (context, state) => const ConversationsListScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.chat}/:id',
        name: 'chat-detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ChatScreen(conversationId: id);
        },
      ),

      // Emergency routes
      GoRoute(
        path: AppRoutes.emergency,
        name: 'emergency',
        builder: (context, state) => const EmergencyContactsScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.emergency}/sos',
        name: 'sos',
        builder: (context, state) => const SosScreen(),
      ),

      // Profile routes
      GoRoute(
        path: AppRoutes.profile,
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        name: 'edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),

      // Settings routes
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.notificationSettings,
        name: 'notification-settings',
        builder: (context, state) => const NotificationSettingsScreen(),
      ),

      // Notifications route
      GoRoute(
        path: AppRoutes.notifications,
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),

      // Location routes
      GoRoute(
        path: AppRoutes.locationSharing,
        name: 'location-sharing',
        builder: (context, state) => const LocationSharingScreen(),
      ),
      GoRoute(
        path: AppRoutes.nearbyUsers,
        name: 'nearby-users',
        builder: (context, state) => const NearbyUsersScreen(),
      ),
      GoRoute(
        path: AppRoutes.activeUsers,
        name: 'active-users',
        builder: (context, state) => const NearbyUsersScreen(showActiveUsers: true),
      ),

      // Admin management routes
      GoRoute(
        path: AppRoutes.userManagement,
        name: 'user-management',
        builder: (context, state) => const UserManagementScreen(),
      ),
      GoRoute(
        path: AppRoutes.pendingApprovals,
        name: 'pending-approvals',
        builder: (context, state) => const PendingApprovalsScreen(),
      ),
      GoRoute(
        path: AppRoutes.statistics,
        name: 'statistics',
        builder: (context, state) => const StatisticsScreen(),
      ),
      GoRoute(
        path: AppRoutes.systemConfig,
        name: 'system-config',
        builder: (context, state) => const SystemConfigScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.matchedLocation,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.login),
              child: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    ),
  );
});

/// Get home route based on user role
String _getHomeRoute(UserRole role) {
  switch (role) {
    case UserRole.rider:
      return AppRoutes.riderHome;
    case UserRole.volunteer:
      return AppRoutes.volunteerHome;
    case UserRole.police:
      return AppRoutes.policeHome;
    case UserRole.admin:
      return AppRoutes.adminHome;
    case UserRole.superAdmin:
      return AppRoutes.superAdminHome;
  }
}
