import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:riderapp/shared/models/user_model.dart';
import 'package:riderapp/shared/models/dashboard_stats_model.dart';
import 'package:riderapp/features/auth/presentation/providers/auth_state.dart';
import 'package:riderapp/features/notifications/presentation/providers/notifications_state.dart';
import 'package:riderapp/features/notifications/domain/entities/app_notification.dart';
import 'package:riderapp/shared/providers/stats_provider.dart';

// =============================================================================
// Localization Test Setup
// =============================================================================

/// Initialize localization for tests - call this in setUpAll
Future<void> initializeTestLocalization() async {
  // Initialize SharedPreferences with empty values for tests
  SharedPreferences.setMockInitialValues({});
  await EasyLocalization.ensureInitialized();
}

/// Mock translations map for testing
/// This provides fallback values when easy_localization is not fully initialized
const Map<String, String> mockTranslations = {
  'app.name': 'RiderApp',
  'app.tagline': 'Safety Coordination Platform',
  'auth.phoneNumber': 'Phone Number',
  'auth.password': 'Password',
  'auth.forgotPassword': 'Forgot Password?',
  'auth.loginButton': 'Sign In',
  'auth.noAccount': "Don't have an account?",
  'auth.register': 'Register',
  'auth.validation.phoneRequired': 'Phone number is required',
  'auth.validation.phoneInvalid': 'Please enter a valid phone number',
  'auth.validation.passwordRequired': 'Password is required',
  'auth.validation.passwordTooShort': 'Password must be at least 8 characters',
  'home.rider.title': 'Home',
  'home.rider.welcome': 'Welcome',
  'home.rider.quickActions': 'Quick Actions',
  'home.rider.reportIncident': 'Report Incident',
  'home.rider.viewReports': 'My Reports',
  'home.rider.chat': 'Chat with Police',
  'home.rider.emergency': 'Emergency Contacts',
  'incidents.title': 'Incidents',
  'chat.title': 'Messages',
  'profile.title': 'Profile',
  'announcements.title': 'Announcements',
  'announcements.noAnnouncements': 'No announcements',
  'common.next': 'Next',
  'notifications.title': 'Notifications',
  'notifications.empty': 'No notifications',
  'notifications.markAllRead': 'Mark all as read',
};

// =============================================================================
// Test User Factory
// =============================================================================

/// Factory for creating test users with different roles
class TestUserFactory {
  static UserModel createRider({
    String id = 'test-rider-id',
    String phone = '0811111111',
    String fullName = 'Test Rider',
    UserStatus status = UserStatus.approved,
  }) {
    return UserModel(
      id: id,
      phone: phone,
      fullName: fullName,
      role: UserRole.rider,
      status: status,
      createdAt: DateTime.now(),
    );
  }

  static UserModel createVolunteer({
    String id = 'test-volunteer-id',
    String phone = '0822222222',
    String fullName = 'Test Volunteer',
    UserStatus status = UserStatus.approved,
  }) {
    return UserModel(
      id: id,
      phone: phone,
      fullName: fullName,
      role: UserRole.volunteer,
      status: status,
      createdAt: DateTime.now(),
    );
  }

  static UserModel createPolice({
    String id = 'test-police-id',
    String phone = '0833333333',
    String fullName = 'Test Police',
    UserStatus status = UserStatus.approved,
  }) {
    return UserModel(
      id: id,
      phone: phone,
      fullName: fullName,
      role: UserRole.police,
      status: status,
      createdAt: DateTime.now(),
    );
  }

  static UserModel createAdmin({
    String id = 'test-admin-id',
    String phone = '0844444444',
    String fullName = 'Test Admin',
    UserStatus status = UserStatus.approved,
  }) {
    return UserModel(
      id: id,
      phone: phone,
      fullName: fullName,
      role: UserRole.admin,
      status: status,
      createdAt: DateTime.now(),
    );
  }

  static UserModel createSuperAdmin({
    String id = 'test-super-admin-id',
    String phone = '0855555555',
    String fullName = 'Test Super Admin',
    UserStatus status = UserStatus.approved,
  }) {
    return UserModel(
      id: id,
      phone: phone,
      fullName: fullName,
      role: UserRole.superAdmin,
      status: status,
      createdAt: DateTime.now(),
    );
  }

  static UserModel createPendingUser({
    String id = 'test-pending-id',
    String phone = '0899999999',
    String fullName = 'Test Pending User',
  }) {
    return UserModel(
      id: id,
      phone: phone,
      fullName: fullName,
      role: UserRole.rider,
      status: UserStatus.pending,
      createdAt: DateTime.now(),
    );
  }
}

// =============================================================================
// Test Notification Factory
// =============================================================================

/// Factory for creating test notifications
class TestNotificationFactory {
  static AppNotification create({
    String id = 'test-notification-id',
    String title = 'Test Notification',
    String body = 'This is a test notification body',
    NotificationType type = NotificationType.system,
    String? targetId,
    bool isRead = false,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      type: type,
      targetId: targetId,
      isRead: isRead,
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  static AppNotification createChatNotification({
    String id = 'chat-notification-id',
    String title = 'New Message',
    String body = 'You have a new message',
    String? targetId = 'chat-123',
    bool isRead = false,
  }) {
    return create(
      id: id,
      title: title,
      body: body,
      type: NotificationType.chat,
      targetId: targetId,
      isRead: isRead,
    );
  }

  static AppNotification createIncidentNotification({
    String id = 'incident-notification-id',
    String title = 'Incident Update',
    String body = 'Your incident has been updated',
    String? targetId = 'incident-123',
    bool isRead = false,
  }) {
    return create(
      id: id,
      title: title,
      body: body,
      type: NotificationType.incident,
      targetId: targetId,
      isRead: isRead,
    );
  }

  static AppNotification createSOSNotification({
    String id = 'sos-notification-id',
    String title = 'SOS Alert',
    String body = 'Emergency alert nearby',
    String? targetId = 'sos-123',
    bool isRead = false,
  }) {
    return create(
      id: id,
      title: title,
      body: body,
      type: NotificationType.sos,
      targetId: targetId,
      isRead: isRead,
    );
  }

  static AppNotification createAnnouncementNotification({
    String id = 'announcement-notification-id',
    String title = 'New Announcement',
    String body = 'Check out the latest announcement',
    String? targetId = 'announcement-123',
    bool isRead = false,
  }) {
    return create(
      id: id,
      title: title,
      body: body,
      type: NotificationType.announcement,
      targetId: targetId,
      isRead: isRead,
    );
  }

  static AppNotification createApprovalNotification({
    String id = 'approval-notification-id',
    String title = 'Account Approved',
    String body = 'Your account has been approved',
    bool isRead = false,
  }) {
    return create(
      id: id,
      title: title,
      body: body,
      type: NotificationType.approval,
      isRead: isRead,
    );
  }

  static List<AppNotification> createList(int count, {bool allRead = false}) {
    return List.generate(
      count,
      (index) => create(
        id: 'notification-$index',
        title: 'Notification $index',
        body: 'Body for notification $index',
        isRead: allRead || index % 2 == 0,
        createdAt: DateTime.now().subtract(Duration(hours: index)),
      ),
    );
  }
}

// =============================================================================
// Test Dashboard Stats Factory
// =============================================================================

/// Factory for creating test dashboard stats
class TestDashboardStatsFactory {
  static DashboardStats create({
    int totalIncidents = 10,
    int todayIncidents = 2,
    int pendingIncidents = 3,
    int investigatingIncidents = 2,
    int resolvedIncidents = 5,
    int totalUsers = 100,
    int pendingUsers = 5,
    int approvedUsers = 90,
    int riders = 70,
    int volunteers = 15,
    int police = 10,
    int unreadNotifications = 3,
    int activeSosAlerts = 0,
  }) {
    return DashboardStats(
      incidents: IncidentCounts(
        total: totalIncidents,
        today: todayIncidents,
        pending: pendingIncidents,
        investigating: investigatingIncidents,
        resolved: resolvedIncidents,
      ),
      users: UserCounts(
        total: totalUsers,
        pending: pendingUsers,
        approved: approvedUsers,
        riders: riders,
        volunteers: volunteers,
        police: police,
      ),
      recentIncidents: [],
      recentAnnouncements: [],
      unreadNotifications: unreadNotifications,
      activeSosAlerts: activeSosAlerts,
    );
  }

  static DashboardStats createEmpty() {
    return DashboardStats.empty();
  }
}

// =============================================================================
// Mock Providers - Simple State Notifiers for Testing
// =============================================================================

/// Mock auth notifier for testing - extends StateNotifier directly
class MockAuthNotifier extends StateNotifier<AuthState> {
  MockAuthNotifier([AuthState? initialState])
      : super(initialState ?? const AuthUnauthenticated());

  // Expose state setter for tests
  @override
  set state(AuthState value) => super.state = value;

  void setAuthenticated(UserModel user, {String accessToken = 'test-token'}) {
    state = AuthAuthenticated(user: user, accessToken: accessToken);
  }

  void setUnauthenticated() {
    state = const AuthUnauthenticated();
  }

  void setLoading() {
    state = const AuthLoading();
  }

  void setError(String message) {
    state = AuthError(message);
  }

  void setPendingApproval(UserModel user) {
    state = AuthPendingApproval(user: user);
  }

  void setRejected(UserModel user, {String? reason}) {
    state = AuthRejected(user: user, reason: reason);
  }

  Future<void> login({required String phone, required String password}) async {
    state = const AuthLoading();
    // Simulate login - in tests, call setAuthenticated after this
  }

  Future<void> logout() async {
    state = const AuthUnauthenticated();
  }

  void updateUser(UserModel user) {
    if (state is AuthAuthenticated) {
      state = AuthAuthenticated(
        user: user,
        accessToken: (state as AuthAuthenticated).accessToken,
      );
    }
  }

  void clearError() {
    if (state is AuthError) {
      state = const AuthUnauthenticated();
    }
  }
}

/// Mock notifications notifier for testing
class MockNotificationsNotifier extends StateNotifier<NotificationsState> {
  MockNotificationsNotifier([NotificationsState? initialState])
      : super(initialState ?? const NotificationsInitial());

  // Expose state setter for tests
  @override
  set state(NotificationsState value) => super.state = value;

  void setLoading() {
    state = const NotificationsLoading();
  }

  void setLoaded({
    List<AppNotification>? notifications,
    int total = 0,
    int page = 1,
    int totalPages = 1,
    int unreadCount = 0,
    bool isLoadingMore = false,
    bool isMarkingAllRead = false,
    String? deletingId,
  }) {
    state = NotificationsLoaded(
      notifications: notifications ?? [],
      total: total,
      page: page,
      totalPages: totalPages,
      unreadCount: unreadCount,
      isLoadingMore: isLoadingMore,
      isMarkingAllRead: isMarkingAllRead,
      deletingId: deletingId,
    );
  }

  void setError(String message) {
    state = NotificationsError(message);
  }

  Future<void> loadNotifications({bool refresh = false}) async {
    // Mock implementation
  }

  Future<void> loadMore() async {
    // Mock implementation
  }

  Future<void> markAsRead(String notificationId) async {
    // Mock implementation
  }

  Future<void> markAllAsRead() async {
    // Mock implementation
  }

  Future<void> deleteNotification(String notificationId) async {
    // Mock implementation
  }

  Future<void> clearAllNotifications() async {
    // Mock implementation
  }

  Future<void> refresh() async {
    // Mock implementation
  }
}

/// Mock dashboard stats notifier for testing
class MockDashboardStatsNotifier extends StateNotifier<DashboardStatsState> {
  MockDashboardStatsNotifier([DashboardStatsState? initialState])
      : super(initialState ?? const DashboardStatsInitial());

  // Expose state setter for tests
  @override
  set state(DashboardStatsState value) => super.state = value;

  void setLoading() {
    state = const DashboardStatsLoading();
  }

  void setLoaded(DashboardStats stats) {
    state = DashboardStatsLoaded(stats);
  }

  void setError(String message) {
    state = DashboardStatsError(message);
  }

  Future<void> fetchDashboard({int recentLimit = 5}) async {
    // Mock implementation
  }

  Future<void> refresh() async {
    // Mock implementation
  }
}


// =============================================================================
// Widget Test Wrapper
// =============================================================================

/// A wrapper widget that provides all necessary providers and configuration
/// for widget testing. This wrapper bypasses easy_localization issues in tests
/// by using a simple MaterialApp without the EasyLocalization widget.
class WidgetTestWrapper extends StatelessWidget {
  final Widget child;
  final List<Override>? providerOverrides;
  final GoRouter? router;
  final Locale? locale;

  const WidgetTestWrapper({
    super.key,
    required this.child,
    this.providerOverrides,
    this.router,
    this.locale,
  });

  @override
  Widget build(BuildContext context) {
    Widget app = MaterialApp(
      home: child,
      locale: locale ?? const Locale('en'),
      localizationsDelegates: const [
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('th'),
      ],
    );

    return ProviderScope(
      overrides: providerOverrides ?? [],
      child: app,
    );
  }
}

/// A test wrapper that provides EasyLocalization support for widget tests.
/// Use this when testing widgets that use .tr() translations.
class LocalizedWidgetTestWrapper extends StatelessWidget {
  final Widget child;
  final List<Override>? providerOverrides;
  final Locale? locale;

  const LocalizedWidgetTestWrapper({
    super.key,
    required this.child,
    this.providerOverrides,
    this.locale,
  });

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: providerOverrides ?? [],
      child: EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('th')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        useOnlyLangCode: true,
        child: Builder(
          builder: (context) {
            return MaterialApp(
              home: child,
              locale: locale ?? context.locale,
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
            );
          },
        ),
      ),
    );
  }
}

/// A wrapper widget that provides GoRouter for navigation testing
class NavigationTestWrapper extends StatelessWidget {
  final Widget child;
  final List<Override>? providerOverrides;
  final GoRouter? router;
  final String initialLocation;
  final Locale? locale;

  const NavigationTestWrapper({
    super.key,
    required this.child,
    this.providerOverrides,
    this.router,
    this.initialLocation = '/',
    this.locale,
  });

  @override
  Widget build(BuildContext context) {
    final testRouter = router ??
        GoRouter(
          initialLocation: initialLocation,
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => child,
            ),
            // Add common routes for testing navigation
            GoRoute(
              path: '/register',
              builder: (context, state) => const Scaffold(
                body: Center(child: Text('Register Screen')),
              ),
            ),
            GoRoute(
              path: '/login',
              builder: (context, state) => const Scaffold(
                body: Center(child: Text('Login Screen')),
              ),
            ),
            GoRoute(
              path: '/notifications',
              builder: (context, state) => const Scaffold(
                body: Center(child: Text('Notifications Screen')),
              ),
            ),
            GoRoute(
              path: '/profile',
              builder: (context, state) => const Scaffold(
                body: Center(child: Text('Profile Screen')),
              ),
            ),
            GoRoute(
              path: '/my-incidents',
              builder: (context, state) => const Scaffold(
                body: Center(child: Text('My Incidents Screen')),
              ),
            ),
            GoRoute(
              path: '/chat',
              builder: (context, state) => const Scaffold(
                body: Center(child: Text('Chat Screen')),
              ),
            ),
            GoRoute(
              path: '/chat/:id',
              builder: (context, state) => Scaffold(
                body: Center(
                    child:
                        Text('Chat Detail Screen ${state.pathParameters['id']}')),
              ),
            ),
            GoRoute(
              path: '/incidents/:id',
              builder: (context, state) => Scaffold(
                body: Center(
                    child: Text(
                        'Incident Detail Screen ${state.pathParameters['id']}')),
              ),
            ),
            GoRoute(
              path: '/announcements/:id',
              builder: (context, state) => Scaffold(
                body: Center(
                    child: Text(
                        'Announcement Detail Screen ${state.pathParameters['id']}')),
              ),
            ),
          ],
        );

    Widget app = MaterialApp.router(
      routerConfig: testRouter,
      locale: locale ?? const Locale('en'),
      localizationsDelegates: const [
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('th'),
      ],
    );

    return ProviderScope(
      overrides: providerOverrides ?? [],
      child: app,
    );
  }
}

// =============================================================================
// Test Utilities
// =============================================================================

/// Helper function to pump widget with necessary providers.
/// Uses controlled pump calls instead of pumpAndSettle to avoid timeouts.
Future<void> pumpWidgetWithProviders(
  WidgetTester tester,
  Widget widget, {
  List<Override>? overrides,
  bool settle = false,
  int pumpFrames = 5,
  Duration pumpDuration = const Duration(milliseconds: 100),
}) async {
  await tester.pumpWidget(
    WidgetTestWrapper(
      providerOverrides: overrides,
      child: widget,
    ),
  );

  if (settle) {
    // Use pumpAndSettle with a timeout to prevent infinite loops
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 5),
    );
  } else {
    // Use controlled pump calls
    for (var i = 0; i < pumpFrames; i++) {
      await tester.pump(pumpDuration);
    }
  }
}

/// Helper function to pump widget with navigation support.
/// Uses controlled pump calls instead of pumpAndSettle to avoid timeouts.
Future<void> pumpWidgetWithNavigation(
  WidgetTester tester,
  Widget widget, {
  List<Override>? overrides,
  String initialLocation = '/',
  bool settle = false,
  int pumpFrames = 5,
  Duration pumpDuration = const Duration(milliseconds: 100),
}) async {
  await tester.pumpWidget(
    NavigationTestWrapper(
      providerOverrides: overrides,
      initialLocation: initialLocation,
      child: widget,
    ),
  );

  if (settle) {
    // Use pumpAndSettle with a timeout
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 5),
    );
  } else {
    // Use controlled pump calls
    for (var i = 0; i < pumpFrames; i++) {
      await tester.pump(pumpDuration);
    }
  }
}

/// Safely pump frames without using pumpAndSettle.
/// This is useful for widgets with infinite animations.
Future<void> pumpFrames(
  WidgetTester tester, {
  int frames = 5,
  Duration duration = const Duration(milliseconds: 100),
}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(duration);
  }
}

/// Try pumpAndSettle with a timeout, falling back to pump if it times out.
Future<void> safePumpAndSettle(
  WidgetTester tester, {
  Duration timeout = const Duration(seconds: 2),
  int fallbackPumpFrames = 10,
}) async {
  try {
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      timeout,
    );
  } catch (_) {
    // If pumpAndSettle times out, use pump instead
    for (var i = 0; i < fallbackPumpFrames; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }
}

/// Helper function to pump widget and wait for EasyLocalization to load.
/// Uses runAsync to properly handle asynchronous asset loading.
/// This is the recommended way to test widgets that use easy_localization.
///
/// Example:
/// ```dart
/// testWidgets('my test', (tester) async {
///   await pumpAndWait(tester, buildMyWidget());
///   expect(find.byType(MyWidget), findsOneWidget);
/// });
/// ```
Future<void> pumpAndWait(
  WidgetTester tester,
  Widget widget, {
  Duration asyncDelay = const Duration(milliseconds: 500),
  int pumpFrames = 20,
  Duration pumpDuration = const Duration(milliseconds: 50),
}) async {
  await tester.runAsync(() async {
    await tester.pumpWidget(widget);
    // Allow time for EasyLocalization to load assets
    await Future.delayed(asyncDelay);
  });
  // Pump frames to render the UI
  for (var i = 0; i < pumpFrames; i++) {
    await tester.pump(pumpDuration);
  }
}

// =============================================================================
// Common Finder Extensions
// =============================================================================

/// Extension methods for common finders in tests
extension WidgetTesterExtensions on WidgetTester {
  /// Find and tap a widget by key
  Future<void> tapByKey(Key key) async {
    await tap(find.byKey(key));
    await pump();
  }

  /// Find and tap a widget by type
  Future<void> tapByType(Type type) async {
    await tap(find.byType(type));
    await pump();
  }

  /// Find and tap a widget by text
  Future<void> tapByText(String text) async {
    await tap(find.text(text));
    await pump();
  }

  /// Find and tap a widget by icon
  Future<void> tapByIcon(IconData icon) async {
    await tap(find.byIcon(icon));
    await pump();
  }

  /// Enter text in a TextField by key
  Future<void> enterTextByKey(Key key, String text) async {
    await enterText(find.byKey(key), text);
    await pump();
  }

  /// Enter text in first TextField found
  Future<void> enterTextInFirst(String text) async {
    await enterText(find.byType(TextField).first, text);
    await pump();
  }

  /// Scroll until widget is visible
  Future<void> scrollUntilVisible(
    Finder finder, {
    double delta = 100,
    int maxScrolls = 50,
    Finder? scrollable,
  }) async {
    final scrollableFinder = scrollable ?? find.byType(Scrollable).first;
    int scrollAttempts = 0;

    while (finder.evaluate().isEmpty && scrollAttempts < maxScrolls) {
      await drag(scrollableFinder, Offset(0, -delta));
      await pumpAndSettle();
      scrollAttempts++;
    }
  }

  /// Swipe to dismiss a Dismissible widget
  Future<void> swipeToDismiss(Finder finder,
      {DismissDirection direction = DismissDirection.endToStart}) async {
    final offset = direction == DismissDirection.endToStart
        ? const Offset(-500, 0)
        : const Offset(500, 0);
    await drag(finder, offset);
    await pumpAndSettle();
  }
}
