import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'dart:async';

/// Centralized remote configuration service
///
/// Principles:
/// 1. Readability: Clear method names and documentation
/// 2. Safety: Type-safe config access
/// 3. Modularity: Separate fetching from value access
/// 4. Testability: Mockable implementation
abstract class RemoteConfigService {
  /// Fetches and activates the latest config values
  Future<void> fetchAndActivate();

  /// Gets a string value with fallback
  String getString(String key, {String fallback = ''});

  /// Gets a boolean value with fallback
  bool getBool(String key, {bool fallback = false});

  /// Gets an integer value with fallback
  int getInt(String key, {int fallback = 0});

  /// Gets a double value with fallback
  double getDouble(String key, {double fallback = 0.0});

  /// Gets all parameters as a map
  Map<String, dynamic> getAll();

  /// Stream of config updates
  Stream<Map<String, dynamic>> get configUpdates;
}

/// Firebase implementation of RemoteConfigService
class FirebaseRemoteConfigService implements RemoteConfigService {
  final FirebaseRemoteConfig _remoteConfig;
  final _controller = StreamController<Map<String, dynamic>>.broadcast();
  final Duration _fetchTimeout;
  final Duration _minimumFetchInterval;

  FirebaseRemoteConfigService({
    required Duration fetchTimeout,
    required Duration minimumFetchInterval,
    FirebaseRemoteConfig? remoteConfig,
  })  : _fetchTimeout = fetchTimeout,
        _minimumFetchInterval = minimumFetchInterval,
        _remoteConfig = remoteConfig ?? FirebaseRemoteConfig.instance {
    _init();
  }

  Future<void> _init() async {
    await _remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: _fetchTimeout,
      minimumFetchInterval: _minimumFetchInterval,
    ));

    // Set defaults
    await _remoteConfig.setDefaults(_defaultConfigs);
  }

  @override
  Future<void> fetchAndActivate() async {
    try {
      await _remoteConfig.fetchAndActivate();
      _controller.add(_getAllValues());
    } catch (e) {
      debugPrint('Failed to fetch remote config: $e');
      rethrow;
    }
  }

  @override
  String getString(String key, {String fallback = ''}) {
    try {
      return _remoteConfig.getString(key);
    } catch (e) {
      debugPrint('Failed to get string for key $key: $e');
      return fallback;
    }
  }

  @override
  bool getBool(String key, {bool fallback = false}) {
    try {
      return _remoteConfig.getBool(key);
    } catch (e) {
      debugPrint('Failed to get bool for key $key: $e');
      return fallback;
    }
  }

  @override
  int getInt(String key, {int fallback = 0}) {
    try {
      return _remoteConfig.getInt(key);
    } catch (e) {
      debugPrint('Failed to get int for key $key: $e');
      return fallback;
    }
  }

  @override
  double getDouble(String key, {double fallback = 0.0}) {
    try {
      return _remoteConfig.getDouble(key);
    } catch (e) {
      debugPrint('Failed to get double for key $key: $e');
      return fallback;
    }
  }

  @override
  Map<String, dynamic> getAll() {
    return _getAllValues();
  }

  @override
  Stream<Map<String, dynamic>> get configUpdates => _controller.stream;

  Map<String, dynamic> _getAllValues() {
    return {
      for (final key in _remoteConfig.getAll().keys)
        key: _remoteConfig.getValue(key).asString(),
    };
  }

  /// Default configuration values
  static final _defaultConfigs = <String, dynamic>{
    'feature_chat_enabled': false,
    'feature_payments_enabled': true,
    'maintenance_mode': false,
    'app_version_required': '1.0.0',
    'special_offer_text': '',
  };
}

/// Provider for remote config service
final remoteConfigServiceProvider = Provider<RemoteConfigService>((ref) {
  return FirebaseRemoteConfigService(
    fetchTimeout: const Duration(seconds: 10),
    minimumFetchInterval: const Duration(minutes: 5),
  );
});

/// Mock implementation for testing
class MockRemoteConfigService implements RemoteConfigService {
  final Map<String, dynamic> _values = {};

  @override
  Future<void> fetchAndActivate() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 100));
  }

  @override
  String getString(String key, {String fallback = ''}) {
    return _values[key]?.toString() ?? fallback;
  }

  @override
  bool getBool(String key, {bool fallback = false}) {
    return _values[key] as bool? ?? fallback;
  }

  @override
  int getInt(String key, {int fallback = 0}) {
    return _values[key] as int? ?? fallback;
  }

  @override
  double getDouble(String key, {double fallback = 0.0}) {
    return _values[key] as double? ?? fallback;
  }

  @override
  Map<String, dynamic> getAll() {
    return Map.unmodifiable(_values);
  }

  @override
  Stream<Map<String, dynamic>> get configUpdates => Stream.empty();

  /// Test method to set mock values
  void setMockValues(Map<String, dynamic> values) {
    _values.clear();
    _values.addAll(values);
  }
}

/// Extension for easy config access
extension RemoteConfigExtension on WidgetRef {
  /// Gets a remote config value with type inference
  T config<T>(String key, {required T fallback}) {
    final service = read(remoteConfigServiceProvider);
    
    return switch (T) {
      const (String) => service.getString(key, fallback: fallback as String) as T,
      const (bool) => service.getBool(key, fallback: fallback as bool) as T,
      const (int) => service.getInt(key, fallback: fallback as int) as T,
      const (double) => service.getDouble(key, fallback: fallback as double) as T,
      _ => throw ArgumentError('Unsupported config type: $T'),
    };
  }
}