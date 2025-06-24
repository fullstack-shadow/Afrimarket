import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Centralized service for application analytics tracking
///
/// Follows strict readability and maintainability principles:
/// - Clear documentation for all public interfaces
/// - Single responsibility for each method
/// - Consistent parameter naming
/// - Testable architecture
abstract class AnalyticsService {
  /// Tracks a custom event with specified parameters
  ///
  /// [eventName] should be in snake_case format (e.g., 'product_viewed')
  /// [parameters] should be a flat map of key-value pairs (max 25 items)
  void logEvent({
    required String eventName,
    Map<String, dynamic>? parameters,
  });

  /// Tracks screen views with consistent naming convention
  ///
  /// [screenName] should follow UpperCamelCase format (e.g., 'ProductDetailScreen')
  void logScreenView({required String screenName});

  /// Tracks user sign-ups and authentication events
  ///
  /// [method] indicates authentication method (e.g., 'email', 'google', 'facebook')
  void logSignUp({required String method});

  /// Tracks e-commerce purchase events
  ///
  /// [value] is the transaction value in USD
  /// [currency] should be ISO 4217 format (e.g., 'USD', 'KES')
  /// [items] list of purchased products (max 10 items)
  void logPurchase({
    required double value,
    String currency = 'USD',
    List<AnalyticsItem>? items,
  });

  /// Sets user properties for segmentation
  ///
  /// [properties] should be predefined set of attributes
  void setUserProperties({required AnalyticsUserProperties properties});
}

/// Data model for analytics items in purchase events
@immutable
class AnalyticsItem {
  final String id;
  final String name;
  final String category;
  final double price;
  final int quantity;

  const AnalyticsItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    this.quantity = 1,
  });

  /// Converts to a map suitable for analytics platforms
  Map<String, dynamic> toMap() {
    return {
      'item_id': id,
      'item_name': name,
      'item_category': category,
      'price': price,
      'quantity': quantity,
    };
  }
}

/// User properties for analytics segmentation
@immutable
class AnalyticsUserProperties {
  final String? userId;
  final String userType; // 'buyer' or 'seller'
  final String signupMethod;
  final String? countryCode;
  final String appVersion;

  const AnalyticsUserProperties({
    this.userId,
    required this.userType,
    required this.signupMethod,
    this.countryCode,
    required this.appVersion,
  });

  /// Converts to a map suitable for analytics platforms
  Map<String, dynamic> toMap() {
    return {
      if (userId != null) 'user_id': userId,
      'user_type': userType,
      'signup_method': signupMethod,
      if (countryCode != null) 'country_code': countryCode,
      'app_version': appVersion,
    };
  }
}

/// Firebase implementation of AnalyticsService
class FirebaseAnalyticsService implements AnalyticsService {
  final FirebaseAnalytics _firebaseAnalytics;

  FirebaseAnalyticsService({FirebaseAnalytics? analytics})
      : _firebaseAnalytics = analytics ?? FirebaseAnalytics.instance;

  @override
  void logEvent({
    required String eventName,
    Map<String, dynamic>? parameters,
  }) {
    // Validate event name format
    if (!_isValidEventName(eventName)) {
      throw ArgumentError(
        'Event name must be snake_case and contain only alphanumeric characters and underscores',
      );
    }

    // Enforce parameter limits
    if (parameters != null && parameters.length > 25) {
      throw ArgumentError('Analytics events cannot exceed 25 parameters');
    }

    // Log to Firebase
    _firebaseAnalytics.logEvent(
      name: eventName,
      parameters: parameters,
    );
  }

  @override
  void logScreenView({required String screenName}) {
    if (!_isValidScreenName(screenName)) {
      throw ArgumentError(
        'Screen name must be UpperCamelCase and contain only alphanumeric characters',
      );
    }

    _firebaseAnalytics.logEvent(
      name: 'screen_view',
      parameters: {
        'screen_name': screenName,
      },
    );
  }

  @override
  void logSignUp({required String method}) {
    _firebaseAnalytics.logEvent(
      name: 'sign_up',
      parameters: {
        'method': method,
      },
    );
  }

  @override
  void logPurchase({
    required double value,
    String currency = 'USD',
    List<AnalyticsItem>? items,
  }) {
    if (items != null && items.length > 10) {
      throw ArgumentError('Purchase events cannot track more than 10 items');
    }

    // Convert items to the format expected by Firebase
    final List<Map<String, dynamic>>? itemList = items?.map((item) => item.toMap()).toList();

    _firebaseAnalytics.logEvent(
      name: 'purchase',
      parameters: {
        'currency': currency,
        'value': value,
        'items': itemList,
      },
    );
  }

  @override
  void setUserProperties({required AnalyticsUserProperties properties}) {
    final propertiesMap = properties.toMap();

    // Set each property individually
    propertiesMap.forEach((key, value) {
      if (value != null) {
        _firebaseAnalytics.setUserProperty(name: key, value: value.toString());
      }
    });
  }

  /// Validates event name format (snake_case)
  bool _isValidEventName(String name) {
    return RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(name);
  }

  /// Validates screen name format (UpperCamelCase)
  bool _isValidScreenName(String name) {
    return RegExp(r'^[A-Z][a-zA-Z0-9]*$').hasMatch(name);
  }
}

/// Mock implementation for testing
class MockAnalyticsService implements AnalyticsService {
  final List<Map<String, dynamic>> loggedEvents = [];

  @override
  void logEvent({required String eventName, Map<String, dynamic>? parameters}) {
    loggedEvents.add({
      'event': eventName,
      'params': parameters ?? {},
    });
  }

  @override
  void logScreenView({required String screenName}) {
    loggedEvents.add({'screen_view': screenName});
  }

  @override
  void logSignUp({required String method}) {
    loggedEvents.add({'sign_up': method});
  }

  @override
  void logPurchase({
    required double value,
    String currency = 'USD',
    List<AnalyticsItem>? items,
  }) {
    loggedEvents.add({
      'purchase': value,
      'currency': currency,
      'items': items?.map((e) => e.toMap()).toList(),
    });
  }

  @override
  void setUserProperties({required AnalyticsUserProperties properties}) {
    loggedEvents.add({'user_properties': properties.toMap()});
  }
}

/// Provider for analytics service
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  // Use mock in test environment, real service otherwise
  if (kDebugMode && const bool.fromEnvironment('TEST_MODE', defaultValue: false)) {
    return MockAnalyticsService();
  }
  return FirebaseAnalyticsService();
});