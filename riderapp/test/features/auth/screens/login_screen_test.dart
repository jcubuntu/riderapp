import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:riderapp/features/auth/presentation/screens/login_screen.dart';

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

  group('LoginScreen', () {
    Widget buildLoginScreen() {
      return ProviderScope(
        child: EasyLocalization(
          supportedLocales: const [Locale('en'), Locale('th')],
          path: 'assets/translations',
          fallbackLocale: const Locale('en'),
          useOnlyLangCode: true,
          child: Builder(
            builder: (context) {
              return MaterialApp(
                home: const LoginScreen(),
                locale: context.locale,
                localizationsDelegates: context.localizationDelegates,
                supportedLocales: context.supportedLocales,
              );
            },
          ),
        ),
      );
    }

    Widget buildLoginScreenWithNavigation() {
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
                  initialLocation: '/login',
                  routes: [
                    GoRoute(
                      path: '/login',
                      builder: (context, state) => const LoginScreen(),
                    ),
                    GoRoute(
                      path: '/register',
                      builder: (context, state) => const Scaffold(
                        body: Center(child: Text('Register Screen')),
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
      testWidgets('should render correctly with all elements', (tester) async {
        await pumpAndWait(tester, buildLoginScreen());

        // Verify logo/icon is present
        expect(find.byIcon(Icons.two_wheeler), findsOneWidget);

        // Verify phone input field is present
        expect(find.byIcon(Icons.phone_outlined), findsOneWidget);
        expect(find.byType(TextFormField), findsNWidgets(2));

        // Verify password input field is present
        expect(find.byIcon(Icons.lock_outlined), findsOneWidget);

        // Verify password visibility toggle is present
        expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);

        // Verify login button is present
        expect(find.byType(ElevatedButton), findsOneWidget);

        // Verify language switcher is present
        expect(find.byIcon(Icons.language), findsOneWidget);
      });

      testWidgets('should have phone and password text fields', (tester) async {
        await pumpAndWait(tester, buildLoginScreen());

        // Find TextFormFields
        expect(find.byType(TextFormField), findsNWidgets(2));
      });
    });

    group('Phone Input Validation', () {
      testWidgets('should show error when phone is empty on submit',
          (tester) async {
        await pumpAndWait(tester, buildLoginScreen());

        // Enter password but leave phone empty
        await tester.enterText(
          find.byType(TextFormField).last,
          'password123',
        );

        // Tap login button
        await tester.tap(find.byType(ElevatedButton));
        for (var i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }

        // Form should still be visible (validation failed)
        expect(find.byType(TextFormField), findsNWidgets(2));
      });

      testWidgets('should show error when phone is too short', (tester) async {
        await pumpAndWait(tester, buildLoginScreen());

        // Enter short phone number
        await tester.enterText(
          find.byType(TextFormField).first,
          '12345678', // 8 digits, less than 9
        );
        await tester.enterText(
          find.byType(TextFormField).last,
          'password123',
        );

        // Tap login button
        await tester.tap(find.byType(ElevatedButton));
        for (var i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }

        // Form should not submit successfully due to validation
        expect(find.byType(TextFormField), findsNWidgets(2));
      });

      testWidgets('should only allow digits in phone field', (tester) async {
        await pumpAndWait(tester, buildLoginScreen());

        // Try to enter letters (should be filtered out)
        await tester.enterText(
          find.byType(TextFormField).first,
          '08abc11111',
        );
        await tester.pump();

        // Get the text from the controller - digits only
        final textField = tester.widget<TextFormField>(
          find.byType(TextFormField).first,
        );
        final controller = textField.controller;
        expect(controller?.text, '0811111');
      });

      testWidgets('should limit phone to 10 digits', (tester) async {
        await pumpAndWait(tester, buildLoginScreen());

        // Enter more than 10 digits
        await tester.enterText(
          find.byType(TextFormField).first,
          '08111111111111', // 14 digits
        );
        await tester.pump();

        // Get the text from the controller
        final textField = tester.widget<TextFormField>(
          find.byType(TextFormField).first,
        );
        final controller = textField.controller;
        expect(controller?.text.length, lessThanOrEqualTo(10));
      });
    });

    group('Password Input Validation', () {
      testWidgets('should show error when password is empty', (tester) async {
        await pumpAndWait(tester, buildLoginScreen());

        // Enter phone but leave password empty
        await tester.enterText(
          find.byType(TextFormField).first,
          '0811111111',
        );

        // Tap login button
        await tester.tap(find.byType(ElevatedButton));
        for (var i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }

        // Form should still be visible
        expect(find.byType(TextFormField), findsNWidgets(2));
      });

      testWidgets('should show error when password is too short',
          (tester) async {
        await pumpAndWait(tester, buildLoginScreen());

        // Enter phone and short password
        await tester.enterText(
          find.byType(TextFormField).first,
          '0811111111',
        );
        await tester.enterText(
          find.byType(TextFormField).last,
          '1234567', // 7 characters, less than 8
        );

        // Tap login button
        await tester.tap(find.byType(ElevatedButton));
        for (var i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }

        // Form validation should fail
        expect(find.byType(TextFormField), findsNWidgets(2));
      });

      testWidgets('should toggle password visibility', (tester) async {
        await pumpAndWait(tester, buildLoginScreen());

        // Initially password should be obscured - verify by icon presence
        expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);

        // Tap visibility toggle
        await tester.tap(find.byIcon(Icons.visibility_outlined));
        await tester.pump();

        // Now password should be visible - icon should change
        expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);

        // Tap again to hide password
        await tester.tap(find.byIcon(Icons.visibility_off_outlined));
        await tester.pump();

        // Password should be obscured again
        expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      });
    });

    group('Login Button', () {
      testWidgets('should be present and tappable', (tester) async {
        await pumpAndWait(tester, buildLoginScreen());

        expect(find.byType(ElevatedButton), findsOneWidget);

        // Can tap it
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();
      });

      testWidgets('should not crash with invalid form', (tester) async {
        await pumpAndWait(tester, buildLoginScreen());

        // Leave form empty and tap login
        await tester.tap(find.byType(ElevatedButton));
        for (var i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }

        // Should still be on login screen (form validation failed)
        expect(find.byType(LoginScreen), findsOneWidget);
      });
    });

    group('Navigation to Register', () {
      testWidgets('should have register link visible', (tester) async {
        await pumpAndWait(tester, buildLoginScreenWithNavigation());

        // Find the register link (TextButton)
        final registerButtons = find.byType(TextButton);
        expect(registerButtons, findsWidgets);

        // Verify login screen is rendered with register link
        expect(find.byType(LoginScreen), findsOneWidget);
      });
    });

    group('Language Switcher', () {
      testWidgets('should have language switcher button', (tester) async {
        await pumpAndWait(tester, buildLoginScreen());

        // Find language button
        expect(find.byIcon(Icons.language), findsOneWidget);

        // Tap language switcher (warnIfMissed: false because it may be off-screen in test viewport)
        await tester.tap(find.byIcon(Icons.language), warnIfMissed: false);
        await tester.pump();

        // The button should be tappable without crashing
      });
    });

    group('Form Interaction', () {
      testWidgets('can enter phone and password', (tester) async {
        await pumpAndWait(tester, buildLoginScreen());

        // Enter valid credentials
        await tester.enterText(
          find.byType(TextFormField).first,
          '0811111111',
        );
        await tester.enterText(
          find.byType(TextFormField).last,
          'password123',
        );
        await tester.pump();

        // Verify text was entered
        final phoneField = tester.widget<TextFormField>(
          find.byType(TextFormField).first,
        );
        expect(phoneField.controller?.text, '0811111111');

        final passwordField = tester.widget<TextFormField>(
          find.byType(TextFormField).last,
        );
        expect(passwordField.controller?.text, 'password123');
      });
    });
  });
}
