import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:integration_test/integration_test.dart';

import 'package:riderapp/core/constants/api_endpoints.dart';
import 'package:riderapp/core/theme/app_theme.dart';
import 'package:riderapp/navigation/app_router.dart';

/// Integration test helper utilities for RiderApp.
///
/// This file provides shared setup utilities, test user credentials,
/// and common widget finders for integration tests.
///
/// **IMPORTANT**: Integration tests require a running API server.
/// Before running tests, ensure the API server is running at the
/// configured base URL (default: http://localhost:3000/api/v1).
///
/// To run integration tests:
/// ```bash
/// # Start the API server first (in the api/ directory)
/// npm run dev
///
/// # Then run the integration tests
/// flutter test integration_test/
/// ```

// =============================================================================
// TEST USER CREDENTIALS
// =============================================================================

/// Test user credentials from the database (pre-approved users).
/// These users are seeded in the database for testing purposes.
abstract class TestUsers {
  /// Rider test user
  static const rider = TestUserCredentials(
    phone: '0811111111',
    password: 'Test1234',
    name: 'Test Rider',
    role: 'rider',
  );

  /// Volunteer test user
  static const volunteer = TestUserCredentials(
    phone: '0822222222',
    password: 'Test1234',
    name: 'Test Volunteer',
    role: 'volunteer',
  );

  /// Police test user
  static const police = TestUserCredentials(
    phone: '0833333333',
    password: 'Test1234',
    name: 'Test Police',
    role: 'police',
  );

  /// Admin test user
  static const admin = TestUserCredentials(
    phone: '0844444444',
    password: 'Test1234',
    name: 'Test Admin',
    role: 'admin',
  );

  /// Super Admin test user
  static const superAdmin = TestUserCredentials(
    phone: '0855555555',
    password: 'Test1234',
    name: 'Test Super Admin',
    role: 'super_admin',
  );

  /// Invalid user for testing error cases
  static const invalidUser = TestUserCredentials(
    phone: '0999999999',
    password: 'WrongPassword',
    name: 'Invalid User',
    role: 'rider',
  );
}

/// Test user credentials data class.
class TestUserCredentials {
  final String phone;
  final String password;
  final String name;
  final String role;

  const TestUserCredentials({
    required this.phone,
    required this.password,
    required this.name,
    required this.role,
  });
}

// =============================================================================
// TEST CONFIGURATION
// =============================================================================

/// Test configuration settings.
abstract class TestConfig {
  /// API base URL for testing.
  /// Override this if your test server runs on a different port.
  static String get apiBaseUrl => ApiEndpoints.devBaseUrl;

  /// Timeout for API calls during tests (in seconds).
  static const int apiTimeout = 30;

  /// Timeout for waiting for widgets to appear.
  static const Duration widgetTimeout = Duration(seconds: 10);

  /// Default pump duration for settling animations.
  static const Duration pumpDuration = Duration(milliseconds: 100);

  /// Pump duration for waiting for API responses.
  static const Duration apiPumpDuration = Duration(seconds: 3);
}

// =============================================================================
// COMMON WIDGET FINDERS
// =============================================================================

/// Common widget finders for integration tests.
abstract class AppFinders {
  // ---------------------------------------------------------------------------
  // Login Screen Finders
  // ---------------------------------------------------------------------------

  /// Phone number text field
  static Finder get phoneField =>
      find.byType(TextFormField).at(0);

  /// Password text field
  static Finder get passwordField =>
      find.byType(TextFormField).at(1);

  /// Login button
  static Finder get loginButton =>
      find.byType(ElevatedButton).first;

  /// Register link/button
  static Finder get registerLink =>
      find.text('auth.register'.tr());

  // ---------------------------------------------------------------------------
  // Register Screen Finders
  // ---------------------------------------------------------------------------

  /// Full name text field (index 0 on register screen)
  static Finder get fullNameField =>
      find.byType(TextFormField).at(0);

  /// ID card number text field (index 1 on register screen)
  static Finder get idCardField =>
      find.byType(TextFormField).at(1);

  /// Phone field on register screen (index 2)
  static Finder get registerPhoneField =>
      find.byType(TextFormField).at(2);

  /// Password field on register screen (index 3)
  static Finder get registerPasswordField =>
      find.byType(TextFormField).at(3);

  /// Confirm password field on register screen (index 4)
  static Finder get confirmPasswordField =>
      find.byType(TextFormField).at(4);

  /// Register submit button
  static Finder get registerSubmitButton =>
      find.byType(ElevatedButton).first;

  // ---------------------------------------------------------------------------
  // Home Screen Finders
  // ---------------------------------------------------------------------------

  /// Logout button/icon
  static Finder get logoutButton =>
      find.byIcon(Icons.logout);

  /// Profile button/icon
  static Finder get profileButton =>
      find.byIcon(Icons.person_outline);

  /// Notifications button/icon
  static Finder get notificationsButton =>
      find.byIcon(Icons.notifications_outlined);

  /// Bottom navigation bar
  static Finder get bottomNavBar =>
      find.byType(BottomNavigationBar);

  /// Home navigation item (index 0)
  static Finder get homeNavItem =>
      find.byIcon(Icons.home);

  /// Incidents navigation item (index 1)
  static Finder get incidentsNavItem =>
      find.byIcon(Icons.report);

  /// Chat navigation item (index 2)
  static Finder get chatNavItem =>
      find.byIcon(Icons.chat);

  /// Profile navigation item (index 3)
  static Finder get profileNavItem =>
      find.byIcon(Icons.person);

  // ---------------------------------------------------------------------------
  // Incidents Screen Finders
  // ---------------------------------------------------------------------------

  /// Create incident FAB
  static Finder get createIncidentFab =>
      find.byType(FloatingActionButton);

  /// Incident list
  static Finder get incidentList =>
      find.byType(ListView);

  /// Search field in incidents
  static Finder get incidentSearchField =>
      find.byType(TextField);

  /// Filter button
  static Finder get filterButton =>
      find.byIcon(Icons.filter_list);

  // ---------------------------------------------------------------------------
  // Create Incident Screen Finders
  // ---------------------------------------------------------------------------

  /// Incident title field
  static Finder get incidentTitleField =>
      find.byType(TextFormField).first;

  /// Incident description field
  static Finder get incidentDescriptionField =>
      find.byType(TextFormField).at(1);

  /// Submit incident button
  static Finder get submitIncidentButton =>
      find.byType(FilledButton).first;

  // ---------------------------------------------------------------------------
  // General Finders
  // ---------------------------------------------------------------------------

  /// Loading indicator
  static Finder get loadingIndicator =>
      find.byType(CircularProgressIndicator);

  /// Snackbar
  static Finder get snackbar =>
      find.byType(SnackBar);

  /// Error icon
  static Finder get errorIcon =>
      find.byIcon(Icons.error_outline);

  /// Back button
  static Finder get backButton =>
      find.byType(BackButton);

  /// App bar back button (alternative)
  static Finder get appBarBackButton =>
      find.byTooltip('Back');
}

// =============================================================================
// TEST HELPER FUNCTIONS
// =============================================================================

/// Initialize the integration test binding.
///
/// Call this at the beginning of your test file's main() function.
IntegrationTestWidgetsFlutterBinding initializeIntegrationTest() {
  return IntegrationTestWidgetsFlutterBinding.ensureInitialized();
}

/// Pump the app widget with all necessary providers.
///
/// This creates the app with EasyLocalization and ProviderScope
/// properly configured for testing.
Future<void> pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [
        Locale('th'),
        Locale('en'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: const ProviderScope(
        child: _TestApp(),
      ),
    ),
  );

  // Wait for localization to initialize
  await tester.pumpAndSettle();
}

/// Internal test app widget
class _TestApp extends ConsumerWidget {
  const _TestApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'RiderApp Integration Test',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}

// =============================================================================
// TESTER EXTENSION METHODS
// =============================================================================

/// Extension methods for WidgetTester to simplify common operations.
extension IntegrationTestExtensions on WidgetTester {
  /// Enter text in a text field after finding it.
  Future<void> enterTextInField(Finder finder, String text) async {
    await tap(finder);
    await pumpAndSettle();
    await enterText(finder, text);
    await pumpAndSettle();
  }

  /// Tap a widget and wait for animations to settle.
  Future<void> tapAndSettle(Finder finder) async {
    await tap(finder);
    await pumpAndSettle();
  }

  /// Wait for a specific duration (useful for API calls).
  Future<void> wait(Duration duration) async {
    await Future.delayed(duration);
    await pumpAndSettle();
  }

  /// Wait for a widget to appear with timeout.
  Future<void> waitForWidget(
    Finder finder, {
    Duration timeout = TestConfig.widgetTimeout,
  }) async {
    final endTime = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(endTime)) {
      await pump(const Duration(milliseconds: 100));

      if (finder.evaluate().isNotEmpty) {
        await pumpAndSettle();
        return;
      }
    }

    // If widget not found, let the test fail with proper error
    expect(finder, findsOneWidget);
  }

  /// Wait for a widget to disappear with timeout.
  Future<void> waitForWidgetToDisappear(
    Finder finder, {
    Duration timeout = TestConfig.widgetTimeout,
  }) async {
    final endTime = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(endTime)) {
      await pump(const Duration(milliseconds: 100));

      if (finder.evaluate().isEmpty) {
        await pumpAndSettle();
        return;
      }
    }

    // If widget still present, let the test fail with proper error
    expect(finder, findsNothing);
  }

  /// Perform login with given credentials.
  Future<void> login(TestUserCredentials user) async {
    // Find and enter phone
    await enterTextInField(AppFinders.phoneField, user.phone);

    // Find and enter password
    await enterTextInField(AppFinders.passwordField, user.password);

    // Tap login button
    await tapAndSettle(AppFinders.loginButton);

    // Wait for API response and navigation
    await wait(TestConfig.apiPumpDuration);
  }

  /// Perform logout.
  Future<void> logout() async {
    await tapAndSettle(AppFinders.logoutButton);
    await wait(TestConfig.apiPumpDuration);
  }

  /// Navigate using bottom navigation bar.
  Future<void> navigateToTab(int index) async {
    final bottomNav = find.byType(BottomNavigationBar);
    expect(bottomNav, findsOneWidget);

    final navItems = find.descendant(
      of: bottomNav,
      matching: find.byType(InkResponse),
    );

    await tap(navItems.at(index));
    await pumpAndSettle();
  }

  /// Scroll down in a list.
  Future<void> scrollDown({double pixels = 300}) async {
    await drag(find.byType(Scrollable).first, Offset(0, -pixels));
    await pumpAndSettle();
  }

  /// Scroll up in a list.
  Future<void> scrollUp({double pixels = 300}) async {
    await drag(find.byType(Scrollable).first, Offset(0, pixels));
    await pumpAndSettle();
  }

  /// Pull to refresh.
  Future<void> pullToRefresh() async {
    await drag(find.byType(Scrollable).first, const Offset(0, 300));
    await pumpAndSettle();
    await wait(TestConfig.apiPumpDuration);
  }
}

// =============================================================================
// CUSTOM MATCHERS
// =============================================================================

/// Matcher to check if a widget is visible on screen.
Matcher isVisible() => _IsVisibleMatcher();

class _IsVisibleMatcher extends Matcher {
  @override
  bool matches(dynamic item, Map matchState) {
    if (item is Finder) {
      return item.evaluate().isNotEmpty;
    }
    return false;
  }

  @override
  Description describe(Description description) {
    return description.add('widget is visible');
  }
}

/// Matcher to check if text contains a substring.
Matcher containsText(String substring) => _ContainsTextMatcher(substring);

class _ContainsTextMatcher extends Matcher {
  final String substring;

  _ContainsTextMatcher(this.substring);

  @override
  bool matches(dynamic item, Map matchState) {
    if (item is String) {
      return item.contains(substring);
    }
    return false;
  }

  @override
  Description describe(Description description) {
    return description.add('contains "$substring"');
  }
}

// =============================================================================
// MOCK DATA FOR TESTING
// =============================================================================

/// Mock incident data for creating test incidents.
abstract class MockIncidentData {
  static const testIncident = {
    'title': 'Integration Test Incident',
    'description': 'This is a test incident created during integration testing. Please ignore.',
    'category': 'general',
    'priority': 'medium',
    'address': 'Test Address',
    'province': 'Bangkok',
    'district': 'Chatuchak',
  };

  static const updatedIncident = {
    'title': 'Updated Integration Test Incident',
    'description': 'This incident has been updated during integration testing.',
  };
}
