// performance_thresholds.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Defines performance thresholds for monitoring
///
/// Principles:
/// 1. Readability: Clear threshold definitions
/// 2. Modularity: Separate from monitoring logic
/// 3. Maintainability: Easy to update thresholds
class PerformanceThresholds {
  final Map<String, dynamic> _thresholds;

  PerformanceThresholds() : _thresholds = {
    // Rendering thresholds
    'screen_render': Duration(milliseconds: 500),
    'app_startup': Duration(milliseconds: 2000),
    
    // Network thresholds
    'network_request': Duration(milliseconds: 3000),
    'api_response': Duration(milliseconds: 1000),
    
    // Computation thresholds
    'computation': Duration(milliseconds: 1000),
    'image_processing': Duration(milliseconds: 500),
    
    // Memory thresholds (in bytes)
    'memory_usage': 200 * 1024 * 1024, // 200MB
    'memory_leak': 50 * 1024 * 1024, // 50MB increase
    
    // Frame rendering thresholds
    'frame_render': Duration(milliseconds: 16), // ~60fps
  };

  /// Gets threshold for a specific metric
  dynamic getThreshold(String metric) => _thresholds[metric];

  /// Checks if value exceeds threshold
  bool exceedsThreshold(String metric, dynamic value) {
    final threshold = _thresholds[metric];
    if (threshold == null) return false;
    
    if (threshold is Duration && value is Duration) {
      return value > threshold;
    } else if (threshold is num && value is num) {
      return value > threshold;
    }
    
    return false;
  }
}

/// Provider for performance thresholds
final performanceThresholdsProvider = Provider<PerformanceThresholds>(
  (ref) => PerformanceThresholds(),
);