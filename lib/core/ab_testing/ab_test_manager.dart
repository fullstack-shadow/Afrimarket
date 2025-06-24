import 'package:firebase_core/firebase_core.dart' show FirebaseException;
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Helper method to convert string to enum
T? _enumFromString<T extends Enum>(String key, List<T> values) {
  try {
    return values.firstWhere(
      (v) => v.toString().split('.').last == key,
    );
  } catch (_) {
    return null;
  }
}

/// Centralized service for managing A/B testing experiments
///
/// Principles applied:
/// 1. Readability: Clear method names and documentation
/// 2. Modularity: Single responsibility for experiment management
/// 3. Consistency: Type-safe experiment definitions
/// 4. Testability: Mockable implementation
/// 5. DRY: Reusable experiment evaluation logic
abstract class ABTestManager {
  /// Initializes the A/B testing service
  Future<void> initialize();

  /// Gets the assigned variant for an experiment
  ///
  /// Returns the default variant if:
  /// - Experiment is not found
  /// - User is not in the experiment cohort
  /// - Experiment is completed
  T getVariant<T extends Enum>(ABExperiment<T> experiment);

  /// Forces a specific variant for testing purposes
  @visibleForTesting
  void setOverrideVariant<T extends Enum>(ABExperiment<T> experiment, T variant);
}

/// Represents an A/B testing experiment configuration
class ABExperiment<T extends Enum> {
  final String name;
  final Map<T, int> variantWeights;
  final T defaultVariant;
  final DateTime? startDate;
  final DateTime? endDate;

  const ABExperiment({
    required this.name,
    required this.variantWeights,
    required this.defaultVariant,
    this.startDate,
    this.endDate,
  });

  /// Validates experiment configuration
  bool get isValid {
    final totalWeight = variantWeights.values.reduce((a, b) => a + b);
    return totalWeight == 100;
  }
}

/// Firebase implementation using Remote Config
class FirebaseABTestManager implements ABTestManager {
  final FirebaseRemoteConfig _remoteConfig;
  final _variantOverrides = <String, Enum>{};

  FirebaseABTestManager({FirebaseRemoteConfig? remoteConfig})
      : _remoteConfig = remoteConfig ?? FirebaseRemoteConfig.instance;

  @override
  Future<void> initialize() async {
    try {
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(minutes: 5),
      ));

      await _remoteConfig.fetchAndActivate();
    } on FirebaseException catch (e) {
      throw ABTestException('Failed to initialize A/B testing: ${e.message}');
    } catch (e) {
      throw ABTestException('Failed to initialize A/B testing: $e');
    }
  }

  @override
  T getVariant<T extends Enum>(ABExperiment<T> experiment) {
    // 1. Check for test overrides
    if (_variantOverrides.containsKey(experiment.name)) {
      return _variantOverrides[experiment.name] as T;
    }

    // 2. Validate experiment configuration
    if (!experiment.isValid) {
      return experiment.defaultVariant;
    }

    // 3. Check experiment availability
    if (!_isExperimentActive(experiment)) {
      return experiment.defaultVariant;
    }

    // 4. Get assigned variant from remote config
    final variantValue = _remoteConfig.getString(experiment.name);

    try {
      return enumFromString<T>(variantValue, experiment.variantWeights.keys.toList()) ?? experiment.defaultVariant;
    } catch (e) {
      return experiment.defaultVariant;
    }
  }

  @override
  void setOverrideVariant<T extends Enum>(ABExperiment<T> experiment, T variant) {
    _variantOverrides[experiment.name] = variant;
  }

  /// Checks if experiment is currently active
  bool _isExperimentActive<T extends Enum>(ABExperiment<T> experiment) {
    final now = DateTime.now();
    final hasStarted = experiment.startDate == null || now.isAfter(experiment.startDate!);
    final hasEnded = experiment.endDate != null && now.isAfter(experiment.endDate!);

    return hasStarted && !hasEnded;
  }

  /// Converts string value to enum
  T? enumFromString<T extends Enum>(String value, List<T> values) {
    return values.firstWhereOrNull(
      (enumItem) => enumItem.name == value,
    );
  }
}

/// Mock implementation for testing
class MockABTestManager implements ABTestManager {
  final Map<String, Enum> _variants = {};

  @override
  Future<void> initialize() async => Future.value();

  @override
  T getVariant<T extends Enum>(ABExperiment<T> experiment) {
    return (_variants[experiment.name] as T?) ?? experiment.defaultVariant;
  }

  @override
  void setOverrideVariant<T extends Enum>(ABExperiment<T> experiment, T variant) {
    _variants[experiment.name] = variant;
  }
}

/// Provider for ABTestManager
final abTestManagerProvider = Provider<ABTestManager>((ref) {
  // Use mock in test environment
  if (kDebugMode && const bool.fromEnvironment('TEST_MODE', defaultValue: false)) {
    return MockABTestManager();
  }
  return FirebaseABTestManager();
});

/// Custom exceptions
class ABTestException implements Exception {
  final String message;
  ABTestException(this.message);

  @override
  String toString() => 'ABTestException: $message';
}

/// Extension for nullable enum lookup
extension EnumListExtension<T extends Enum> on List<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final item in this) {
      if (test(item)) return item;
    }
    return null;
  }
}
