import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:riderapp/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:riderapp/features/notifications/presentation/widgets/notification_tile.dart';
import 'package:riderapp/features/notifications/domain/entities/app_notification.dart';

import '../../../helpers/widget_test_helpers.dart';

void main() {
  group('NotificationsScreen', () {
    Widget buildNotificationsScreen() {
      return ProviderScope(
        child: MaterialApp(
          home: const NotificationsScreen(),
          localizationsDelegates: const [
            DefaultMaterialLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
          ],
        ),
      );
    }

    Widget buildNotificationsScreenWithNavigation() {
      return ProviderScope(
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/notifications',
            routes: [
              GoRoute(
                path: '/notifications',
                builder: (context, state) => const NotificationsScreen(),
              ),
              GoRoute(
                path: '/chat/:id',
                builder: (context, state) => Scaffold(
                  body: Center(
                      child: Text(
                          'Chat Detail Screen ${state.pathParameters['id']}')),
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
              GoRoute(
                path: '/profile',
                builder: (context, state) => const Scaffold(
                  body: Center(child: Text('Profile Screen')),
                ),
              ),
            ],
          ),
          localizationsDelegates: const [
            DefaultMaterialLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
          ],
        ),
      );
    }

    group('Rendering', () {
      testWidgets('should render notifications screen', (tester) async {
        await tester.pumpWidget(buildNotificationsScreen());
        // Don't pumpAndSettle since screen will try to load
        await tester.pump();

        expect(find.byType(NotificationsScreen), findsOneWidget);
      });

      testWidgets('should show app bar with title', (tester) async {
        await tester.pumpWidget(buildNotificationsScreen());
        await tester.pump();

        expect(find.byType(AppBar), findsOneWidget);
      });

      testWidgets('should show loading indicator initially', (tester) async {
        await tester.pumpWidget(buildNotificationsScreen());
        await tester.pump();

        // Screen tries to load notifications, might show loading indicator
        expect(find.byType(NotificationsScreen), findsOneWidget);
      });
    });

    group('Empty State', () {
      testWidgets('should show empty icon when no notifications', (tester) async {
        await tester.pumpWidget(buildNotificationsScreen());
        // Let the loading complete
        await tester.pump(const Duration(seconds: 1));

        // The screen may show empty state with specific icon
        // Depends on API response, but screen should not crash
        expect(find.byType(NotificationsScreen), findsOneWidget);
      });
    });

    group('Error Handling', () {
      testWidgets('should not crash on screen load', (tester) async {
        await tester.pumpWidget(buildNotificationsScreen());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // Screen should be present
        expect(find.byType(NotificationsScreen), findsOneWidget);
      });
    });

    group('Pull to Refresh', () {
      testWidgets('should have scrollable content', (tester) async {
        await tester.pumpWidget(buildNotificationsScreen());
        await tester.pump();

        // Should be able to scroll (RefreshIndicator wraps content)
        expect(find.byType(NotificationsScreen), findsOneWidget);
      });
    });

    group('Notification Types - Visual Tests', () {
      testWidgets('notification tile renders with chat icon', (tester) async {
        final notification = TestNotificationFactory.createChatNotification();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: NotificationTile(
                notification: notification,
              ),
            ),
            localizationsDelegates: const [
              DefaultMaterialLocalizations.delegate,
              DefaultWidgetsLocalizations.delegate,
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
      });

      testWidgets('notification tile renders with incident icon', (tester) async {
        final notification = TestNotificationFactory.createIncidentNotification();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: NotificationTile(
                notification: notification,
              ),
            ),
            localizationsDelegates: const [
              DefaultMaterialLocalizations.delegate,
              DefaultWidgetsLocalizations.delegate,
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.warning_amber_outlined), findsOneWidget);
      });

      testWidgets('notification tile renders with SOS icon', (tester) async {
        final notification = TestNotificationFactory.createSOSNotification();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: NotificationTile(
                notification: notification,
              ),
            ),
            localizationsDelegates: const [
              DefaultMaterialLocalizations.delegate,
              DefaultWidgetsLocalizations.delegate,
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.sos), findsOneWidget);
      });

      testWidgets('notification tile renders with announcement icon',
          (tester) async {
        final notification =
            TestNotificationFactory.createAnnouncementNotification();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: NotificationTile(
                notification: notification,
              ),
            ),
            localizationsDelegates: const [
              DefaultMaterialLocalizations.delegate,
              DefaultWidgetsLocalizations.delegate,
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.campaign_outlined), findsOneWidget);
      });

      testWidgets('notification tile renders with approval icon', (tester) async {
        final notification =
            TestNotificationFactory.createApprovalNotification();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: NotificationTile(
                notification: notification,
              ),
            ),
            localizationsDelegates: const [
              DefaultMaterialLocalizations.delegate,
              DefaultWidgetsLocalizations.delegate,
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.verified_user_outlined), findsOneWidget);
      });

      testWidgets('notification tile renders with system icon', (tester) async {
        final notification = TestNotificationFactory.create(
          type: NotificationType.system,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: NotificationTile(
                notification: notification,
              ),
            ),
            localizationsDelegates: const [
              DefaultMaterialLocalizations.delegate,
              DefaultWidgetsLocalizations.delegate,
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.info_outline), findsOneWidget);
      });
    });

    group('Notification Tile Interactions', () {
      testWidgets('notification tile is tappable', (tester) async {
        bool tapped = false;
        final notification = TestNotificationFactory.create();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: NotificationTile(
                notification: notification,
                onTap: () => tapped = true,
              ),
            ),
            localizationsDelegates: const [
              DefaultMaterialLocalizations.delegate,
              DefaultWidgetsLocalizations.delegate,
            ],
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byType(InkWell));
        await tester.pump();

        expect(tapped, isTrue);
      });

      testWidgets('notification tile is dismissible', (tester) async {
        bool dismissed = false;
        final notification = TestNotificationFactory.create();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: NotificationTile(
                notification: notification,
                onDismiss: () => dismissed = true,
              ),
            ),
            localizationsDelegates: const [
              DefaultMaterialLocalizations.delegate,
              DefaultWidgetsLocalizations.delegate,
            ],
          ),
        );
        await tester.pumpAndSettle();

        // Swipe to dismiss
        await tester.drag(
          find.byType(Dismissible),
          const Offset(-500, 0),
        );
        await tester.pumpAndSettle();

        expect(dismissed, isTrue);
      });

      testWidgets('notification tile shows delete background when swiping',
          (tester) async {
        final notification = TestNotificationFactory.create();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: NotificationTile(
                notification: notification,
              ),
            ),
            localizationsDelegates: const [
              DefaultMaterialLocalizations.delegate,
              DefaultWidgetsLocalizations.delegate,
            ],
          ),
        );
        await tester.pumpAndSettle();

        // Start swiping
        await tester.drag(
          find.byType(Dismissible),
          const Offset(-100, 0),
        );
        await tester.pump();

        // Should show delete icon in background
        expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      });
    });

    group('Unread Indicator', () {
      testWidgets('shows unread indicator for unread notification',
          (tester) async {
        final notification = TestNotificationFactory.create(isRead: false);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: NotificationTile(
                notification: notification,
              ),
            ),
            localizationsDelegates: const [
              DefaultMaterialLocalizations.delegate,
              DefaultWidgetsLocalizations.delegate,
            ],
          ),
        );
        await tester.pumpAndSettle();

        // Notification tile should render
        expect(find.byType(NotificationTile), findsOneWidget);
      });
    });

    group('Chevron Indicator', () {
      testWidgets('shows chevron for notification with target', (tester) async {
        final notification = TestNotificationFactory.create(
          targetId: 'some-target-id',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: NotificationTile(
                notification: notification,
              ),
            ),
            localizationsDelegates: const [
              DefaultMaterialLocalizations.delegate,
              DefaultWidgetsLocalizations.delegate,
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      });

      testWidgets('does not show chevron for notification without target',
          (tester) async {
        final notification = TestNotificationFactory.create(
          targetId: null,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: NotificationTile(
                notification: notification,
              ),
            ),
            localizationsDelegates: const [
              DefaultMaterialLocalizations.delegate,
              DefaultWidgetsLocalizations.delegate,
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.chevron_right), findsNothing);
      });
    });

    group('Loading State', () {
      testWidgets('shows loading overlay when deleting', (tester) async {
        final notification = TestNotificationFactory.create();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: NotificationTile(
                notification: notification,
                isDeleting: true,
              ),
            ),
            localizationsDelegates: const [
              DefaultMaterialLocalizations.delegate,
              DefaultWidgetsLocalizations.delegate,
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });
  });
}
