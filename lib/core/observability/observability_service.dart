import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

/// Centralized observability service for monitoring application health
///
/// Principles:
/// 1. Readability: Clear metric names and documentation
/// 2. Modularity: Separate logging, metrics, and tracing concerns
/// 3. Testability: Mockable implementation
/// 4. Safety: Error boundaries and fallbacks
abstract class ObservabilityService {
  /// Logs an application event
  void logEvent(String eventName, {Map<String, dynamic>? attributes});

  /// Records a performance metric
  void recordMetric(String metricName, double value, {Map<String, dynamic>? tags});

  /// Starts a distributed trace
  ObservabilitySpan startTrace(String operationName, {Map<String, dynamic>? context});

  /// Sets a global context attribute
  void setContextAttribute(String key, dynamic value);

  /// Reports an error
  void reportError(dynamic error, StackTrace stackTrace, {String? context});
}

/// Represents a distributed tracing span
abstract class ObservabilitySpan {
  /// Adds metadata to the span
  void setAttribute(String key, dynamic value);

  /// Records an exception
  void recordError(dynamic error, StackTrace stackTrace);

  /// Ends the span
  void end();
}

/// Composite implementation using multiple observability tools
class CompositeObservabilityService implements ObservabilityService {
  final List<ObservabilityService> _services;
  final Map<String, dynamic> _globalContext = {};

  CompositeObservabilityService(this._services);

  @override
  void logEvent(String eventName, {Map<String, dynamic>? attributes}) {
    final combinedAttributes = {..._globalContext, ...?attributes};
    
    for (final service in _services) {
      try {
        service.logEvent(eventName, attributes: combinedAttributes);
      } catch (e) {
        debugPrint('Failed to log event: $e');
      }
    }
  }

  @override
  void recordMetric(String metricName, double value, {Map<String, dynamic>? tags}) {
    final combinedTags = {..._globalContext, ...?tags};
    
    for (final service in _services) {
      try {
        service.recordMetric(metricName, value, tags: combinedTags);
      } catch (e) {
        debugPrint('Failed to record metric: $e');
      }
    }
  }

  @override
  ObservabilitySpan startTrace(String operationName, {Map<String, dynamic>? context}) {
    final combinedContext = {..._globalContext, ...?context};
    final spans = _services.map((service) {
      try {
        return service.startTrace(operationName, context: combinedContext);
      } catch (e) {
        debugPrint('Failed to start trace: $e');
        return _NoOpSpan();
      }
    }).toList();

    return _CompositeSpan(spans);
  }

  @override
  void setContextAttribute(String key, dynamic value) {
    _globalContext[key] = value;
    for (final service in _services) {
      try {
        service.setContextAttribute(key, value);
      } catch (e) {
        debugPrint('Failed to set context attribute: $e');
      }
    }
  }

  @override
  void reportError(dynamic error, StackTrace stackTrace, {String? context}) {
    final errorContext = {
      ..._globalContext,
      if (context != null) 'error_context': context,
    };
    
    for (final service in _services) {
      try {
        service.reportError(error, stackTrace, context: context);
      } catch (e) {
        debugPrint('Failed to report error: $e');
      }
    }
  }
}

/// Composite span that manages multiple child spans
class _CompositeSpan implements ObservabilitySpan {
  final List<ObservabilitySpan> _spans;

  _CompositeSpan(this._spans);

  @override
  void setAttribute(String key, dynamic value) {
    for (final span in _spans) {
      try {
        span.setAttribute(key, value);
      } catch (e) {
        debugPrint('Failed to set span attribute: $e');
      }
    }
  }

  @override
  void recordError(dynamic error, StackTrace stackTrace) {
    for (final span in _spans) {
      try {
        span.recordError(error, stackTrace);
      } catch (e) {
        debugPrint('Failed to record span error: $e');
      }
    }
  }

  @override
  void end() {
    for (final span in _spans) {
      try {
        span.end();
      } catch (e) {
        debugPrint('Failed to end span: $e');
      }
    }
  }
}

/// No-op span for fallback scenarios
class _NoOpSpan implements ObservabilitySpan {
  @override
  void setAttribute(String key, dynamic value) {}

  @override
  void recordError(dynamic error, StackTrace stackTrace) {}

  @override
  void end() {}
}

/// Firebase implementation for Crashlytics and Performance Monitoring
class FirebaseObservabilityService implements ObservabilityService {
  @override
  void logEvent(String eventName, {Map<String, dynamic>? attributes}) {
    // Implementation using Firebase Analytics
    debugPrint('Firebase Event: $eventName - $attributes');
  }

  @override
  void recordMetric(String metricName, double value, {Map<String, dynamic>? tags}) {
    // Implementation using Firebase Performance Monitoring
    debugPrint('Firebase Metric: $metricName = $value - $tags');
  }

  @override
  ObservabilitySpan startTrace(String operationName, {Map<String, dynamic>? context}) {
    // Implementation using Firebase Performance Monitoring
    debugPrint('Firebase Trace Start: $operationName - $context');
    return _FirebaseSpan(operationName);
  }

  @override
  void setContextAttribute(String key, dynamic value) {
    // Implementation using Firebase Crashlytics
    debugPrint('Firebase Context: $key = $value');
  }

  @override
  void reportError(dynamic error, StackTrace stackTrace, {String? context}) {
    // Implementation using Firebase Crashlytics
    debugPrint('Firebase Error: $error - $stackTrace - $context');
  }
}

class _FirebaseSpan implements ObservabilitySpan {
  final String _operationName;

  _FirebaseSpan(this._operationName);

  @override
  void setAttribute(String key, dynamic value) {
    debugPrint('Firebase Span Attribute: $_operationName - $key = $value');
  }

  @override
  void recordError(dynamic error, StackTrace stackTrace) {
    debugPrint('Firebase Span Error: $_operationName - $error - $stackTrace');
  }

  @override
  void end() {
    debugPrint('Firebase Span End: $_operationName');
  }
}

/// Sentry implementation for error tracking
class SentryObservabilityService implements ObservabilityService {
  @override
  void logEvent(String eventName, {Map<String, dynamic>? attributes}) {
    debugPrint('Sentry Event: $eventName - $attributes');
  }

  @override
  void recordMetric(String metricName, double value, {Map<String, dynamic>? tags}) {
    debugPrint('Sentry Metric: $metricName = $value - $tags');
  }

  @override
  ObservabilitySpan startTrace(String operationName, {Map<String, dynamic>? context}) {
    debugPrint('Sentry Trace Start: $operationName - $context');
    return _SentrySpan(operationName);
  }

  @override
  void setContextAttribute(String key, dynamic value) {
    debugPrint('Sentry Context: $key = $value');
  }

  @override
  void reportError(dynamic error, StackTrace stackTrace, {String? context}) {
    debugPrint('Sentry Error: $error - $stackTrace - $context');
  }
}

class _SentrySpan implements ObservabilitySpan {
  final String _operationName;

  _SentrySpan(this._operationName);

  @override
  void setAttribute(String key, dynamic value) {
    debugPrint('Sentry Span Attribute: $_operationName - $key = $value');
  }

  @override
  void recordError(dynamic error, StackTrace stackTrace) {
    debugPrint('Sentry Span Error: $_operationName - $error - $stackTrace');
  }

  @override
  void end() {
    debugPrint('Sentry Span End: $_operationName');
  }
}

/// Provider for observability service
final observabilityServiceProvider = Provider<ObservabilityService>((ref) {
  return CompositeObservabilityService([
    FirebaseObservabilityService(),
    SentryObservabilityService(),
  ]);
});

/// Extension for easy observability access
extension ObservabilityExtension on BuildContext {
  ObservabilityService get observability =>
      ProviderScope.containerOf(this, listen: false).read(observabilityServiceProvider);
}

/// Mock implementation for testing
class MockObservabilityService implements ObservabilityService {
  final List<String> loggedEvents = [];
  final List<Map<String, dynamic>> recordedMetrics = [];
  final List<dynamic> reportedErrors = [];

  @override
  void logEvent(String eventName, {Map<String, dynamic>? attributes}) {
    loggedEvents.add(eventName);
  }

  @override
  void recordMetric(String metricName, double value, {Map<String, dynamic>? tags}) {
    recordedMetrics.add({
      'metric': metricName,
      'value': value,
      'tags': tags,
    });
  }

  @override
  ObservabilitySpan startTrace(String operationName, {Map<String, dynamic>? context}) {
    return _MockSpan(operationName);
  }

  @override
  void setContextAttribute(String key, dynamic value) {}

  @override
  void reportError(dynamic error, StackTrace stackTrace, {String? context}) {
    reportedErrors.add(error);
  }
}

class _MockSpan implements ObservabilitySpan {
  final String operationName;

  _MockSpan(this.operationName);

  @override
  void setAttribute(String key, dynamic value) {}

  @override
  void recordError(dynamic error, StackTrace stackTrace) {}

  @override
  void end() {}
}