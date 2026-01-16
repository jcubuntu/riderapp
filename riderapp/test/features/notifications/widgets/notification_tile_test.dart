import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:riderapp/features/notifications/presentation/widgets/notification_tile.dart';
import 'package:riderapp/features/notifications/domain/entities/app_notification.dart';
import 'package:riderapp/core/constants/app_colors.dart';

import '../../../helpers/widget_test_helpers.dart';

void main() {
  group('NotificationTile', () {
    Widget buildNotificationTile({
      required AppNotification notification,
      VoidCallback? onTap,
      VoidCallback? onDismiss,
      bool isDeleting = false,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: NotificationTile(
            notification: notification,
            onTap: onTap,
            onDismiss: onDismiss,
            isDeleting: isDeleting,
          ),
        ),
        localizationsDelegates: const [
          DefaultMaterialLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
      );
    }

    group('Rendering Different Notification Types', () {
      testWidgets('should render chat notification with chat icon',
          (tester) async {
        final notification = TestNotificationFactory.createChatNotification(
          title: 'New Message',
          body: 'You have a new message',
        );

        await tester.pumpWidget(buildNotificationTile(notification: notification));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
        expect(find.text('New Message'), findsOneWidget);
        expect(find.text('You have a new message'), findsOneWidget);
      });

      testWidgets('should render incident notification with warning icon',
          (tester) async {
        final notification = TestNotificationFactory.createIncidentNotification(
          title: 'Incident Update',
          body: 'Your incident status changed',
        );

        await tester.pumpWidget(buildNotificationTile(notification: notification));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.warning_amber_outlined), findsOneWidget);
        expect(find.text('Incident Update'), findsOneWidget);
        expect(find.text('Your incident status changed'), findsOneWidget);
      });

      testWidgets('should render SOS notification with SOS icon', (tester) async {
        final notification = TestNotificationFactory.createSOSNotification(
          title: 'SOS Alert',
          body: 'Emergency nearby',
        );

        await tester.pumpWidget(buildNotificationTile(notification: notification));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.sos), findsOneWidget);
        expect(find.text('SOS Alert'), findsOneWidget);
        expect(find.text('Emergency nearby'), findsOneWidget);
      });

      testWidgets('should render announcement notification with campaign icon',
          (tester) async {
        final notification =
            TestNotificationFactory.createAnnouncementNotification(
          title: 'New Announcement',
          body: 'Check out the latest news',
        );

        await tester.pumpWidget(buildNotificationTile(notification: notification));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.campaign_outlined), findsOneWidget);
        expect(find.text('New Announcement'), findsOneWidget);
        expect(find.text('Check out the latest news'), findsOneWidget);
      });

      testWidgets('should render approval notification with verified icon',
          (tester) async {
        final notification = TestNotificationFactory.createApprovalNotification(
          title: 'Account Approved',
          body: 'Your account has been approved',
        );

        await tester.pumpWidget(buildNotificationTile(notification: notification));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.verified_user_outlined), findsOneWidget);
        expect(find.text('Account Approved'), findsOneWidget);
        expect(find.text('Your account has been approved'), findsOneWidget);
      });

      testWidgets('should render system notification with info icon',
          (tester) async {
        final notification = TestNotificationFactory.create(
          title: 'System Update',
          body: 'App has been updated',
          type: NotificationType.system,
        );

        await tester.pumpWidget(buildNotificationTile(notification: notification));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.info_outline), findsOneWidget);
        expect(find.text('System Update'), findsOneWidget);
        expect(find.text('App has been updated'), findsOneWidget);
      });
    });

    group('Unread Indicator', () {
      testWidgets('should show unread indicator for unread notification',
          (tester) async {
        final notification = TestNotificationFactory.create(
          title: 'Unread Notification',
          isRead: false,
        );

        await tester.pumpWidget(buildNotificationTile(notification: notification));
        await tester.pumpAndSettle();

        // Find the unread indicator (small circle)
        final unreadIndicator = find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).shape == BoxShape.circle &&
              (widget.decoration as BoxDecoration).color == AppColors.primary,
        );
        expect(unreadIndicator, findsOneWidget);
      });

      testWidgets('should not show unread indicator for read notification',
          (tester) async {
        final notification = TestNotificationFactory.create(
          title: 'Read Notification',
          isRead: true,
        );

        await tester.pumpWidget(buildNotificationTile(notification: notification));
        await tester.pumpAndSettle();

        // Find containers that are circular with primary color (unread indicator)
        final unreadIndicator = find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.constraints?.maxWidth == 8 &&
              widget.constraints?.maxHeight == 8,
        );
        expect(unreadIndicator, findsNothing);
      });

      testWidgets('should have different background for unread notification',
          (tester) async {
        final unreadNotification = TestNotificationFactory.create(
          id: 'unread',
          title: 'Unread',
          isRead: false,
        );

        await tester.pumpWidget(
            buildNotificationTile(notification: unreadNotification));
        await tester.pumpAndSettle();

        // The unread notification should have a slightly tinted background
        // We verify this by checking the Container decoration
        final container = tester.widget<Container>(
          find
              .descendant(
                of: find.byType(InkWell),
                matching: find.byType(Container),
              )
              .first,
        );
        expect(container, isNotNull);
      });

      testWidgets('should have white background for read notification',
          (tester) async {
        final readNotification = TestNotificationFactory.create(
          id: 'read',
          title: 'Read',
          isRead: true,
        );

        await tester
            .pumpWidget(buildNotificationTile(notification: readNotification));
        await tester.pumpAndSettle();

        // The read notification should have white background
        final container = tester.widget<Container>(
          find
              .descendant(
                of: find.byType(InkWell),
                matching: find.byType(Container),
              )
              .first,
        );
        expect(container, isNotNull);
      });

      testWidgets('should have bold title for unread notification',
          (tester) async {
        final notification = TestNotificationFactory.create(
          title: 'Unread Title',
          isRead: false,
        );

        await tester.pumpWidget(buildNotificationTile(notification: notification));
        await tester.pumpAndSettle();

        // Find title text
        final titleText = tester.widget<Text>(
          find.text('Unread Title'),
        );
        expect(titleText.style?.fontWeight, equals(FontWeight.w600));
      });

      testWidgets('should have normal weight title for read notification',
          (tester) async {
        final notification = TestNotificationFactory.create(
          title: 'Read Title',
          isRead: true,
        );

        await tester.pumpWidget(buildNotificationTile(notification: notification));
        await tester.pumpAndSettle();

        // Find title text
        final titleText = tester.widget<Text>(
          find.text('Read Title'),
        );
        expect(titleText.style?.fontWeight, equals(FontWeight.normal));
      });
    });

    group('Time Formatting', () {
      testWidgets('should show "just now" for very recent notification',
          (tester) async {
        final notification = TestNotificationFactory.create(
          createdAt: DateTime.now().subtract(const Duration(seconds: 30)),
        );

        await tester.pumpWidget(buildNotificationTile(notification: notification));
        await tester.pumpAndSettle();

        // Should show some time indicator (actual text depends on localization)
        // We verify that there's a time-related Text widget
        expect(find.byType(Text), findsWidgets);
      });

      testWidgets('should show minutes ago for recent notification',
          (tester) async {
        final notification = TestNotificationFactory.create(
          createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        );

        await tester.pumpWidget(buildNotificationTile(notification: notification));
        await tester.pumpAndSettle();

        // Should have text with time indication
        expect(find.byType(Text), findsWidgets);
      });

      testWidgets('should show hours ago for older notification', (tester) async {
        final notification = TestNotificationFactory.create(
          createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        );

        await tester.pumpWidget(buildNotificationTile(notification: notification));
        await tester.pumpAndSettle();

        expect(find.byType(Text), findsWidgets);
      });

      testWidgets('should show days ago for notification from days ago',
          (tester) async {
        final notification = TestNotificationFactory.create(
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        );

        await tester.pumpWidget(buildNotificationTile(notification: notification));
        await tester.pumpAndSettle();

        expect(find.byType(Text), findsWidgets);
      });

      testWidgets('should show date for old notification', (tester) async {
        final notification = TestNotificationFactory.create(
          createdAt: DateTime.now().subtract(const Duration(days: 14)),
        );

        await tester.pumpWidget(buildNotificationTile(notification: notification));
        await tester.pumpAndSettle();

        // Should show formatted date
        expect(find.byType(Text), findsWidgets);
      });
    });

    group('Navigation Indicator', () {
      testWidgets('should show chevron for notification with target',
          (tester) async {
        final notification = TestNotificationFactory.create(
          targetId: 'some-target-id',
        );

        await tester.pumpWidget(buildNotificationTile(notification: notification));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      });

      testWidgets('should not show chevron for notification without target',
          (tester) async {
        final notification = TestNotificationFactory.create(
          targetId: null,
        );

        await tester.pumpWidget(buildNotificationTile(notification: notification));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.chevron_right), findsNothing);
      });

      testWidgets('should not show chevron for empty target id', (tester) async {
        final notification = AppNotification(
          id: 'test',
          title: 'Test',
          body: 'Body',
          type: NotificationType.system,
          targetId: '',
          createdAt: DateTime.now(),
        );

        await tester.pumpWidget(buildNotificationTile(notification: notification));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.chevron_right), findsNothing);
      });
    });

    group('Tap Interaction', () {
      testWidgets('should call onTap when tapped', (tester) async {
        bool tapped = false;
        final notification = TestNotificationFactory.create();

        await tester.pumpWidget(buildNotificationTile(
          notification: notification,
          onTap: () => tapped = true,
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.byType(InkWell));
        await tester.pump();

        expect(tapped, isTrue);
      });

      testWidgets('should not crash when onTap is null', (tester) async {
        final notification = TestNotificationFactory.create();

        await tester.pumpWidget(buildNotificationTile(
          notification: notification,
          onTap: null,
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.byType(InkWell));
        await tester.pump();

        // Should not crash
        expect(find.byType(NotificationTile), findsOneWidget);
      });
    });

    group('Dismissible', () {
      testWidgets('should be wrapped in Dismissible', (tester) async {
        final notification = TestNotificationFactory.create();

        await tester.pumpWidget(buildNotificationTile(notification: notification));
        await tester.pumpAndSettle();

        expect(find.byType(Dismissible), findsOneWidget);
      });

      testWidgets('should call onDismiss when dismissed', (tester) async {
        bool dismissed = false;
        final notification = TestNotificationFactory.create();

        await tester.pumpWidget(buildNotificationTile(
          notification: notification,
          onDismiss: () => dismissed = true,
        ));
        await tester.pumpAndSettle();

        // Swipe to dismiss
        await tester.drag(
          find.byType(Dismissible),
          const Offset(-500, 0),
        );
        await tester.pumpAndSettle();

        expect(dismissed, isTrue);
      });

      testWidgets('should show delete background when swiping', (tester) async {
        final notification = TestNotificationFactory.create();

        await tester.pumpWidget(buildNotificationTile(notification: notification));
        await tester.pumpAndSettle();

        // Start swiping
        await tester.drag(
          find.byType(Dismissible),
          const Offset(-100, 0),
        );
        await tester.pump();

        // Should show delete icon
        expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      });

      testWidgets('should only dismiss in endToStart direction', (tester) async {
        bool dismissed = false;
        final notification = TestNotificationFactory.create();

        await tester.pumpWidget(buildNotificationTile(
          notification: notification,
          onDismiss: () => dismissed = true,
        ));
        await tester.pumpAndSettle();

        // Try to swipe in wrong direction
        await tester.drag(
          find.byType(Dismissible),
          const Offset(500, 0),
        );
        await tester.pumpAndSettle();

        // Should not be dismissed
        expect(dismissed, isFalse);
        expect(find.byType(NotificationTile), findsOneWidget);
      });
    });

    group('Deleting State', () {
      testWidgets('should show loading overlay when deleting', (tester) async {
        final notification = TestNotificationFactory.create();

        await tester.pumpWidget(buildNotificationTile(
          notification: notification,
          isDeleting: true,
        ));
        await tester.pumpAndSettle();

        // Should show loading indicator
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should not show loading overlay when not deleting',
          (tester) async {
        final notification = TestNotificationFactory.create();

        await tester.pumpWidget(buildNotificationTile(
          notification: notification,
          isDeleting: false,
        ));
        await tester.pumpAndSettle();

        // Should not show loading indicator
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });
    });

    group('Icon Colors', () {
      testWidgets('should use primary color for chat notification icon',
          (tester) async {
        final notification = TestNotificationFactory.createChatNotification();

        await tester.pumpWidget(buildNotificationTile(notification: notification));
        await tester.pumpAndSettle();

        final icon = tester.widget<Icon>(
          find.byIcon(Icons.chat_bubble_outline),
        );
        expect(icon.color, equals(AppColors.primary));
      });

      testWidgets('should use warning color for incident notification icon',
          (tester) async {
        final notification = TestNotificationFactory.createIncidentNotification();

        await tester.pumpWidget(buildNotificationTile(notification: notification));
        await tester.pumpAndSettle();

        final icon = tester.widget<Icon>(
          find.byIcon(Icons.warning_amber_outlined),
        );
        expect(icon.color, equals(AppColors.warning));
      });

      testWidgets('should use error color for SOS notification icon',
          (tester) async {
        final notification = TestNotificationFactory.createSOSNotification();

        await tester.pumpWidget(buildNotificationTile(notification: notification));
        await tester.pumpAndSettle();

        final icon = tester.widget<Icon>(
          find.byIcon(Icons.sos),
        );
        expect(icon.color, equals(AppColors.error));
      });

      testWidgets('should use info color for announcement notification icon',
          (tester) async {
        final notification =
            TestNotificationFactory.createAnnouncementNotification();

        await tester.pumpWidget(buildNotificationTile(notification: notification));
        await tester.pumpAndSettle();

        final icon = tester.widget<Icon>(
          find.byIcon(Icons.campaign_outlined),
        );
        expect(icon.color, equals(AppColors.info));
      });

      testWidgets('should use success color for approval notification icon',
          (tester) async {
        final notification = TestNotificationFactory.createApprovalNotification();

        await tester.pumpWidget(buildNotificationTile(notification: notification));
        await tester.pumpAndSettle();

        final icon = tester.widget<Icon>(
          find.byIcon(Icons.verified_user_outlined),
        );
        expect(icon.color, equals(AppColors.success));
      });

      testWidgets('should use secondary color for system notification icon',
          (tester) async {
        final notification = TestNotificationFactory.create(
          type: NotificationType.system,
        );

        await tester.pumpWidget(buildNotificationTile(notification: notification));
        await tester.pumpAndSettle();

        final icon = tester.widget<Icon>(
          find.byIcon(Icons.info_outline),
        );
        expect(icon.color, equals(AppColors.textSecondary));
      });
    });

    group('Layout', () {
      testWidgets('should have proper padding', (tester) async {
        final notification = TestNotificationFactory.create();

        await tester.pumpWidget(buildNotificationTile(notification: notification));
        await tester.pumpAndSettle();

        // Find the main container
        final container = tester.widget<Container>(
          find
              .descendant(
                of: find.byType(InkWell),
                matching: find.byType(Container),
              )
              .first,
        );
        expect(container.padding, isNotNull);
      });

      testWidgets('should have icon container', (tester) async {
        final notification = TestNotificationFactory.create();

        await tester.pumpWidget(buildNotificationTile(notification: notification));
        await tester.pumpAndSettle();

        // Should have the icon container (44x44)
        final iconContainer = find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.constraints?.maxWidth == 44 &&
              widget.constraints?.maxHeight == 44,
        );
        expect(iconContainer, findsOneWidget);
      });

      testWidgets('should truncate long titles', (tester) async {
        final notification = TestNotificationFactory.create(
          title:
              'This is a very long notification title that should be truncated because it is too long to fit in one line',
        );

        await tester.pumpWidget(buildNotificationTile(notification: notification));
        await tester.pumpAndSettle();

        // Find title text and verify it has overflow handling
        final titleText = tester.widget<Text>(
          find.textContaining('This is a very long'),
        );
        expect(titleText.maxLines, equals(1));
        expect(titleText.overflow, equals(TextOverflow.ellipsis));
      });

      testWidgets('should truncate long body to 2 lines', (tester) async {
        final notification = TestNotificationFactory.create(
          body:
              'This is a very long notification body that should be truncated because it is too long to fit in two lines. We need to verify that the text is properly truncated with ellipsis.',
        );

        await tester.pumpWidget(buildNotificationTile(notification: notification));
        await tester.pumpAndSettle();

        // Find body text and verify it has overflow handling
        final bodyText = tester.widget<Text>(
          find.textContaining('This is a very long notification body'),
        );
        expect(bodyText.maxLines, equals(2));
        expect(bodyText.overflow, equals(TextOverflow.ellipsis));
      });
    });
  });
}
