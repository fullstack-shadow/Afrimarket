// test/golden/login_screen_golden.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_flutter_app/features/auth/presentation/screens/login_screen.dart';

/// Golden tests for the LoginScreen visual appearance
void main() {
  group('LoginScreen Golden Tests', () {
    testWidgets('Renders default state correctly', (tester) async {
      await _pumpLoginScreen(tester);
      await expectLater(
        find.byType(LoginScreen),
        matchesGoldenFile('goldens/login_screen_default.png'),
      );
    });

    testWidgets('Renders email input state correctly', (tester) async {
      await _pumpLoginScreen(tester);
      await _enterText(tester, 'email', 'test@example.com');
      await expectLater(
        find.byType(LoginScreen),
        matchesGoldenFile('goldens/login_screen_email_entered.png'),
      );
    });

    testWidgets('Renders password input state correctly', (tester) async {
      await _pumpLoginScreen(tester);
      await _enterText(tester, 'password', 'securepassword123');
      await expectLater(
        find.byType(LoginScreen),
        matchesGoldenFile('goldens/login_screen_password_entered.png'),
      );
    });

    testWidgets('Renders loading state correctly', (tester) async {
      await _pumpLoginScreen(tester, isLoading: true);
      await expectLater(
        find.byType(LoginScreen),
        matchesGoldenFile('goldens/login_screen_loading.png'),
      );
    });

    testWidgets('Renders error state correctly', (tester) async {
      await _pumpLoginScreen(tester, errorMessage: 'Invalid credentials');
      await expectLater(
        find.byType(LoginScreen),
        matchesGoldenFile('goldens/login_screen_error.png'),
      );
    });

    testWidgets('Renders dark mode correctly', (tester) async {
      await _pumpLoginScreen(tester, darkMode: true);
      await expectLater(
        find.byType(LoginScreen),
        matchesGoldenFile('goldens/login_screen_dark_mode.png'),
      );
    });
  });
}

/// Helper to render the LoginScreen with specified parameters
Future<void> _pumpLoginScreen(
  WidgetTester tester, {
  bool isLoading = false,
  String? errorMessage,
  bool darkMode = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: darkMode ? ThemeData.dark() : ThemeData.light(),
      home: Scaffold(
        body: LoginScreen(
          isLoading: isLoading,
          errorMessage: errorMessage,
          onLogin: (_, __) {},
          onNavigateToSignUp: () {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Helper to enter text into a field
Future<void> _enterText(
  WidgetTester tester,
  String key,
  String text,
) async {
  await tester.enterText(find.byKey(Key('${key}_field')), text);
  await tester.pump();
}