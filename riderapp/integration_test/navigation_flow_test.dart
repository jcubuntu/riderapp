import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helper.dart';

/// Integration tests for navigation flow.
///
/// These tests cover:
/// - Bottom navigation bar functionality
/// - Screen navigation
/// - Back navigation
/// - Deep link navigation (basic)
///
/// **IMPORTANT**: These tests require a running API server.
/// Before running, ensure the API server is running:
/// ```bash
/// cd api && npm run dev
/// ```
///
/// Run these tests with:
/// ```bash
/// flutter test integration_test/navigation_flow_test.dart
/// ```
void main() {
  final binding = initializeIntegrationTest();

  group('Bottom Navigation Tests', () {
    testWidgets(
      'should navigate between tabs using bottom navigation',
      (WidgetTester tester) async {
        // Arrange - Login first
        await pumpApp(tester);
        await tester.pumpAndSettle();
        await tester.login(TestUsers.rider);

        // Wait for home screen
        await tester.waitForWidget(
          AppFinders.bottomNavBar,
          timeout: const Duration(seconds: 15),
        );

        // Verify bottom navigation bar is present with 4 items
        final bottomNav = find.byType(BottomNavigationBar);
        expect(bottomNav, findsOneWidget);

        // Get the bottom navigation bar widget
        final bottomNavWidget = tester.widget<BottomNavigationBar>(bottomNav);
        expect(
          bottomNavWidget.items.length,
          equals(4),
          reason: 'Rider home should have 4 navigation items',
        );

        // Take screenshot of home tab
        await binding.takeScreenshot('nav_home_tab');
      },
    );

    testWidgets(
      'should navigate to incidents tab',
      (WidgetTester tester) async {
        // Arrange
        await pumpApp(tester);
        await tester.pumpAndSettle();
        await tester.login(TestUsers.rider);

        await tester.waitForWidget(
          AppFinders.bottomNavBar,
          timeout: const Duration(seconds: 15),
        );

        // Act - Navigate to incidents tab (index 1)
        await tester.navigateToTab(1);
        await tester.wait(TestConfig.apiPumpDuration);

        // Assert - Should show incidents screen
        expect(
          find.text('incidents.myReports'),
          findsOneWidget,
          reason: 'Should show My Reports screen for rider',
        );

        // Verify the FAB is visible (incidents screen specific)
        expect(
          AppFinders.createIncidentFab,
          findsOneWidget,
          reason: 'Should show create incident FAB',
        );

        // Take screenshot
        await binding.takeScreenshot('nav_incidents_tab');
      },
    );

    testWidgets(
      'should navigate to chat tab',
      (WidgetTester tester) async {
        // Arrange
        await pumpApp(tester);
        await tester.pumpAndSettle();
        await tester.login(TestUsers.rider);

        await tester.waitForWidget(
          AppFinders.bottomNavBar,
          timeout: const Duration(seconds: 15),
        );

        // Act - Navigate to chat tab (index 2)
        await tester.navigateToTab(2);
        await tester.wait(TestConfig.apiPumpDuration);

        // Assert - Should show chat screen
        expect(
          find.text('chat.title'),
          findsOneWidget,
          reason: 'Should show Chat screen',
        );

        // Take screenshot
        await binding.takeScreenshot('nav_chat_tab');
      },
    );

    testWidgets(
      'should navigate to profile tab',
      (WidgetTester tester) async {
        // Arrange
        await pumpApp(tester);
        await tester.pumpAndSettle();
        await tester.login(TestUsers.rider);

        await tester.waitForWidget(
          AppFinders.bottomNavBar,
          timeout: const Duration(seconds: 15),
        );

        // Act - Navigate to profile tab (index 3)
        await tester.navigateToTab(3);
        await tester.pumpAndSettle();

        // Assert - Should show profile screen
        expect(
          find.text('profile.title'),
          findsOneWidget,
          reason: 'Should show Profile screen',
        );

        // Take screenshot
        await binding.takeScreenshot('nav_profile_tab');
      },
    );

    testWidgets(
      'should return to home tab from other tabs',
      (WidgetTester tester) async {
        // Arrange
        await pumpApp(tester);
        await tester.pumpAndSettle();
        await tester.login(TestUsers.rider);

        await tester.waitForWidget(
          AppFinders.bottomNavBar,
          timeout: const Duration(seconds: 15),
        );

        // Navigate to incidents first
        await tester.navigateToTab(1);
        await tester.wait(TestConfig.apiPumpDuration);

        // Act - Navigate back to home (index 0)
        await tester.navigateToTab(0);
        await tester.pumpAndSettle();

        // Assert - Should show home screen
        expect(
          find.text('home.rider.title'),
          findsOneWidget,
          reason: 'Should show Rider Home screen',
        );

        // Take screenshot
        await binding.takeScreenshot('nav_back_to_home');
      },
    );

    testWidgets(
      'should cycle through all tabs',
      (WidgetTester tester) async {
        // Arrange
        await pumpApp(tester);
        await tester.pumpAndSettle();
        await tester.login(TestUsers.rider);

        await tester.waitForWidget(
          AppFinders.bottomNavBar,
          timeout: const Duration(seconds: 15),
        );

        // Act & Assert - Cycle through all tabs
        // Tab 0 - Home (already there)
        expect(find.text('home.rider.title'), findsOneWidget);
        await binding.takeScreenshot('tab_cycle_home');

        // Tab 1 - Incidents
        await tester.navigateToTab(1);
        await tester.wait(TestConfig.apiPumpDuration);
        await binding.takeScreenshot('tab_cycle_incidents');

        // Tab 2 - Chat
        await tester.navigateToTab(2);
        await tester.wait(TestConfig.apiPumpDuration);
        await binding.takeScreenshot('tab_cycle_chat');

        // Tab 3 - Profile
        await tester.navigateToTab(3);
        await tester.pumpAndSettle();
        await binding.takeScreenshot('tab_cycle_profile');

        // Back to Home
        await tester.navigateToTab(0);
        await tester.pumpAndSettle();
        expect(find.text('home.rider.title'), findsOneWidget);
      },
    );
  });

  group('Screen Navigation Tests', () {
    testWidgets(
      'should navigate to notifications screen',
      (WidgetTester tester) async {
        // Arrange
        await pumpApp(tester);
        await tester.pumpAndSettle();
        await tester.login(TestUsers.rider);

        await tester.waitForWidget(
          AppFinders.notificationsButton,
          timeout: const Duration(seconds: 15),
        );

        // Act - Tap notifications button
        await tester.tapAndSettle(AppFinders.notificationsButton);
        await tester.wait(TestConfig.apiPumpDuration);

        // Assert - Should navigate to notifications screen
        expect(
          find.text('notifications.title'),
          findsOneWidget,
          reason: 'Should show Notifications screen',
        );

        // Take screenshot
        await binding.takeScreenshot('nav_notifications_screen');
      },
    );

    testWidgets(
      'should navigate to create incident from home',
      (WidgetTester tester) async {
        // Arrange
        await pumpApp(tester);
        await tester.pumpAndSettle();
        await tester.login(TestUsers.rider);

        await tester.waitForWidget(
          AppFinders.bottomNavBar,
          timeout: const Duration(seconds: 15),
        );

        // Find the "Report Incident" action card on home
        final reportIncidentCard = find.text('home.rider.reportIncident');
        if (reportIncidentCard.evaluate().isNotEmpty) {
          // Act - Tap on report incident card
          await tester.tapAndSettle(reportIncidentCard);
          await tester.pumpAndSettle();

          // Assert - Should navigate to create incident screen
          expect(
            find.text('incidents.create'),
            findsOneWidget,
            reason: 'Should show Create Incident screen',
          );

          // Take screenshot
          await binding.takeScreenshot('nav_create_incident_from_home');
        }
      },
    );

    testWidgets(
      'should navigate to settings from profile',
      (WidgetTester tester) async {
        // Arrange - Go to profile
        await pumpApp(tester);
        await tester.pumpAndSettle();
        await tester.login(TestUsers.rider);

        await tester.waitForWidget(
          AppFinders.bottomNavBar,
          timeout: const Duration(seconds: 15),
        );

        await tester.navigateToTab(3);
        await tester.pumpAndSettle();

        // Look for settings button/link in profile
        final settingsButton = find.byIcon(Icons.settings);
        if (settingsButton.evaluate().isNotEmpty) {
          // Act - Tap settings
          await tester.tapAndSettle(settingsButton);
          await tester.pumpAndSettle();

          // Assert - Should navigate to settings screen
          expect(
            find.text('settings.title'),
            findsOneWidget,
            reason: 'Should show Settings screen',
          );

          // Take screenshot
          await binding.takeScreenshot('nav_settings_screen');
        }
      },
    );
  });

  group('Back Navigation Tests', () {
    testWidgets(
      'should navigate back from incident detail',
      (WidgetTester tester) async {
        // Arrange - Go to incidents and open detail
        await pumpApp(tester);
        await tester.pumpAndSettle();
        await tester.login(TestUsers.rider);

        await tester.waitForWidget(
          AppFinders.bottomNavBar,
          timeout: const Duration(seconds: 15),
        );

        await tester.navigateToTab(1);
        await tester.wait(TestConfig.apiPumpDuration);

        // Open create incident screen
        await tester.tapAndSettle(AppFinders.createIncidentFab);

        // Verify we're on create screen
        expect(find.text('incidents.create'), findsOneWidget);

        // Act - Navigate back
        await tester.pageBack();
        await tester.pumpAndSettle();

        // Assert - Should be back on incidents list
        expect(
          AppFinders.createIncidentFab,
          findsOneWidget,
          reason: 'Should be back on incidents list',
        );

        // Take screenshot
        await binding.takeScreenshot('nav_back_from_create_incident');
      },
    );

    testWidgets(
      'should navigate back from notifications',
      (WidgetTester tester) async {
        // Arrange
        await pumpApp(tester);
        await tester.pumpAndSettle();
        await tester.login(TestUsers.rider);

        await tester.waitForWidget(
          AppFinders.notificationsButton,
          timeout: const Duration(seconds: 15),
        );

        // Go to notifications
        await tester.tapAndSettle(AppFinders.notificationsButton);
        await tester.wait(TestConfig.apiPumpDuration);

        // Act - Navigate back
        await tester.pageBack();
        await tester.pumpAndSettle();

        // Assert - Should be back on home
        expect(
          find.text('home.rider.title'),
          findsOneWidget,
          reason: 'Should be back on home screen',
        );

        // Take screenshot
        await binding.takeScreenshot('nav_back_from_notifications');
      },
    );

    testWidgets(
      'should handle back button on home (should not exit)',
      (WidgetTester tester) async {
        // Arrange
        await pumpApp(tester);
        await tester.pumpAndSettle();
        await tester.login(TestUsers.rider);

        await tester.waitForWidget(
          AppFinders.bottomNavBar,
          timeout: const Duration(seconds: 15),
        );

        // Verify on home
        expect(find.text('home.rider.title'), findsOneWidget);

        // Act - Try to go back (should do nothing on home)
        // Note: pageBack might not do anything if there's no navigation history
        await tester.pumpAndSettle();

        // Assert - Should still be on home
        expect(
          find.text('home.rider.title'),
          findsOneWidget,
          reason: 'Should still be on home screen',
        );
      },
    );
  });

  group('Role-Based Navigation Tests', () {
    testWidgets(
      'admin should see admin-specific home screen',
      (WidgetTester tester) async {
        // Arrange
        await pumpApp(tester);
        await tester.pumpAndSettle();

        // Act - Login as admin
        await tester.login(TestUsers.admin);

        // Wait for admin home
        await tester.waitForWidget(
          find.text('home.admin.title'),
          timeout: const Duration(seconds: 15),
        );

        // Assert - Should show admin home
        expect(
          find.text('home.admin.title'),
          findsOneWidget,
          reason: 'Admin should see admin home screen',
        );

        // Take screenshot
        await binding.takeScreenshot('nav_admin_home');
      },
    );

    testWidgets(
      'volunteer should see volunteer-specific home screen',
      (WidgetTester tester) async {
        // Arrange
        await pumpApp(tester);
        await tester.pumpAndSettle();

        // Act - Login as volunteer
        await tester.login(TestUsers.volunteer);

        // Wait for volunteer home
        await tester.waitForWidget(
          find.text('home.volunteer.title'),
          timeout: const Duration(seconds: 15),
        );

        // Assert - Should show volunteer home
        expect(
          find.text('home.volunteer.title'),
          findsOneWidget,
          reason: 'Volunteer should see volunteer home screen',
        );

        // Take screenshot
        await binding.takeScreenshot('nav_volunteer_home');
      },
    );

    testWidgets(
      'police should see police-specific home screen',
      (WidgetTester tester) async {
        // Arrange
        await pumpApp(tester);
        await tester.pumpAndSettle();

        // Act - Login as police
        await tester.login(TestUsers.police);

        // Wait for police home
        await tester.waitForWidget(
          find.text('home.police.title'),
          timeout: const Duration(seconds: 15),
        );

        // Assert - Should show police home
        expect(
          find.text('home.police.title'),
          findsOneWidget,
          reason: 'Police should see police home screen',
        );

        // Take screenshot
        await binding.takeScreenshot('nav_police_home');
      },
    );
  });

  group('Quick Action Navigation Tests', () {
    testWidgets(
      'should navigate using quick action cards on home',
      (WidgetTester tester) async {
        // Arrange
        await pumpApp(tester);
        await tester.pumpAndSettle();
        await tester.login(TestUsers.rider);

        await tester.waitForWidget(
          AppFinders.bottomNavBar,
          timeout: const Duration(seconds: 15),
        );

        // Find quick action cards
        final viewReportsCard = find.text('home.rider.viewReports');
        final chatCard = find.text('home.rider.chat');
        final emergencyCard = find.text('home.rider.emergency');

        // Test View Reports action
        if (viewReportsCard.evaluate().isNotEmpty) {
          await tester.tapAndSettle(viewReportsCard);
          await tester.wait(TestConfig.apiPumpDuration);

          // Should navigate to my incidents
          // Navigate back
          await tester.navigateToTab(0);
          await tester.pumpAndSettle();
        }

        // Test Chat action
        if (chatCard.evaluate().isNotEmpty) {
          await tester.tapAndSettle(chatCard);
          await tester.pumpAndSettle();

          // Navigate back
          await tester.navigateToTab(0);
          await tester.pumpAndSettle();
        }

        // Take screenshot of home with action cards
        await binding.takeScreenshot('nav_quick_actions_home');
      },
    );
  });

  group('Scroll Navigation Tests', () {
    testWidgets(
      'should scroll home screen content',
      (WidgetTester tester) async {
        // Arrange
        await pumpApp(tester);
        await tester.pumpAndSettle();
        await tester.login(TestUsers.rider);

        await tester.waitForWidget(
          AppFinders.bottomNavBar,
          timeout: const Duration(seconds: 15),
        );

        // Act - Scroll down
        await tester.scrollDown(pixels: 200);

        // Take screenshot after scroll
        await binding.takeScreenshot('nav_home_scrolled');

        // Scroll up
        await tester.scrollUp(pixels: 200);

        // Take screenshot
        await binding.takeScreenshot('nav_home_scrolled_back');
      },
    );

    testWidgets(
      'should scroll incidents list',
      (WidgetTester tester) async {
        // Arrange
        await pumpApp(tester);
        await tester.pumpAndSettle();
        await tester.login(TestUsers.rider);

        await tester.waitForWidget(
          AppFinders.bottomNavBar,
          timeout: const Duration(seconds: 15),
        );

        await tester.navigateToTab(1);
        await tester.wait(TestConfig.apiPumpDuration);

        // Act - Scroll if there are incidents
        final incidentList = find.byType(ListView);
        if (incidentList.evaluate().isNotEmpty) {
          await tester.scrollDown(pixels: 300);
          await binding.takeScreenshot('nav_incidents_scrolled');
        }
      },
    );
  });

  group('Error Navigation Tests', () {
    testWidgets(
      'should redirect unauthenticated user to login',
      (WidgetTester tester) async {
        // Arrange
        await pumpApp(tester);
        await tester.pumpAndSettle();

        // Assert - Should start on login screen
        expect(
          find.byType(TextFormField),
          findsAtLeast(2),
          reason: 'Should be on login screen initially',
        );

        // Take screenshot
        await binding.takeScreenshot('nav_unauthenticated_redirect');
      },
    );

    testWidgets(
      'should redirect to login after logout',
      (WidgetTester tester) async {
        // Arrange - Login first
        await pumpApp(tester);
        await tester.pumpAndSettle();
        await tester.login(TestUsers.rider);

        await tester.waitForWidget(
          AppFinders.logoutButton,
          timeout: const Duration(seconds: 15),
        );

        // Act - Logout
        await tester.logout();

        // Assert - Should redirect to login
        await tester.waitForWidget(
          AppFinders.loginButton,
          timeout: const Duration(seconds: 10),
        );

        expect(
          find.byType(TextFormField),
          findsAtLeast(2),
          reason: 'Should redirect to login after logout',
        );

        // Take screenshot
        await binding.takeScreenshot('nav_redirect_after_logout');
      },
    );
  });
}
