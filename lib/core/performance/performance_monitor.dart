// performance_monitor.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_performance/firebase_performance.dart';

/// Centralized performance monitoring service
///
/// Principles:
/// 1. Readability: Clear metric names and documentation
/// 2. Modularity: Separate tracking and analysis concerns
/// 3. Testability: Mockable implementation
/// 4. Safety: Threshold validation and error handling
abstract class PerformanceMonitor {
  /// Tracks app startup time
  void trackAppStartup(Duration duration);

  /// Tracks screen rendering time
  void trackScreenRender(String screenName, Duration duration);

  /// Tracks network request duration
  void trackNetworkRequest(String endpoint, Duration duration);

  /// Tracks heavy computation tasks
  void trackComputation(String taskName, Duration duration);

  /// Records memory usage snapshot
  void recordMemoryUsage(int bytes);

  /// Checks if current performance meets thresholds
  PerformanceHealthCheck get healthCheck;

  /// Stream of performance events for real-time monitoring
  Stream<PerformanceEvent> get performanceEvents;
}

/// Performance health status
class PerformanceHealthCheck {
  final bool isHealthy;
  final List<PerformanceIssue> issues;

  const PerformanceHealthCheck({
    required this.isHealthy,
    this.issues = const <PerformanceIssue>[],
  });
}

/// Identified performance issue
class PerformanceIssue {
  final String metric;
  final String description;
  final dynamic measuredValue;
  final dynamic threshold;

  const PerformanceIssue({
    required this.metric,
    required this.description,
    required this.measuredValue,
    required this.threshold,
  });

  @override
  String toString() => '$metric exceeded threshold: $measuredValue > $threshold ($description)';
}

/// Performance event types
class PerformanceEvent {
  final String name;
  final String? category;
  final Duration duration;
  final int? memoryBytes;
  final DateTime timestamp;

  PerformanceEvent({
    required this.name,
    this.category,
    required this.duration,
    this.memoryBytes,
  }) : timestamp = DateTime.now();
}

/// Firebase implementation of PerformanceMonitor
class FirebasePerformanceMonitor implements PerformanceMonitor {
  final FirebasePerformance _firebasePerformance;
  final PerformanceThresholds _thresholds;
  final _controller = StreamController<PerformanceEvent>.broadcast();

  FirebasePerformanceMonitor({
    required PerformanceThresholds thresholds,
    FirebasePerformance? performance,
  })  : _thresholds = thresholds,
        _firebasePerformance = performance ?? FirebasePerformance.instance {
    // Enable automatic data collection (optional)
    _firebasePerformance.setPerformanceCollectionEnabled(true);
  }

  @override
  void trackAppStartup(Duration duration) {
    _logToFirebase('app_startup', duration);
    _checkThreshold('app_startup', duration);
  }

  @override
  void trackScreenRender(String screenName, Duration duration) {
    _logToFirebase('screen_render_$screenName', duration);
    _checkThreshold('screen_render', duration, extra: {'screen': screenName});
  }

  @override
  void trackNetworkRequest(String endpoint, Duration duration) {
    _logToFirebase('network_$endpoint', duration);
    _checkThreshold('network_request', duration, extra: {'endpoint': endpoint});
  }

  @override
  void trackComputation(String taskName, Duration duration) {
    _logToFirebase('compute_$taskName', duration);
    _checkThreshold('computation', duration, extra: {'task': taskName});
  }

  @override
  void recordMemoryUsage(int bytes) {
    _controller.add(PerformanceEvent(
      name: 'memory_usage',
      duration: Duration.zero,
      memoryBytes: bytes,
    ));
    _checkThreshold('memory_usage', bytes);
  }

  @override
  PerformanceHealthCheck get healthCheck {
    // Implement actual threshold checks
    return PerformanceHealthCheck(isHealthy: true);
  }

  @override
  Stream<PerformanceEvent> get performanceEvents => _controller.stream;

  void _logToFirebase(String name, Duration duration, {String? screenName}) {
    try {
      final trace = _firebasePerformance.newTrace(name);
      trace.start();
      trace.setMetric('duration_ms', duration.inMilliseconds);
      if (screenName != null) {
        trace.putAttribute('screen', screenName);
      }
      trace.stop();
      
      // Also log to our internal stream
      _controller.add(PerformanceEvent(
        name: name,
        category: screenName,
        duration: duration,
      ));
    } catch (e) {
      debugPrint('Failed to log performance metric: $e');
    }
  }

  void _checkThreshold(
    String metric,
    dynamic value, {
    Map<String, dynamic>? extra,
  }) {
    final threshold = _thresholds.getThreshold(metric);
    if (threshold != null && value > threshold) {
      _controller.add(PerformanceEvent(
        name: 'threshold_exceeded',
        category: 'alert',
        duration: Duration.zero,
      ));
    }
  }
}

/// Mock implementation for testing
class MockPerformanceMonitor implements PerformanceMonitor {
  final List<PerformanceEvent> _events = [];
  final _controller = StreamController<PerformanceEvent>.broadcast();

  @override
  void trackAppStartup(Duration duration) {
    _addEvent('app_startup', duration);
  }

  @override
  void trackScreenRender(String screenName, Duration duration) {
    _addEvent('screen_render_$screenName', duration);
  }

  @override
  void trackNetworkRequest(String endpoint, Duration duration) {
    _addEvent('network_$endpoint', duration);
  }

  @override
  void trackComputation(String taskName, Duration duration) {
    _addEvent('compute_$taskName', duration);
  }

  @override
  void recordMemoryUsage(int bytes) {
    _addEvent('memory_usage', Duration.zero, memoryBytes: bytes);
  }

  @override
  PerformanceHealthCheck get healthCheck => PerformanceHealthCheck(
        isHealthy: _events.isEmpty,
        issues: [],
      );

  @override
  Stream<PerformanceEvent> get performanceEvents => _controller.stream;

  void _addEvent(String name, Duration duration, {int? memoryBytes}) {
    final event = PerformanceEvent(
      name: name,
      duration: duration,
      memoryBytes: memoryBytes,
    );
    _events.add(event);
    _controller.add(event);
  }
}

/// Provider for performance monitoring
final performanceMonitorProvider = Provider<PerformanceMonitor>((ref) {
  if (kDebugMode && const bool.fromEnvironment('TEST_MODE')) {
    return MockPerformanceMonitor();
  }
  return FirebasePerformanceMonitor(
    thresholds: ref.read(performanceThresholdsProvider),
  );
});

/// Stub for PerformanceThresholds class
class PerformanceThresholds {
  final Map<String, dynamic> _thresholds;
  PerformanceThresholds(this._thresholds);

  dynamic getThreshold(String metric) => _thresholds[metric];
}

/// Stub provider for PerformanceThresholds
final performanceThresholdsProvider = Provider<PerformanceThresholds>((ref) {
  // Example thresholds, adjust as needed
  return PerformanceThresholds({
    'app_startup': Duration(seconds: 2),
    'screen_render': Duration(milliseconds: 500),
    'network_request': Duration(seconds: 5),
    'computation': Duration(seconds: 1),
    'memory_usage': 100000000, // 100 MB
  });
});
