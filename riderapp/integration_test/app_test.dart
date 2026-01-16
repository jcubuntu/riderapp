import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'test_helper.dart';

/// Main integration test runner for RiderApp.
///
/// This file serves as the entry point for running all integration tests
/// together or for running a quick smoke test of the application.
///
/// ## Prerequisites
///
/// Before running integration tests, ensure:
///
/// 1. **API Server is running:**
///    ```bash
///    cd api && npm run dev
///    ```
///
/// 2. **Test users exist in database:**
///    The following test users should be seeded:
///    - Rider: 0811111111 / Test1234
///    - Volunteer: 0822222222 / Test1234
///    - Police: 0833333333 / Test1234
///    - Admin: 0844444444 / Test1234
///    - Super Admin: 0855555555 / Test1234
///
/// 3. **Emulator/Device is running:**
///    For Android: `flutter emulators --launch <emulator_id>`
///    For iOS: Xcode Simulator or physical device
///
/// ## Running Tests
///
/// **Run all integration tests:**
/// ```bash
/// flutter test integration_test/
/// ```
///
/// **Run a specific test file:**
/// ```bash
/// flutter test integration_test/auth_flow_test.dart
/// flutter test integration_test/incidents_flow_test.dart
/// flutter test integration_test/navigation_flow_test.dart
/// ```
///
/// **Run on a specific device:**
/// ```bash
/// flutter test integration_test/ -d <device_id>
/// ```
///
/// **Run with coverage:**
/// ```bash
/// flutter test integration_test/ --coverage
/// ```
///
/// ## Test Categories
///
/// The integration tests are organized into the following categories:
///
/// - **auth_flow_test.dart**: Authentication flows (login, register, logout)
/// - **incidents_flow_test.dart**: Incident management flows (create, view, update)
/// - **navigation_flow_test.dart**: Navigation and routing tests
///
/// ## Notes
///
/// - Integration tests run against a real (test) API server
/// - Each test group is independent and can be run separately
/// - Screenshots are captured at key points for documentation
/// - Tests may be flaky if the API is slow or unavailable
void main() {
  final binding = initializeIntegrationTest();

  group('RiderApp Integration Tests - Smoke Test', () {
    testWidgets(
      'App should launch successfully',
      (WidgetTester tester) async {
        // Arrange
        await pumpApp(tester);
        await tester.pumpAndSettle();

        // Assert - App should be on login screen
        expect(
          find.byType(MaterialApp).first,
          findsOneWidget,
          reason: 'App should launch successfully',
        );

        // Take screenshot
        await binding.takeScreenshot('smoke_app_launched');
      },
    );

    testWidgets(
      'Should show login screen on initial launch',
      (WidgetTester tester) async {
        // Arrange
        await pumpApp(tester);
        await tester.pumpAndSettle();

        // Assert - Should show login form fields
        expect(
          find.byType(TextFormField),
          findsAtLeast(2),
          reason: 'Login screen should show phone and password fields',
        );

        // Should show login button
        expect(
          AppFinders.loginButton,
          findsOneWidget,
          reason: 'Login screen should show login button',
        );

        // Take screenshot
        await binding.takeScreenshot('smoke_login_screen');
      },
    );

    testWidgets(
      'Complete user journey: Login -> Browse -> Logout',
      (WidgetTester tester) async {
        // This is a comprehensive smoke test that covers the main user journey

        // 1. App Launch
        await pumpApp(tester);
        await tester.pumpAndSettle();
        await binding.takeScreenshot('journey_1_app_launch');

        // 2. Login
        await tester.login(TestUsers.rider);
        await tester.waitForWidget(
          AppFinders.bottomNavBar,
          timeout: const Duration(seconds: 15),
        );
        await binding.takeScreenshot('journey_2_logged_in');

        // 3. Navigate to Incidents
        await tester.navigateToTab(1);
        await tester.wait(TestConfig.apiPumpDuration);
        await binding.takeScreenshot('journey_3_incidents');

        // 4. Navigate to Chat
        await tester.navigateToTab(2);
        await tester.wait(TestConfig.apiPumpDuration);
        await binding.takeScreenshot('journey_4_chat');

        // 5. Navigate to Profile
        await tester.navigateToTab(3);
        await tester.pumpAndSettle();
        await binding.takeScreenshot('journey_5_profile');

        // 6. Back to Home
        await tester.navigateToTab(0);
        await tester.pumpAndSettle();
        await binding.takeScreenshot('journey_6_back_home');

        // 7. Logout
        await tester.logout();
        await tester.waitForWidget(
          AppFinders.loginButton,
          timeout: const Duration(seconds: 10),
        );
        await binding.takeScreenshot('journey_7_logged_out');

        // Assert - Complete journey successful
        expect(
          find.byType(TextFormField),
          findsAtLeast(2),
          reason: 'Should be back on login screen after complete journey',
        );
      },
    );
  });

  group('RiderApp Integration Tests - Critical Paths', () {
    testWidgets(
      'Critical Path: Rider can report an incident',
      (WidgetTester tester) async {
        // Arrange
        await pumpApp(tester);
        await tester.pumpAndSettle();
        await tester.login(TestUsers.rider);

        await tester.waitForWidget(
          AppFinders.bottomNavBar,
          timeout: const Duration(seconds: 15),
        );

        // Navigate to incidents
        await tester.navigateToTab(1);
        await tester.wait(TestConfig.apiPumpDuration);

        // Tap create incident
        await tester.tapAndSettle(AppFinders.createIncidentFab);

        // Verify create incident screen is shown
        expect(
          find.text('incidents.create'),
          findsOneWidget,
          reason: 'Should navigate to create incident screen',
        );

        // Take screenshot
        await binding.takeScreenshot('critical_path_create_incident');
      },
    );

    testWidgets(
      'Critical Path: Admin can access dashboard',
      (WidgetTester tester) async {
        // Arrange
        await pumpApp(tester);
        await tester.pumpAndSettle();
        await tester.login(TestUsers.admin);

        // Wait for admin home
        await tester.waitForWidget(
          find.text('home.admin.title'),
          timeout: const Duration(seconds: 15),
        );

        // Assert
        expect(
          find.text('home.admin.title'),
          findsOneWidget,
          reason: 'Admin should see admin dashboard',
        );

        // Take screenshot
        await binding.takeScreenshot('critical_path_admin_dashboard');
      },
    );

    testWidgets(
      'Critical Path: User can view notifications',
      (WidgetTester tester) async {
        // Arrange
        await pumpApp(tester);
        await tester.pumpAndSettle();
        await tester.login(TestUsers.rider);

        await tester.waitForWidget(
          AppFinders.notificationsButton,
          timeout: const Duration(seconds: 15),
        );

        // Act - Go to notifications
        await tester.tapAndSettle(AppFinders.notificationsButton);
        await tester.wait(TestConfig.apiPumpDuration);

        // Assert
        expect(
          find.text('notifications.title'),
          findsOneWidget,
          reason: 'Should show notifications screen',
        );

        // Take screenshot
        await binding.takeScreenshot('critical_path_notifications');
      },
    );
  });

  group('RiderApp Integration Tests - Performance', () {
    testWidgets(
      'Login should complete within acceptable time',
      (WidgetTester tester) async {
        // Arrange
        await pumpApp(tester);
        await tester.pumpAndSettle();

        // Measure login time
        final stopwatch = Stopwatch()..start();

        // Act
        await tester.login(TestUsers.rider);
        await tester.waitForWidget(
          AppFinders.bottomNavBar,
          timeout: const Duration(seconds: 15),
        );

        stopwatch.stop();

        // Assert - Login should complete within 10 seconds
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(10000),
          reason: 'Login should complete within 10 seconds',
        );

        // Take screenshot
        await binding.takeScreenshot('perf_login_time_${stopwatch.elapsedMilliseconds}ms');
      },
    );

    testWidgets(
      'Navigation should be responsive',
      (WidgetTester tester) async {
        // Arrange
        await pumpApp(tester);
        await tester.pumpAndSettle();
        await tester.login(TestUsers.rider);

        await tester.waitForWidget(
          AppFinders.bottomNavBar,
          timeout: const Duration(seconds: 15),
        );

        // Measure navigation time
        final stopwatch = Stopwatch()..start();

        // Act - Navigate through tabs
        await tester.navigateToTab(1);
        await tester.pumpAndSettle();
        await tester.navigateToTab(2);
        await tester.pumpAndSettle();
        await tester.navigateToTab(3);
        await tester.pumpAndSettle();
        await tester.navigateToTab(0);
        await tester.pumpAndSettle();

        stopwatch.stop();

        // Assert - All navigation should complete within 5 seconds
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(5000),
          reason: 'Navigation through all tabs should complete within 5 seconds',
        );
      },
    );
  });

  group('RiderApp Integration Tests - Error Handling', () {
    testWidgets(
      'Should handle invalid login gracefully',
      (WidgetTester tester) async {
        // Arrange
        await pumpApp(tester);
        await tester.pumpAndSettle();

        // Act
        await tester.login(TestUsers.invalidUser);

        // Assert - Should show error and stay on login screen
        expect(
          find.byType(TextFormField),
          findsAtLeast(2),
          reason: 'Should remain on login screen after failed login',
        );

        // Take screenshot
        await binding.takeScreenshot('error_invalid_login');
      },
    );

    testWidgets(
      'Should handle form validation',
      (WidgetTester tester) async {
        // Arrange
        await pumpApp(tester);
        await tester.pumpAndSettle();

        // Act - Submit empty form
        await tester.tapAndSettle(AppFinders.loginButton);

        // Assert - Should show validation errors
        expect(
          find.text('auth.validation.phoneRequired'),
          findsOneWidget,
          reason: 'Should show phone required error',
        );

        // Take screenshot
        await binding.takeScreenshot('error_validation');
      },
    );
  });
}

// =============================================================================
// TEST CONFIGURATION VERIFICATION
// =============================================================================

/// Helper function to verify test environment is properly configured.
/// Call this at the start of your test session to catch configuration issues.
void verifyTestEnvironment() {
  print('===========================================');
  print('RiderApp Integration Test Environment');
  print('===========================================');
  print('API Base URL: ${TestConfig.apiBaseUrl}');
  print('API Timeout: ${TestConfig.apiTimeout}s');
  print('Widget Timeout: ${TestConfig.widgetTimeout.inSeconds}s');
  print('');
  print('Test Users:');
  print('  - Rider: ${TestUsers.rider.phone}');
  print('  - Volunteer: ${TestUsers.volunteer.phone}');
  print('  - Police: ${TestUsers.police.phone}');
  print('  - Admin: ${TestUsers.admin.phone}');
  print('  - Super Admin: ${TestUsers.superAdmin.phone}');
  print('');
  print('Prerequisites:');
  print('  1. API server running at ${TestConfig.apiBaseUrl}');
  print('  2. Test users seeded in database');
  print('  3. Emulator/device running');
  print('===========================================');
}
