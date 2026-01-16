import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:riderapp/features/home/presentation/screens/rider_home_screen.dart';

void main() {
  group('RiderHomeScreen', () {
    Widget buildRiderHomeScreen() {
      return ProviderScope(
        child: MaterialApp(
          home: const RiderHomeScreen(),
          localizationsDelegates: const [
            DefaultMaterialLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
          ],
        ),
      );
    }

    Widget buildRiderHomeScreenWithNavigation() {
      return ProviderScope(
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/rider',
            routes: [
              GoRoute(
                path: '/rider',
                builder: (context, state) => const RiderHomeScreen(),
              ),
              GoRoute(
                path: '/notifications',
                builder: (context, state) => const Scaffold(
                  body: Center(child: Text('Notifications Screen')),
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
                path: '/profile',
                builder: (context, state) => const Scaffold(
                  body: Center(child: Text('Profile Screen')),
                ),
              ),
              GoRoute(
                path: '/login',
                builder: (context, state) => const Scaffold(
                  body: Center(child: Text('Login Screen')),
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
      testWidgets('should render correctly', (tester) async {
        await tester.pumpWidget(buildRiderHomeScreen());
        await tester.pump();

        // Verify screen is rendered
        expect(find.byType(RiderHomeScreen), findsOneWidget);
      });

      testWidgets('should have app bar', (tester) async {
        await tester.pumpWidget(buildRiderHomeScreen());
        await tester.pump();

        expect(find.byType(AppBar), findsOneWidget);
      });

      testWidgets('should show notification icon in app bar', (tester) async {
        await tester.pumpWidget(buildRiderHomeScreen());
        await tester.pump();

        expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
      });

      testWidgets('should show profile icon in app bar', (tester) async {
        await tester.pumpWidget(buildRiderHomeScreen());
        await tester.pump();

        expect(find.byIcon(Icons.person_outline), findsOneWidget);
      });

      testWidgets('should show logout icon in app bar', (tester) async {
        await tester.pumpWidget(buildRiderHomeScreen());
        await tester.pump();

        expect(find.byIcon(Icons.logout), findsOneWidget);
      });
    });

    group('Bottom Navigation', () {
      testWidgets('should have bottom navigation bar', (tester) async {
        await tester.pumpWidget(buildRiderHomeScreen());
        await tester.pump();

        expect(find.byType(BottomNavigationBar), findsOneWidget);
      });

      testWidgets('should have 4 navigation items', (tester) async {
        await tester.pumpWidget(buildRiderHomeScreen());
        await tester.pump();

        final bottomNav = tester.widget<BottomNavigationBar>(
          find.byType(BottomNavigationBar),
        );
        expect(bottomNav.items.length, equals(4));
      });

      testWidgets('should show home icon', (tester) async {
        await tester.pumpWidget(buildRiderHomeScreen());
        await tester.pump();

        expect(find.byIcon(Icons.home), findsOneWidget);
      });

      testWidgets('should show report icon', (tester) async {
        await tester.pumpWidget(buildRiderHomeScreen());
        await tester.pump();

        expect(find.byIcon(Icons.report), findsOneWidget);
      });

      testWidgets('should show chat icon in bottom nav', (tester) async {
        await tester.pumpWidget(buildRiderHomeScreen());
        await tester.pump();

        // Chat icon should exist (may be in nav or action cards)
        expect(find.byIcon(Icons.chat), findsWidgets);
      });

      testWidgets('should show person icon', (tester) async {
        await tester.pumpWidget(buildRiderHomeScreen());
        await tester.pump();

        expect(find.byIcon(Icons.person), findsOneWidget);
      });

      testWidgets('home should be current index', (tester) async {
        await tester.pumpWidget(buildRiderHomeScreen());
        await tester.pump();

        final bottomNav = tester.widget<BottomNavigationBar>(
          find.byType(BottomNavigationBar),
        );
        expect(bottomNav.currentIndex, equals(0));
      });
    });

    group('Quick Action Cards', () {
      testWidgets('should show grid view with action cards', (tester) async {
        await tester.pumpWidget(buildRiderHomeScreen());
        await tester.pump();

        expect(find.byType(GridView), findsOneWidget);
      });

      testWidgets('should show report incident icon', (tester) async {
        await tester.pumpWidget(buildRiderHomeScreen());
        await tester.pump();

        expect(find.byIcon(Icons.report_problem), findsOneWidget);
      });

      testWidgets('should show view reports icon', (tester) async {
        await tester.pumpWidget(buildRiderHomeScreen());
        await tester.pump();

        expect(find.byIcon(Icons.list_alt), findsOneWidget);
      });

      testWidgets('should show emergency call icon', (tester) async {
        await tester.pumpWidget(buildRiderHomeScreen());
        await tester.pump();

        expect(find.byIcon(Icons.phone_in_talk), findsOneWidget);
      });

      testWidgets('action cards should be tappable', (tester) async {
        await tester.pumpWidget(buildRiderHomeScreen());
        await tester.pump();

        // Find InkWell widgets inside GridView (action cards)
        final gridView = find.byType(GridView);
        expect(gridView, findsOneWidget);

        final inkWells = find.descendant(
          of: gridView,
          matching: find.byType(InkWell),
        );
        expect(inkWells, findsNWidgets(4));
      });
    });

    group('Welcome Card', () {
      testWidgets('should have welcome card with gradient', (tester) async {
        await tester.pumpWidget(buildRiderHomeScreen());
        await tester.pump();

        // Find container with LinearGradient
        final gradientContainer = find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).gradient is LinearGradient,
        );
        expect(gradientContainer, findsOneWidget);
      });
    });

    group('Navigation', () {
      testWidgets('should navigate to notifications when bell icon is tapped',
          (tester) async {
        await tester.pumpWidget(buildRiderHomeScreenWithNavigation());
        await tester.pump();

        // Tap notification icon
        await tester.tap(find.byIcon(Icons.notifications_outlined));
        await tester.pumpAndSettle();

        expect(find.text('Notifications Screen'), findsOneWidget);
      });

      testWidgets('bottom nav incidents tab should navigate', (tester) async {
        await tester.pumpWidget(buildRiderHomeScreenWithNavigation());
        await tester.pump();

        // Tap incidents tab (index 1)
        await tester.tap(find.byIcon(Icons.report));
        await tester.pumpAndSettle();

        expect(find.text('My Incidents Screen'), findsOneWidget);
      });

      testWidgets('bottom nav profile tab should navigate', (tester) async {
        await tester.pumpWidget(buildRiderHomeScreenWithNavigation());
        await tester.pump();

        // Tap profile tab
        await tester.tap(find.byIcon(Icons.person));
        await tester.pumpAndSettle();

        expect(find.text('Profile Screen'), findsOneWidget);
      });
    });

    group('Refresh', () {
      testWidgets('should support pull to refresh', (tester) async {
        await tester.pumpWidget(buildRiderHomeScreen());
        await tester.pump();

        expect(find.byType(RefreshIndicator), findsOneWidget);
      });
    });

    group('Error Handling', () {
      testWidgets('should not crash on load', (tester) async {
        await tester.pumpWidget(buildRiderHomeScreen());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // Screen should still be present
        expect(find.byType(RiderHomeScreen), findsOneWidget);
      });
    });

    group('Accessibility', () {
      testWidgets('bottom nav items should have labels', (tester) async {
        await tester.pumpWidget(buildRiderHomeScreen());
        await tester.pump();

        final bottomNav = tester.widget<BottomNavigationBar>(
          find.byType(BottomNavigationBar),
        );

        // All items should have labels
        for (final item in bottomNav.items) {
          expect(item.label, isNotNull);
        }
      });
    });
  });
}
