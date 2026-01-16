import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:riderapp/features/home/presentation/screens/rider_home_screen.dart';

void main() {
  // Initialize test environment before all tests
  setUpAll(() async {
    // Initialize Flutter bindings for tests
    TestWidgetsFlutterBinding.ensureInitialized();
    // Initialize SharedPreferences with mock values
    SharedPreferences.setMockInitialValues({});
    // Initialize EasyLocalization
    await EasyLocalization.ensureInitialized();
  });

  /// Helper function to pump widget and wait for EasyLocalization to load.
  /// Uses runAsync to properly handle asynchronous asset loading.
  Future<void> pumpAndWait(WidgetTester tester, Widget widget) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(widget);
      // Allow time for EasyLocalization to load assets
      await Future.delayed(const Duration(milliseconds: 500));
    });
    // Pump frames to render the UI
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  group('RiderHomeScreen', () {
    Widget buildRiderHomeScreen() {
      return ProviderScope(
        child: EasyLocalization(
          supportedLocales: const [Locale('en'), Locale('th')],
          path: 'assets/translations',
          fallbackLocale: const Locale('en'),
          useOnlyLangCode: true,
          child: Builder(
            builder: (context) {
              return MaterialApp(
                home: const RiderHomeScreen(),
                locale: context.locale,
                localizationsDelegates: context.localizationDelegates,
                supportedLocales: context.supportedLocales,
              );
            },
          ),
        ),
      );
    }

    Widget buildRiderHomeScreenWithNavigation() {
      return ProviderScope(
        child: EasyLocalization(
          supportedLocales: const [Locale('en'), Locale('th')],
          path: 'assets/translations',
          fallbackLocale: const Locale('en'),
          useOnlyLangCode: true,
          child: Builder(
            builder: (context) {
              return MaterialApp.router(
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
                locale: context.locale,
                localizationsDelegates: context.localizationDelegates,
                supportedLocales: context.supportedLocales,
              );
            },
          ),
        ),
      );
    }

    group('Rendering', () {
      testWidgets('should render correctly', (tester) async {
        await pumpAndWait(tester, buildRiderHomeScreen());

        // Verify screen is rendered
        expect(find.byType(RiderHomeScreen), findsOneWidget);
      });

      testWidgets('should have app bar', (tester) async {
        await pumpAndWait(tester, buildRiderHomeScreen());

        expect(find.byType(AppBar), findsOneWidget);
      });

      testWidgets('should show notification icon in app bar', (tester) async {
        await pumpAndWait(tester, buildRiderHomeScreen());

        expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
      });

      testWidgets('should show profile icon in app bar', (tester) async {
        await pumpAndWait(tester, buildRiderHomeScreen());

        expect(find.byIcon(Icons.person_outline), findsOneWidget);
      });

      testWidgets('should show logout icon in app bar', (tester) async {
        await pumpAndWait(tester, buildRiderHomeScreen());

        expect(find.byIcon(Icons.logout), findsOneWidget);
      });
    });

    group('Bottom Navigation', () {
      testWidgets('should have bottom navigation bar', (tester) async {
        await pumpAndWait(tester, buildRiderHomeScreen());

        expect(find.byType(BottomNavigationBar), findsOneWidget);
      });

      testWidgets('should have 4 navigation items', (tester) async {
        await pumpAndWait(tester, buildRiderHomeScreen());

        final bottomNav = tester.widget<BottomNavigationBar>(
          find.byType(BottomNavigationBar),
        );
        expect(bottomNav.items.length, equals(4));
      });

      testWidgets('should show home icon', (tester) async {
        await pumpAndWait(tester, buildRiderHomeScreen());

        expect(find.byIcon(Icons.home), findsOneWidget);
      });

      testWidgets('should show report icon', (tester) async {
        await pumpAndWait(tester, buildRiderHomeScreen());

        expect(find.byIcon(Icons.report), findsOneWidget);
      });

      testWidgets('should show chat icon in bottom nav', (tester) async {
        await pumpAndWait(tester, buildRiderHomeScreen());

        // Chat icon should exist (may be in nav or action cards)
        expect(find.byIcon(Icons.chat), findsWidgets);
      });

      testWidgets('should show person icon', (tester) async {
        await pumpAndWait(tester, buildRiderHomeScreen());

        expect(find.byIcon(Icons.person), findsOneWidget);
      });

      testWidgets('home should be current index', (tester) async {
        await pumpAndWait(tester, buildRiderHomeScreen());

        final bottomNav = tester.widget<BottomNavigationBar>(
          find.byType(BottomNavigationBar),
        );
        expect(bottomNav.currentIndex, equals(0));
      });
    });

    group('Quick Action Cards', () {
      testWidgets('should show grid view with action cards', (tester) async {
        await pumpAndWait(tester, buildRiderHomeScreen());

        expect(find.byType(GridView), findsOneWidget);
      });

      testWidgets('should show report incident icon', (tester) async {
        await pumpAndWait(tester, buildRiderHomeScreen());

        expect(find.byIcon(Icons.report_problem), findsOneWidget);
      });

      testWidgets('should show view reports icon', (tester) async {
        await pumpAndWait(tester, buildRiderHomeScreen());

        expect(find.byIcon(Icons.list_alt), findsOneWidget);
      });

      testWidgets('should show emergency call icon', (tester) async {
        await pumpAndWait(tester, buildRiderHomeScreen());

        expect(find.byIcon(Icons.phone_in_talk), findsOneWidget);
      });

      testWidgets('action cards should be tappable', (tester) async {
        await pumpAndWait(tester, buildRiderHomeScreen());

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
        await pumpAndWait(tester, buildRiderHomeScreen());

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
        await pumpAndWait(tester, buildRiderHomeScreenWithNavigation());

        // Tap notification icon
        await tester.tap(find.byIcon(Icons.notifications_outlined));
        // Use controlled pump for navigation
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }

        expect(find.text('Notifications Screen'), findsOneWidget);
      });

      testWidgets('bottom nav incidents tab should navigate', (tester) async {
        await pumpAndWait(tester, buildRiderHomeScreenWithNavigation());

        // Tap incidents tab (index 1)
        await tester.tap(find.byIcon(Icons.report));
        // Use controlled pump for navigation
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }

        expect(find.text('My Incidents Screen'), findsOneWidget);
      });

      testWidgets('bottom nav profile tab should navigate', (tester) async {
        await pumpAndWait(tester, buildRiderHomeScreenWithNavigation());

        // Tap profile tab
        await tester.tap(find.byIcon(Icons.person));
        // Use controlled pump for navigation
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }

        expect(find.text('Profile Screen'), findsOneWidget);
      });
    });

    group('Refresh', () {
      testWidgets('should support pull to refresh', (tester) async {
        await pumpAndWait(tester, buildRiderHomeScreen());

        expect(find.byType(RefreshIndicator), findsOneWidget);
      });
    });

    group('Error Handling', () {
      testWidgets('should not crash on load', (tester) async {
        await pumpAndWait(tester, buildRiderHomeScreen());

        // Screen should still be present
        expect(find.byType(RiderHomeScreen), findsOneWidget);
      });
    });

    group('Accessibility', () {
      testWidgets('bottom nav items should have labels', (tester) async {
        await pumpAndWait(tester, buildRiderHomeScreen());

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
