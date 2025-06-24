// test/integration/onboarding_flow_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// Update the import path below if your main.dart is in a different location
import 'package:afrimarket/main.dart' as app;

/// Tests the complete user onboarding flow from initial launch to completion
void main() {
  group('Onboarding Flow Integration Tests', () {
    testWidgets('Should complete onboarding flow successfully', (tester) async {
      // Launch app
      app.main();
      await tester.pumpAndSettle();

      // Verify initial screen
      expect(find.text('Welcome to OurApp'), findsOneWidget);

      // Navigate through screens
      await _completeOnboardingSteps(tester);

      // Verify final state
      expect(find.byKey(const Key('homeScreen')), findsOneWidget);
    });

    testWidgets('Should persist onboarding completion', (tester) async {
      // First launch - complete onboarding
      app.main();
      await tester.pumpAndSettle();
      await _completeOnboardingSteps(tester);

      // Restart app
      tester.binding.window.clearLifecycleState();
      app.main();
      await tester.pumpAndSettle();

      // Verify skip onboarding
      expect(find.byKey(const Key('homeScreen')), findsOneWidget);
    });
  });
}

/// Helper to complete all onboarding steps
Future<void> _completeOnboardingSteps(WidgetTester tester) async {
  // Page 1
  await tester.tap(find.text('Continue'));
  await tester.pumpAndSettle();

  // Page 2
  await tester.enterText(find.byType(TextField), 'Test User');
  await tester.tap(find.text('Continue'));
  await tester.pumpAndSettle();

  // Page 3
  await tester.tap(find.byKey(const Key('acceptTermsCheckbox')));
  await tester.tap(find.text('Get Started'));
  await tester.pumpAndSettle();
}