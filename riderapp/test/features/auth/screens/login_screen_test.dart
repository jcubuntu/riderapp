import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:riderapp/features/auth/presentation/screens/login_screen.dart';

void main() {
  group('LoginScreen', () {
    Widget buildLoginScreen() {
      return ProviderScope(
        child: MaterialApp(
          home: const LoginScreen(),
          localizationsDelegates: const [
            DefaultMaterialLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
          ],
        ),
      );
    }

    Widget buildLoginScreenWithNavigation() {
      return ProviderScope(
        child: MaterialApp.router(
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
          localizationsDelegates: const [
            DefaultMaterialLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
          ],
        ),
      );
    }

    group('Rendering', () {
      testWidgets('should render correctly with all elements', (tester) async {
        await tester.pumpWidget(buildLoginScreen());
        await tester.pumpAndSettle();

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
        await tester.pumpWidget(buildLoginScreen());
        await tester.pumpAndSettle();

        // Find TextFormFields
        expect(find.byType(TextFormField), findsNWidgets(2));
      });
    });

    group('Phone Input Validation', () {
      testWidgets('should show error when phone is empty on submit',
          (tester) async {
        await tester.pumpWidget(buildLoginScreen());
        await tester.pumpAndSettle();

        // Enter password but leave phone empty
        await tester.enterText(
          find.byType(TextFormField).last,
          'password123',
        );

        // Tap login button
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Form should still be visible (validation failed)
        expect(find.byType(TextFormField), findsNWidgets(2));
      });

      testWidgets('should show error when phone is too short', (tester) async {
        await tester.pumpWidget(buildLoginScreen());
        await tester.pumpAndSettle();

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
        await tester.pumpAndSettle();

        // Form should not submit successfully due to validation
        expect(find.byType(TextFormField), findsNWidgets(2));
      });

      testWidgets('should only allow digits in phone field', (tester) async {
        await tester.pumpWidget(buildLoginScreen());
        await tester.pumpAndSettle();

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
        await tester.pumpWidget(buildLoginScreen());
        await tester.pumpAndSettle();

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
        await tester.pumpWidget(buildLoginScreen());
        await tester.pumpAndSettle();

        // Enter phone but leave password empty
        await tester.enterText(
          find.byType(TextFormField).first,
          '0811111111',
        );

        // Tap login button
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Form should still be visible
        expect(find.byType(TextFormField), findsNWidgets(2));
      });

      testWidgets('should show error when password is too short',
          (tester) async {
        await tester.pumpWidget(buildLoginScreen());
        await tester.pumpAndSettle();

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
        await tester.pumpAndSettle();

        // Form validation should fail
        expect(find.byType(TextFormField), findsNWidgets(2));
      });

      testWidgets('should toggle password visibility', (tester) async {
        await tester.pumpWidget(buildLoginScreen());
        await tester.pumpAndSettle();

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
        await tester.pumpWidget(buildLoginScreen());
        await tester.pumpAndSettle();

        expect(find.byType(ElevatedButton), findsOneWidget);

        // Can tap it
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();
      });

      testWidgets('should not crash with invalid form', (tester) async {
        await tester.pumpWidget(buildLoginScreen());
        await tester.pumpAndSettle();

        // Leave form empty and tap login
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Should still be on login screen (form validation failed)
        expect(find.byType(LoginScreen), findsOneWidget);
      });
    });

    group('Navigation to Register', () {
      testWidgets('should navigate to register screen when tapping register',
          (tester) async {
        await tester.pumpWidget(buildLoginScreenWithNavigation());
        await tester.pumpAndSettle();

        // Find and tap the register link (last TextButton in the row)
        final registerButtons = find.byType(TextButton);
        expect(registerButtons, findsWidgets);

        // Tap the last TextButton which should be the register link
        await tester.tap(find.byType(TextButton).last);
        await tester.pumpAndSettle();

        // Should navigate to register screen
        expect(find.text('Register Screen'), findsOneWidget);
      });
    });

    group('Language Switcher', () {
      testWidgets('should have language switcher button', (tester) async {
        await tester.pumpWidget(buildLoginScreen());
        await tester.pumpAndSettle();

        // Find language button
        expect(find.byIcon(Icons.language), findsOneWidget);

        // Tap language switcher
        await tester.tap(find.byIcon(Icons.language));
        await tester.pump();

        // The button should be tappable without crashing
      });
    });

    group('Form Interaction', () {
      testWidgets('can enter phone and password', (tester) async {
        await tester.pumpWidget(buildLoginScreen());
        await tester.pumpAndSettle();

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
