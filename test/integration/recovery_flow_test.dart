// test/integration/recovery_flow_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_flutter_app/main.dart' as app;
import 'package:mockito/annotations.dart';

/// Tests the complete account recovery flow
@GenerateMocks([AuthRepository])
void main() {
  group('Account Recovery Integration Tests', () {
    testWidgets('Should complete password reset flow successfully', (tester) async {
      // Launch app
      app.main();
      await tester.pumpAndSettle();

      // Navigate to recovery
      await _initiateRecoveryFlow(tester);

      // Verify email sent
      expect(find.text('Reset Email Sent'), findsOneWidget);
    });

    testWidgets('Should handle invalid email gracefully', (tester) async {
      // Launch app
      app.main();
      await tester.pumpAndSettle();

      // Attempt recovery with invalid email
      await _initiateRecoveryFlow(tester, email: 'invalid-email');

      // Verify error handling
      expect(find.text('Please enter a valid email'), findsOneWidget);
    });
  });
}

/// Helper to initiate recovery flow
Future<void> _initiateRecoveryFlow(
  WidgetTester tester, {
  String email = 'test@example.com',
}) async {
  // Go to login
  await tester.tap(find.text('Sign In'));
  await tester.pumpAndSettle();

  // Navigate to recovery
  await tester.tap(find.text('Forgot Password?'));
  await tester.pumpAndSettle();

  // Enter email
  await tester.enterText(find.byKey(const Key('recoveryEmailField')), email);
  await tester.tap(find.text('Send Reset Link'));
  await tester.pumpAndSettle();
}