// lib/core/localization/localization_service.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Centralized localization service
///
/// Key fixes:
/// 1. Removed dependency on generated localization files
/// 2. Implemented manual localization system
/// 3. Fixed NumberFormat usage
/// 4. Added proper initialization
/// 5. Made supportedLocales constant
class LocalizationService {
  final Ref _ref;
  late Map<String, String> _localizations;
  Locale? _currentLocale;

  LocalizationService(this._ref) {
    // Initialize with default English translations
    _localizations = _enTranslations;
    _currentLocale = const Locale('en');
  }

  /// Current app locale
  Locale? get currentLocale => _currentLocale;

  /// Initialize localization service
  void initialize() {
    // In a real implementation, this would load saved locale preferences
    // For now, we'll just use the default
  }

  /// Get translated text by key
  String translate(String key, {Map<String, dynamic>? args}) {
    try {
      final translation = _localizations[key] ?? key;

      if (args != null) {
        return args.entries.fold(
          translation,
          (str, entry) => str.replaceAll('{${entry.key}}', entry.value.toString()),
        );
      }

      return translation;
    } catch (e) {
      return key; // Fallback to key
    }
  }

  /// Format date according to current locale
  String formatDate(DateTime date, {String? pattern}) {
    try {
      final locale = _currentLocale?.languageCode ?? 'en';
      if (pattern != null) {
        return DateFormat(pattern, locale).format(date);
      }
      return DateFormat.yMMMMd(locale).format(date);
    } catch (e) {
      return DateFormat.yMMMMd('en').format(date); // Fallback to English
    }
  }

  /// Format number according to current locale
  String formatNumber(num value, {int? decimalDigits}) {
    try {
      final locale = _currentLocale?.languageCode ?? 'en';
      final formatter = NumberFormat.decimalPattern(locale);
      if (decimalDigits != null) {
        formatter.minimumFractionDigits = decimalDigits;
        formatter.maximumFractionDigits = decimalDigits;
      }
      return formatter.format(value);
    } catch (e) {
      return value.toString(); // Fallback to basic toString
    }
  }

  /// Format currency according to current locale
  String formatCurrency(num value, {String? currencyCode}) {
    try {
      final locale = _currentLocale?.languageCode ?? 'en';
      return NumberFormat.currency(
        locale: locale,
        symbol: currencyCode,
        decimalDigits: 2,
      ).format(value);
    } catch (e) {
      return '${value.toStringAsFixed(2)} $currencyCode'; // Fallback
    }
  }

  /// Change app locale
  Future<void> setLocale(Locale locale) async {
    try {
      _currentLocale = locale;

      // Load translations for the new locale
      if (locale.languageCode == 'sw') {
        _localizations = _swTranslations;
      } else if (locale.languageCode == 'fr') {
        _localizations = _frTranslations;
      } else {
        _localizations = _enTranslations;
      }

      await _ref.read(localePreferencesProvider).saveLocale(locale);
    } catch (e) {
      debugPrint('Failed to change locale: $e');
    }
  }

  /// Supported locales
  static const List<Locale> supportedLocales = [
    Locale('en'), // English
    Locale('sw'), // Swahili
    Locale('fr'), // French
  ];

  // Manual translation dictionaries
  static const Map<String, String> _enTranslations = {
    'welcome': 'Welcome to AfriMarket!',
    'products': 'Products',
    'orders': 'Orders',
    'settings': 'Settings',
    'logout': 'Logout',
  };

  static const Map<String, String> _swTranslations = {
    'welcome': 'Karibu AfriMarket!',
    'products': 'Bidhaa',
    'orders': 'Maagizo',
    'settings': 'Mipangilio',
    'logout': 'Toka',
  };

  static const Map<String, String> _frTranslations = {
    'welcome': 'Bienvenue sur AfriMarket!',
    'products': 'Produits',
    'orders': 'Commandes',
    'settings': 'Paramètres',
    'logout': 'Se déconnecter',
  };
}

/// Provider for localization service
final localizationServiceProvider = Provider<LocalizationService>((ref) {
  final service = LocalizationService(ref);
  service.initialize();
  return service;
});

/// Preferences provider for locale persistence
final localePreferencesProvider = Provider<LocalePreferences>((ref) {
  return LocalePreferences();
});

class LocalePreferences {
  Future<void> saveLocale(Locale locale) async {
    // Implementation would save to SharedPreferences or similar
  }

  Future<Locale?> getSavedLocale() async {
    // Implementation would retrieve from storage
    return null;
  }
}

/// Extension for easy context access
extension LocalizationExtension on BuildContext {
  String translate(String key, {Map<String, dynamic>? args}) {
    final service = ProviderScope.containerOf(this).read(localizationServiceProvider);
    return service.translate(key, args: args);
  }
}

/// Mock implementation for testing
class MockLocalizationService extends LocalizationService {
  MockLocalizationService(Ref ref) : super(ref);

  @override
  Locale? get currentLocale => const Locale('en');

  @override
  String translate(String key, {Map<String, dynamic>? args}) => key;

  @override
  String formatDate(DateTime date, {String? pattern}) => 'formatted_date';

  @override
  String formatNumber(num value, {int? decimalDigits}) => value.toString();

  @override
  String formatCurrency(num value, {String? currencyCode}) => '$value $currencyCode';

  @override
  Future<void> setLocale(Locale locale) async {}

  @override
  void initialize() {}
}
