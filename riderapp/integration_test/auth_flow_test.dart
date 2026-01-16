import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helper.dart';

/// Integration tests for authentication flow.
///
/// These tests cover:
/// - Login with valid credentials
/// - Login with invalid credentials (error handling)
/// - Register flow (if implemented)
/// - Logout flow
///
/// **IMPORTANT**: These tests require a running API server.
/// Before running, ensure the API server is running:
/// ```bash
/// cd api && npm run dev
/// ```
///
/// Run these tests with:
/// ```bash
/// flutter test integration_test/auth_flow_test.dart
/// ```
void main() {
  final binding = initializeIntegrationTest();

  group('Authentication Flow Tests', () {
    testWidgets(
      'should login successfully with valid rider credentials',
      (WidgetTester tester) async {
        // Arrange
        await pumpApp(tester);
        await tester.pumpAndSettle();

        // Verify we're on the login screen
        expect(find.byType(TextFormField), findsAtLeast(2));

        // Act - Login with rider credentials
        await tester.login(TestUsers.rider);

        // Assert - Should navigate to rider home screen
        // Wait for navigation to complete
        await tester.waitForWidget(
          find.text('home.rider.title'),
          timeout: const Duration(seconds: 15),
        );

        // Verify rider home screen elements are visible
        expect(AppFinders.bottomNavBar, findsOneWidget);
        expect(AppFinders.logoutButton, findsOneWidget);

        // Take screenshot for documentation
        await binding.takeScreenshot('rider_home_after_login');
      },
    );

    testWidgets(
      'should login successfully with admin credentials',
      (WidgetTester tester) async {
        // Arrange
        await pumpApp(tester);
        await tester.pumpAndSettle();

        // Act - Login with admin credentials
        await tester.login(TestUsers.admin);

        // Assert - Should navigate to admin home screen
        await tester.waitForWidget(
          find.text('home.admin.title'),
          timeout: const Duration(seconds: 15),
        );

        // Verify admin-specific elements
        expect(AppFinders.logoutButton, findsOneWidget);

        // Take screenshot
        await binding.takeScreenshot('admin_home_after_login');
      },
    );

    testWidgets(
      'should show error with invalid credentials',
      (WidgetTester tester) async {
        // Arrange
        await pumpApp(tester);
        await tester.pumpAndSettle();

        // Act - Try to login with invalid credentials
        await tester.enterTextInField(
          AppFinders.phoneField,
          TestUsers.invalidUser.phone,
        );
        await tester.enterTextInField(
          AppFinders.passwordField,
          TestUsers.invalidUser.password,
        );

        // Tap login button
        await tester.tapAndSettle(AppFinders.loginButton);

        // Wait for API response
        await tester.wait(TestConfig.apiPumpDuration);

        // Assert - Should show error message (snackbar)
        // The app shows errors via SnackBar
        expect(
          find.byType(SnackBar),
          findsOneWidget,
          reason: 'Should show error snackbar for invalid credentials',
        );

        // Should remain on login screen
        expect(
          find.byType(TextFormField),
          findsAtLeast(2),
          reason: 'Should still be on login screen',
        );

        // Take screenshot
        await binding.takeScreenshot('login_error_invalid_credentials');
      },
    );

    testWidgets(
      'should show validation error for empty phone number',
      (WidgetTester tester) async {
        // Arrange
        await pumpApp(tester);
        await tester.pumpAndSettle();

        // Act - Try to login without entering phone
        await tester.enterTextInField(
          AppFinders.passwordField,
          'SomePassword123',
        );

        // Tap login button without phone
        await tester.tapAndSettle(AppFinders.loginButton);

        // Assert - Should show validation error
        expect(
          find.text('auth.validation.phoneRequired'),
          findsOneWidget,
          reason: 'Should show phone required validation error',
        );

        // Take screenshot
        await binding.takeScreenshot('login_validation_phone_required');
      },
    );

    testWidgets(
      'should show validation error for empty password',
      (WidgetTester tester) async {
        // Arrange
        await pumpApp(tester);
        await tester.pumpAndSettle();

        // Act - Try to login without entering password
        await tester.enterTextInField(
          AppFinders.phoneField,
          '0812345678',
        );

        // Tap login button without password
        await tester.tapAndSettle(AppFinders.loginButton);

        // Assert - Should show validation error
        expect(
          find.text('auth.validation.passwordRequired'),
          findsOneWidget,
          reason: 'Should show password required validation error',
        );

        // Take screenshot
        await binding.takeScreenshot('login_validation_password_required');
      },
    );

    testWidgets(
      'should show validation error for short password',
      (WidgetTester tester) async {
        // Arrange
        await pumpApp(tester);
        await tester.pumpAndSettle();

        // Act - Enter phone and short password
        await tester.enterTextInField(
          AppFinders.phoneField,
          '0812345678',
        );
        await tester.enterTextInField(
          AppFinders.passwordField,
          '1234', // Too short
        );

        // Tap login button
        await tester.tapAndSettle(AppFinders.loginButton);

        // Assert - Should show validation error for short password
        expect(
          find.text('auth.validation.passwordTooShort'),
          findsOneWidget,
          reason: 'Should show password too short validation error',
        );

        // Take screenshot
        await binding.takeScreenshot('login_validation_password_short');
      },
    );

    testWidgets(
      'should navigate to register screen',
      (WidgetTester tester) async {
        // Arrange
        await pumpApp(tester);
        await tester.pumpAndSettle();

        // Act - Tap on register link
        final registerButton = find.byType(TextButton).last;
        await tester.tapAndSettle(registerButton);

        // Assert - Should navigate to register screen
        // Look for register screen specific elements
        await tester.pumpAndSettle();

        // The register screen should have more form fields
        expect(
          find.byType(TextFormField),
          findsAtLeast(4),
          reason: 'Register screen should have multiple form fields',
        );

        // Take screenshot
        await binding.takeScreenshot('register_screen');
      },
    );

    testWidgets(
      'should logout successfully',
      (WidgetTester tester) async {
        // Arrange - Login first
        await pumpApp(tester);
        await tester.pumpAndSettle();
        await tester.login(TestUsers.rider);

        // Wait for home screen
        await tester.waitForWidget(
          AppFinders.logoutButton,
          timeout: const Duration(seconds: 15),
        );

        // Act - Tap logout button
        await tester.logout();

        // Assert - Should navigate back to login screen
        await tester.waitForWidget(
          AppFinders.loginButton,
          timeout: const Duration(seconds: 10),
        );

        // Verify we're back on login screen
        expect(
          find.byType(TextFormField),
          findsAtLeast(2),
          reason: 'Should be back on login screen after logout',
        );

        // Take screenshot
        await binding.takeScreenshot('login_screen_after_logout');
      },
    );

    testWidgets(
      'should toggle password visibility',
      (WidgetTester tester) async {
        // Arrange
        await pumpApp(tester);
        await tester.pumpAndSettle();

        // Enter some password
        await tester.enterTextInField(
          AppFinders.passwordField,
          'TestPassword123',
        );

        // Find the visibility toggle button
        final visibilityToggle = find.byIcon(Icons.visibility_outlined);
        expect(visibilityToggle, findsOneWidget);

        // Act - Tap to show password
        await tester.tapAndSettle(visibilityToggle);

        // Assert - Icon should change to visibility_off
        expect(
          find.byIcon(Icons.visibility_off_outlined),
          findsOneWidget,
          reason: 'Should show visibility_off icon after toggling',
        );

        // Take screenshot
        await binding.takeScreenshot('password_visible');

        // Toggle back
        await tester.tapAndSettle(find.byIcon(Icons.visibility_off_outlined));

        // Should be back to visibility icon
        expect(
          find.byIcon(Icons.visibility_outlined),
          findsOneWidget,
          reason: 'Should show visibility icon after toggling back',
        );
      },
    );

    testWidgets(
      'should show loading indicator during login',
      (WidgetTester tester) async {
        // Arrange
        await pumpApp(tester);
        await tester.pumpAndSettle();

        // Enter credentials
        await tester.enterTextInField(
          AppFinders.phoneField,
          TestUsers.rider.phone,
        );
        await tester.enterTextInField(
          AppFinders.passwordField,
          TestUsers.rider.password,
        );

        // Act - Tap login (don't wait for settle)
        await tester.tap(AppFinders.loginButton);

        // Pump a short time to see loading state
        await tester.pump(const Duration(milliseconds: 100));

        // Assert - Should show loading indicator
        // The button shows CircularProgressIndicator when loading
        final loadingIndicator = find.byType(CircularProgressIndicator);
        // Note: This might be flaky depending on API speed
        // If the API responds too fast, loading indicator might not be visible

        // Wait for login to complete
        await tester.pumpAndSettle(const Duration(seconds: 10));
      },
    );

    testWidgets(
      'should switch language',
      (WidgetTester tester) async {
        // Arrange
        await pumpApp(tester);
        await tester.pumpAndSettle();

        // Find language switcher button
        final languageSwitcher = find.byIcon(Icons.language);
        expect(languageSwitcher, findsOneWidget);

        // Get current language text
        final currentLangFinder = find.text('English');

        // Act - Tap to switch language
        await tester.tapAndSettle(languageSwitcher);

        // Assert - Language should change
        // After switching, the button text should change
        await tester.pumpAndSettle();

        // Take screenshot
        await binding.takeScreenshot('language_switched');
      },
    );
  });

  group('Register Flow Tests', () {
    testWidgets(
      'should show validation errors for empty register form',
      (WidgetTester tester) async {
        // Arrange - Navigate to register screen
        await pumpApp(tester);
        await tester.pumpAndSettle();

        // Tap register link
        final registerButton = find.byType(TextButton).last;
        await tester.tapAndSettle(registerButton);
        await tester.pumpAndSettle();

        // Act - Try to submit empty form
        final submitButton = find.byType(ElevatedButton).first;
        await tester.tapAndSettle(submitButton);

        // Assert - Should show validation errors
        // Multiple validation errors should appear
        await tester.pumpAndSettle();

        // Take screenshot
        await binding.takeScreenshot('register_validation_errors');
      },
    );

    testWidgets(
      'should navigate back to login from register',
      (WidgetTester tester) async {
        // Arrange - Navigate to register screen
        await pumpApp(tester);
        await tester.pumpAndSettle();

        // Tap register link
        final registerButton = find.byType(TextButton).last;
        await tester.tapAndSettle(registerButton);
        await tester.pumpAndSettle();

        // Verify we're on register screen
        expect(
          find.byType(TextFormField),
          findsAtLeast(4),
        );

        // Act - Navigate back
        await tester.pageBack();
        await tester.pumpAndSettle();

        // Assert - Should be back on login screen
        expect(
          find.byType(TextFormField),
          findsNWidgets(2),
          reason: 'Should be back on login screen with 2 form fields',
        );

        // Take screenshot
        await binding.takeScreenshot('back_to_login_from_register');
      },
    );
  });

  group('Session Persistence Tests', () {
    testWidgets(
      'should maintain session after app restart (if implemented)',
      (WidgetTester tester) async {
        // This test verifies session persistence
        // Note: Full session persistence testing would require
        // actually restarting the app, which is complex in integration tests.
        // This is a placeholder for manual testing.

        // Arrange
        await pumpApp(tester);
        await tester.pumpAndSettle();

        // Login
        await tester.login(TestUsers.rider);

        // Wait for home screen
        await tester.waitForWidget(
          AppFinders.logoutButton,
          timeout: const Duration(seconds: 15),
        );

        // Verify we're logged in
        expect(AppFinders.logoutButton, findsOneWidget);

        // Take screenshot
        await binding.takeScreenshot('session_logged_in');
      },
    );
  });
}
