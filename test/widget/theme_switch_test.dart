// test/widget/theme_switch_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_flutter_app/core/theming/theme_manager.dart';
import 'package:my_flutter_app/widgets/shared/theme_switch.dart';
import 'package:provider/provider.dart';

/// Tests for the [ThemeSwitch] widget that allows users to toggle between light/dark themes
void main() {
  late ThemeManager themeManager;
  late Widget testWidget;

  /// Sets up fresh dependencies and test widget before each test
  setUp(() {
    themeManager = _MockThemeManager();
    testWidget = _buildTestWidget(themeManager);
  });

  group('ThemeSwitch Widget Tests', () {
    testWidgets('Should display moon icon when in light mode', (tester) async {
      // Setup
      when(themeManager.isDarkMode).thenReturn(false);

      // Execute
      await tester.pumpWidget(testWidget);

      // Verify
      expect(find.byIcon(Icons.dark_mode), findsOneWidget);
      expect(find.byIcon(Icons.light_mode), findsNothing);
    });

    testWidgets('Should display sun icon when in dark mode', (tester) async {
      // Setup
      when(themeManager.isDarkMode).thenReturn(true);

      // Execute
      await tester.pumpWidget(testWidget);

      // Verify
      expect(find.byIcon(Icons.light_mode), findsOneWidget);
      expect(find.byIcon(Icons.dark_mode), findsNothing);
    });

    testWidgets('Should call toggleTheme when user taps the switch', (tester) async {
      // Setup
      when(themeManager.isDarkMode).thenReturn(false);
      when(themeManager.toggleTheme()).thenAnswer((_) async {});

      // Execute
      await tester.pumpWidget(testWidget);
      await tester.tap(find.byType(ThemeSwitch));
      await tester.pump();

      // Verify
      verify(themeManager.toggleTheme()).called(1);
    });

    testWidgets('Should provide proper accessibility semantics', (tester) async {
      // Setup
      when(themeManager.isDarkMode).thenReturn(false);

      // Execute
      await tester.pumpWidget(testWidget);

      // Verify
      final semantics = tester.getSemantics(find.byType(ThemeSwitch));
      expect(semantics.properties.label, 'Toggle theme');
      expect(semantics.properties.tooltip, 'Switch between light and dark mode');
    });
  });
}

/// Builds the test widget with proper provider setup
Widget _buildTestWidget(ThemeManager manager) {
  return MaterialApp(
    home: ChangeNotifierProvider<ThemeManager>.value(
      value: manager,
      child: const Scaffold(
        body: ThemeSwitch(),
      ),
    ),
  );
}

/// Mock implementation of [ThemeManager] for testing
class _MockThemeManager extends Mock implements ThemeManager {}