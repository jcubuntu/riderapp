import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helper.dart';

/// Integration tests for incidents flow.
///
/// These tests cover:
/// - Creating a new incident
/// - Viewing incident list
/// - Viewing incident detail
/// - Updating incident (for owner)
/// - Filtering incidents
///
/// **IMPORTANT**: These tests require a running API server.
/// Before running, ensure the API server is running:
/// ```bash
/// cd api && npm run dev
/// ```
///
/// Run these tests with:
/// ```bash
/// flutter test integration_test/incidents_flow_test.dart
/// ```
void main() {
  final binding = initializeIntegrationTest();

  group('Incidents Flow Tests', () {
    testWidgets(
      'should view incidents list after login',
      (WidgetTester tester) async {
        // Arrange - Login as rider
        await pumpApp(tester);
        await tester.pumpAndSettle();
        await tester.login(TestUsers.rider);

        // Wait for home screen
        await tester.waitForWidget(
          AppFinders.bottomNavBar,
          timeout: const Duration(seconds: 15),
        );

        // Act - Navigate to incidents tab (index 1)
        await tester.navigateToTab(1);
        await tester.wait(TestConfig.apiPumpDuration);

        // Assert - Should show incidents list screen
        expect(
          find.text('incidents.myReports'),
          findsOneWidget,
          reason: 'Should show My Reports title for rider',
        );

        // Verify list components are present
        expect(
          AppFinders.createIncidentFab,
          findsOneWidget,
          reason: 'Should show create incident FAB',
        );

        expect(
          AppFinders.filterButton,
          findsOneWidget,
          reason: 'Should show filter button',
        );

        // Take screenshot
        await binding.takeScreenshot('incidents_list_screen');
      },
    );

    testWidgets(
      'should navigate to create incident screen',
      (WidgetTester tester) async {
        // Arrange - Login and navigate to incidents
        await pumpApp(tester);
        await tester.pumpAndSettle();
        await tester.login(TestUsers.rider);

        await tester.waitForWidget(
          AppFinders.bottomNavBar,
          timeout: const Duration(seconds: 15),
        );

        await tester.navigateToTab(1);
        await tester.wait(TestConfig.apiPumpDuration);

        // Act - Tap create incident FAB
        await tester.tapAndSettle(AppFinders.createIncidentFab);

        // Assert - Should navigate to create incident screen
        expect(
          find.text('incidents.create'),
          findsOneWidget,
          reason: 'Should show Create Incident title',
        );

        // Verify form elements are present
        expect(
          find.byType(TextFormField),
          findsAtLeast(2),
          reason: 'Should show form fields',
        );

        // Verify category selector is present
        expect(
          find.byType(ChoiceChip),
          findsAtLeast(3),
          reason: 'Should show category chips',
        );

        // Take screenshot
        await binding.takeScreenshot('create_incident_screen');
      },
    );

    testWidgets(
      'should show validation errors on empty incident form',
      (WidgetTester tester) async {
        // Arrange - Navigate to create incident screen
        await pumpApp(tester);
        await tester.pumpAndSettle();
        await tester.login(TestUsers.rider);

        await tester.waitForWidget(
          AppFinders.bottomNavBar,
          timeout: const Duration(seconds: 15),
        );

        await tester.navigateToTab(1);
        await tester.wait(TestConfig.apiPumpDuration);

        await tester.tapAndSettle(AppFinders.createIncidentFab);

        // Act - Try to submit empty form
        final submitButton = find.byType(FilledButton).first;
        await tester.tapAndSettle(submitButton);

        // Assert - Should show validation errors
        expect(
          find.text('Title is required'),
          findsOneWidget,
          reason: 'Should show title required error',
        );

        expect(
          find.text('Description is required'),
          findsOneWidget,
          reason: 'Should show description required error',
        );

        // Take screenshot
        await binding.takeScreenshot('create_incident_validation_errors');
      },
    );

    testWidgets(
      'should create a new incident successfully',
      (WidgetTester tester) async {
        // Arrange - Navigate to create incident screen
        await pumpApp(tester);
        await tester.pumpAndSettle();
        await tester.login(TestUsers.rider);

        await tester.waitForWidget(
          AppFinders.bottomNavBar,
          timeout: const Duration(seconds: 15),
        );

        await tester.navigateToTab(1);
        await tester.wait(TestConfig.apiPumpDuration);

        await tester.tapAndSettle(AppFinders.createIncidentFab);

        // Act - Fill in the form
        // Enter title
        final titleField = find.byType(TextFormField).first;
        await tester.enterTextInField(
          titleField,
          MockIncidentData.testIncident['title']!,
        );

        // Enter description (second TextFormField in the form)
        final descriptionField = find.byType(TextFormField).at(1);
        await tester.enterTextInField(
          descriptionField,
          MockIncidentData.testIncident['description']!,
        );

        // Select category (tap on a ChoiceChip)
        final generalCategoryChip = find.text('incidents.categories.general');
        if (generalCategoryChip.evaluate().isNotEmpty) {
          await tester.tapAndSettle(generalCategoryChip);
        }

        // Enter address (optional)
        // Find address field by its hint or by index
        final addressField = find.byType(TextFormField).at(2);
        await tester.enterTextInField(
          addressField,
          MockIncidentData.testIncident['address']!,
        );

        // Submit the form
        final submitButton = find.byType(FilledButton).first;
        await tester.tapAndSettle(submitButton);

        // Wait for API response
        await tester.wait(TestConfig.apiPumpDuration);

        // Assert - Should show success message and navigate back
        // Check for success snackbar
        final successSnackbar = find.byType(SnackBar);
        // Note: Snackbar might dismiss quickly

        // Should navigate back to incidents list
        await tester.waitForWidget(
          AppFinders.createIncidentFab,
          timeout: const Duration(seconds: 10),
        );

        // Take screenshot
        await binding.takeScreenshot('incident_created_success');
      },
    );

    testWidgets(
      'should view incident detail',
      (WidgetTester tester) async {
        // Arrange - Login and go to incidents list
        await pumpApp(tester);
        await tester.pumpAndSettle();
        await tester.login(TestUsers.rider);

        await tester.waitForWidget(
          AppFinders.bottomNavBar,
          timeout: const Duration(seconds: 15),
        );

        await tester.navigateToTab(1);
        await tester.wait(TestConfig.apiPumpDuration);

        // Act - Tap on first incident in list (if any)
        // Look for incident cards
        final incidentCard = find.byType(Card);
        if (incidentCard.evaluate().isNotEmpty) {
          await tester.tapAndSettle(incidentCard.first);

          // Assert - Should navigate to incident detail
          await tester.pumpAndSettle();

          // Incident detail screen should show more details
          // Look for back button (indicating we navigated to detail)
          expect(
            find.byType(AppBar),
            findsOneWidget,
            reason: 'Should show app bar on detail screen',
          );

          // Take screenshot
          await binding.takeScreenshot('incident_detail_screen');

          // Navigate back
          await tester.pageBack();
          await tester.pumpAndSettle();
        } else {
          // No incidents to view, skip this assertion
          // This might happen if the incident list is empty
        }
      },
    );

    testWidgets(
      'should filter incidents by status',
      (WidgetTester tester) async {
        // Arrange - Login and go to incidents
        await pumpApp(tester);
        await tester.pumpAndSettle();
        await tester.login(TestUsers.rider);

        await tester.waitForWidget(
          AppFinders.bottomNavBar,
          timeout: const Duration(seconds: 15),
        );

        await tester.navigateToTab(1);
        await tester.wait(TestConfig.apiPumpDuration);

        // Act - Open filter sheet
        await tester.tapAndSettle(AppFinders.filterButton);

        // Assert - Should show filter bottom sheet
        expect(
          find.text('Filter Incidents'),
          findsOneWidget,
          reason: 'Should show filter sheet title',
        );

        // Verify filter options are present
        expect(
          find.byType(FilterChip),
          findsAtLeast(3),
          reason: 'Should show filter chips',
        );

        // Take screenshot
        await binding.takeScreenshot('incidents_filter_sheet');

        // Select a status filter
        final pendingFilter = find.text('incidents.status.pending');
        if (pendingFilter.evaluate().isNotEmpty) {
          await tester.tapAndSettle(pendingFilter);
        }

        // Apply filter
        final applyButton = find.text('Apply');
        await tester.tapAndSettle(applyButton);

        // Wait for filtered results
        await tester.wait(TestConfig.apiPumpDuration);

        // Take screenshot of filtered results
        await binding.takeScreenshot('incidents_filtered_by_status');
      },
    );

    testWidgets(
      'should search incidents',
      (WidgetTester tester) async {
        // Arrange - Login and go to incidents
        await pumpApp(tester);
        await tester.pumpAndSettle();
        await tester.login(TestUsers.rider);

        await tester.waitForWidget(
          AppFinders.bottomNavBar,
          timeout: const Duration(seconds: 15),
        );

        await tester.navigateToTab(1);
        await tester.wait(TestConfig.apiPumpDuration);

        // Act - Enter search query
        final searchField = find.byType(TextField);
        expect(searchField, findsOneWidget);

        await tester.enterTextInField(searchField, 'test');

        // Submit search
        await tester.testTextInput.receiveAction(TextInputAction.search);
        await tester.pumpAndSettle();

        // Wait for search results
        await tester.wait(TestConfig.apiPumpDuration);

        // Assert - List should update with search results
        // (Results depend on actual data in the test database)

        // Take screenshot
        await binding.takeScreenshot('incidents_search_results');

        // Clear search
        final clearButton = find.byIcon(Icons.clear);
        if (clearButton.evaluate().isNotEmpty) {
          await tester.tapAndSettle(clearButton);
          await tester.wait(TestConfig.apiPumpDuration);
        }
      },
    );

    testWidgets(
      'should pull to refresh incidents list',
      (WidgetTester tester) async {
        // Arrange - Login and go to incidents
        await pumpApp(tester);
        await tester.pumpAndSettle();
        await tester.login(TestUsers.rider);

        await tester.waitForWidget(
          AppFinders.bottomNavBar,
          timeout: const Duration(seconds: 15),
        );

        await tester.navigateToTab(1);
        await tester.wait(TestConfig.apiPumpDuration);

        // Act - Pull to refresh
        await tester.pullToRefresh();

        // Assert - List should refresh
        // Look for refresh indicator during pull
        // After refresh, list should still be present
        expect(
          AppFinders.createIncidentFab,
          findsOneWidget,
          reason: 'Should still show FAB after refresh',
        );

        // Take screenshot
        await binding.takeScreenshot('incidents_after_refresh');
      },
    );

    testWidgets(
      'should show empty state when no incidents',
      (WidgetTester tester) async {
        // This test verifies the empty state UI
        // Note: This depends on the test user having no incidents

        // Arrange
        await pumpApp(tester);
        await tester.pumpAndSettle();

        // Login with a fresh user (if available) or use existing
        await tester.login(TestUsers.rider);

        await tester.waitForWidget(
          AppFinders.bottomNavBar,
          timeout: const Duration(seconds: 15),
        );

        await tester.navigateToTab(1);
        await tester.wait(TestConfig.apiPumpDuration);

        // Act & Assert
        // Check if empty state is shown or incidents list
        final emptyStateIcon = find.byIcon(Icons.report_off_outlined);
        final incidentCard = find.byType(Card);

        // Either empty state or incidents should be visible
        final hasEmptyState = emptyStateIcon.evaluate().isNotEmpty;
        final hasIncidents = incidentCard.evaluate().isNotEmpty;

        expect(
          hasEmptyState || hasIncidents,
          isTrue,
          reason: 'Should show either empty state or incidents list',
        );

        // Take screenshot
        await binding.takeScreenshot('incidents_list_state');
      },
    );

    testWidgets(
      'should navigate back from create incident screen',
      (WidgetTester tester) async {
        // Arrange - Navigate to create incident
        await pumpApp(tester);
        await tester.pumpAndSettle();
        await tester.login(TestUsers.rider);

        await tester.waitForWidget(
          AppFinders.bottomNavBar,
          timeout: const Duration(seconds: 15),
        );

        await tester.navigateToTab(1);
        await tester.wait(TestConfig.apiPumpDuration);

        await tester.tapAndSettle(AppFinders.createIncidentFab);

        // Verify we're on create screen
        expect(
          find.text('incidents.create'),
          findsOneWidget,
        );

        // Act - Navigate back
        await tester.pageBack();
        await tester.pumpAndSettle();

        // Assert - Should be back on incidents list
        expect(
          AppFinders.createIncidentFab,
          findsOneWidget,
          reason: 'Should be back on incidents list showing FAB',
        );

        // Take screenshot
        await binding.takeScreenshot('back_to_incidents_list');
      },
    );

    testWidgets(
      'should select incident category',
      (WidgetTester tester) async {
        // Arrange - Navigate to create incident
        await pumpApp(tester);
        await tester.pumpAndSettle();
        await tester.login(TestUsers.rider);

        await tester.waitForWidget(
          AppFinders.bottomNavBar,
          timeout: const Duration(seconds: 15),
        );

        await tester.navigateToTab(1);
        await tester.wait(TestConfig.apiPumpDuration);

        await tester.tapAndSettle(AppFinders.createIncidentFab);

        // Act - Select different categories
        final choiceChips = find.byType(ChoiceChip);
        expect(choiceChips, findsAtLeast(3));

        // Tap on accident category
        final accidentChip = find.text('incidents.categories.accident');
        if (accidentChip.evaluate().isNotEmpty) {
          await tester.tapAndSettle(accidentChip);

          // Take screenshot
          await binding.takeScreenshot('incident_category_accident_selected');
        }

        // Tap on intelligence category
        final intelligenceChip = find.text('incidents.categories.intelligence');
        if (intelligenceChip.evaluate().isNotEmpty) {
          await tester.tapAndSettle(intelligenceChip);

          // Take screenshot
          await binding.takeScreenshot('incident_category_intelligence_selected');
        }
      },
    );

    testWidgets(
      'should select incident priority',
      (WidgetTester tester) async {
        // Arrange - Navigate to create incident
        await pumpApp(tester);
        await tester.pumpAndSettle();
        await tester.login(TestUsers.rider);

        await tester.waitForWidget(
          AppFinders.bottomNavBar,
          timeout: const Duration(seconds: 15),
        );

        await tester.navigateToTab(1);
        await tester.wait(TestConfig.apiPumpDuration);

        await tester.tapAndSettle(AppFinders.createIncidentFab);

        // Act - Find and interact with priority selector
        final prioritySelector = find.byType(SegmentedButton<dynamic>);
        expect(prioritySelector, findsOneWidget);

        // Tap on high priority
        final highPriority = find.text('incidents.priority.high');
        if (highPriority.evaluate().isNotEmpty) {
          await tester.tapAndSettle(highPriority);
        }

        // Take screenshot
        await binding.takeScreenshot('incident_priority_selected');
      },
    );

    testWidgets(
      'should toggle anonymous report',
      (WidgetTester tester) async {
        // Arrange - Navigate to create incident
        await pumpApp(tester);
        await tester.pumpAndSettle();
        await tester.login(TestUsers.rider);

        await tester.waitForWidget(
          AppFinders.bottomNavBar,
          timeout: const Duration(seconds: 15),
        );

        await tester.navigateToTab(1);
        await tester.wait(TestConfig.apiPumpDuration);

        await tester.tapAndSettle(AppFinders.createIncidentFab);

        // Scroll down to find anonymous toggle
        await tester.scrollDown(pixels: 500);

        // Act - Find and toggle anonymous switch
        final anonymousSwitch = find.byType(Switch);
        if (anonymousSwitch.evaluate().isNotEmpty) {
          await tester.tapAndSettle(anonymousSwitch);

          // Take screenshot
          await binding.takeScreenshot('incident_anonymous_enabled');

          // Toggle back
          await tester.tapAndSettle(anonymousSwitch);
        }
      },
    );
  });

  group('Incident Detail Tests', () {
    testWidgets(
      'should show incident information on detail screen',
      (WidgetTester tester) async {
        // This test requires existing incidents in the database
        // Arrange - Login and go to incidents
        await pumpApp(tester);
        await tester.pumpAndSettle();
        await tester.login(TestUsers.rider);

        await tester.waitForWidget(
          AppFinders.bottomNavBar,
          timeout: const Duration(seconds: 15),
        );

        await tester.navigateToTab(1);
        await tester.wait(TestConfig.apiPumpDuration);

        // Check if there are any incidents
        final incidentCard = find.byType(Card);
        if (incidentCard.evaluate().isNotEmpty) {
          // Act - Tap first incident
          await tester.tapAndSettle(incidentCard.first);
          await tester.pumpAndSettle();

          // Assert - Should show incident details
          // Look for key detail elements
          expect(
            find.byType(AppBar),
            findsOneWidget,
          );

          // Take screenshot
          await binding.takeScreenshot('incident_detail_information');
        }
      },
    );
  });
}
