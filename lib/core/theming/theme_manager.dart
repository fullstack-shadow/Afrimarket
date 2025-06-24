import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Centralized theme management service
///
/// Principles:
/// 1. Readability: Clear theme definitions and method names
/// 2. Modularity: Separate theme data and state management
/// 3. Testability: Mockable implementation
/// 4. Consistency: Enforced design system
class ThemeManager {
  final Ref _ref;
  ThemeMode _currentThemeMode = ThemeMode.system;

  ThemeManager(this._ref);

  /// Current theme mode
  ThemeMode get currentThemeMode => _currentThemeMode;

  /// Light theme configuration
  ThemeData get lightTheme => _buildTheme(Brightness.light);

  /// Dark theme configuration
  ThemeData get darkTheme => _buildTheme(Brightness.dark);

  /// Toggle between light/dark/system themes
  Future<void> toggleTheme(ThemeMode mode) async {
    _currentThemeMode = mode;
    await _ref.read(themePreferencesProvider).saveThemeMode(mode);
  }

  /// Initialize theme from preferences
  Future<void> initialize() async {
    _currentThemeMode = await _ref.read(themePreferencesProvider).getThemeMode();
  }

  /// Builds a ThemeData based on brightness
  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: brightness,
    );

    return baseTheme.copyWith(
      colorScheme: _colorScheme(brightness),
      textTheme: _textTheme(baseTheme.textTheme),
      appBarTheme: _appBarTheme(isDark),
      buttonTheme: _buttonTheme(),
      cardTheme: _cardTheme(),
      inputDecorationTheme: _inputDecorationTheme(),
      // Add other component themes as needed
    );
  }

  /// Color scheme definition
  ColorScheme _colorScheme(Brightness brightness) {
    return ColorScheme(
      brightness: brightness,
      primary: const Color(0xFF6200EE),
      primaryContainer: const Color(0xFF3700B3),
      secondary: const Color(0xFF03DAC6),
      secondaryContainer: const Color(0xFF018786),
      surface: brightness == Brightness.dark 
          ? const Color(0xFF121212) 
          : const Color(0xFFF5F5F5),
      error: const Color(0xFFB00020),
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onSurface: brightness == Brightness.dark 
          ? Colors.white 
          : Colors.black,
      onError: Colors.white,
    );
  }

  /// Text theme configuration
  TextTheme _textTheme(TextTheme base) {
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.bold,
      ),
      displayMedium: base.displayMedium?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
      // Add other text styles as needed
    );
  }

  /// AppBar theme configuration
  AppBarTheme _appBarTheme(bool isDark) {
    return AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: isDark 
          ? const Color(0xFF1E1E1E) 
          : const Color(0xFF6200EE),
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : Colors.white,
      ),
    );
  }

  /// Button theme configuration
  ButtonThemeData _buttonTheme() {
    return const ButtonThemeData(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  /// Card theme configuration
  CardThemeData _cardTheme() {
    return const CardThemeData(
      elevation: 2,
      margin: EdgeInsets.all(8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    );
  }

  /// Input decoration theme configuration
  InputDecorationTheme _inputDecorationTheme() {
    return const InputDecorationTheme(
      border: OutlineInputBorder(),
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
    );
  }
}

/// Provider for theme manager
final themeManagerProvider = Provider<ThemeManager>((ref) {
  return ThemeManager(ref);
});

/// Provider for theme mode state
final themeModeProvider = StateProvider<ThemeMode>((ref) {
  return ThemeMode.system;
});

/// Preferences provider for theme persistence
final themePreferencesProvider = Provider<ThemePreferences>((ref) {
  throw UnimplementedError('ThemePreferences provider must be overridden');
});

abstract class ThemePreferences {
  Future<void> saveThemeMode(ThemeMode mode);
  Future<ThemeMode> getThemeMode();
}

/// Mock implementation for testing
class MockThemeManager extends ThemeManager {
  MockThemeManager() : super(FakeRef());

  @override
  ThemeMode _currentThemeMode = ThemeMode.light;

  @override
  ThemeData get darkTheme => ThemeData.dark();

  @override
  ThemeData get lightTheme => ThemeData.light();

  @override
  Future<void> toggleTheme(ThemeMode mode) async {
    _currentThemeMode = mode;
  }

  @override
  Future<void> initialize() async {}

  @override
  ThemeData _buildTheme(Brightness brightness) => ThemeData();

  @override
  ColorScheme _colorScheme(Brightness brightness) => const ColorScheme.light();

  @override
  TextTheme _textTheme(TextTheme base) => base;

  @override
  AppBarTheme _appBarTheme(bool isDark) => const AppBarTheme();

  @override
  ButtonThemeData _buttonTheme() => const ButtonThemeData();

  @override
  CardThemeData _cardTheme() => const CardThemeData();

  @override
  InputDecorationTheme _inputDecorationTheme() => const InputDecorationTheme();
}

/// Fake Ref for MockThemeManager
class FakeRef implements Ref {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}