// test/e2e/dark_mode_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:my_flutter_app/main.dart' as app;
import 'package:my_flutter_app/core/theming/theme_manager.dart';

/// End-to-end tests for dark mode functionality across the entire application
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Dark Mode E2E Tests', () {
    testWidgets('Should toggle between light and dark mode successfully',
        (tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Verify initial light theme
      await _verifyThemeColors(tester, isDarkMode: false);

      // Open settings and toggle dark mode
      await _toggleDarkMode(tester);

      // Verify dark theme applied
      await _verifyThemeColors(tester, isDarkMode: true);

      // Toggle back to light mode
      await _toggleDarkMode(tester);

      // Verify light theme restored
      await _verifyThemeColors(tester, isDarkMode: false);
    });

    testWidgets('Should persist dark mode preference across app restarts',
        (tester) async {
      // First launch - enable dark mode
      app.main();
      await tester.pumpAndSettle();
      await _toggleDarkMode(tester);
      await _verifyThemeColors(tester, isDarkMode: true);

      // Simulate app restart
      tester.binding.window.clearLifecycleState();
      app.main();
      await tester.pumpAndSettle();

      // Verify dark mode persists
      await _verifyThemeColors(tester, isDarkMode: true);
    });
  });
}

/// Navigates to settings and toggles dark mode switch
Future<void> _toggleDarkMode(WidgetTester tester) async {
  // Open settings drawer
  await tester.tap(find.byTooltip('Open settings'));
  await tester.pumpAndSettle();

  // Find and toggle theme switch
  final themeSwitch = find.byKey(const Key('theme_switch'));
  await tester.tap(themeSwitch);
  await tester.pumpAndSettle();

  // Close settings drawer
  await tester.pageBack();
  await tester.pumpAndSettle();
}

/// Verifies the current theme matches expectations
Future<void> _verifyThemeColors(
  WidgetTester tester, {
  required bool isDarkMode,
}) async {
  final appBar = tester.widget<AppBar>(find.byType(AppBar));
  final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));

  if (isDarkMode) {
    expect(appBar.backgroundColor, Colors.grey[900]);
    expect(scaffold.backgroundColor, Colors.grey[850]);
  } else {
    expect(appBar.backgroundColor, Colors.blue);
    expect(scaffold.backgroundColor, Colors.white);
  }

  // Additional verification through ThemeManager
  final themeManager = tester.state<ThemeManager>(find.byType(ThemeManager));
  expect(themeManager.isDarkMode, isDarkMode);
}