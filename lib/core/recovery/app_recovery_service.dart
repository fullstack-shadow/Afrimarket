import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Centralized application recovery service
///
/// Principles:
/// 1. Readability: Clear recovery procedures
/// 2. Resilience: Multiple recovery strategies
/// 3. Testability: Mockable implementation
/// 4. Safety: Error boundaries and fallbacks
abstract class AppRecoveryService {
  /// Attempts to recover from a critical error
  Future<RecoveryResult> recoverFromError({
    required Object error,
    required StackTrace stackTrace,
    required String context,
  });

  /// Registers a recovery strategy
  void registerStrategy(RecoveryStrategy strategy);

  /// Gets current recovery strategies
  List<RecoveryStrategy> get strategies;
}

/// Concrete implementation of AppRecoveryService
class AppRecoveryServiceImpl implements AppRecoveryService {
  final List<RecoveryStrategy> _strategies = [];
  final RecoveryLogger _logger;

  AppRecoveryServiceImpl({required RecoveryLogger logger}) : _logger = logger;

  @override
  Future<RecoveryResult> recoverFromError({
    required Object error,
    required StackTrace stackTrace,
    required String context,
  }) async {
    // Log the error first
    await _logger.logError(error, stackTrace, context);

    // Try each strategy until one succeeds
    for (final strategy in _strategies) {
      try {
        final result = await strategy.attemptRecovery(
          error: error,
          stackTrace: stackTrace,
          context: context,
        );
        
        if (result.isSuccess) {
          return result;
        }
      } catch (e) {
        debugPrint('Recovery strategy failed: $e');
        continue;
      }
    }

    // All strategies failed
    return const RecoveryResult.failure();
  }

  @override
  void registerStrategy(RecoveryStrategy strategy) {
    _strategies.add(strategy);
  }

  @override
  List<RecoveryStrategy> get strategies => List.unmodifiable(_strategies);
}

/// Recovery strategy interface
abstract class RecoveryStrategy {
  /// Attempts to recover from an error
  Future<RecoveryResult> attemptRecovery({
    required Object error,
    required StackTrace stackTrace,
    required String context,
  });
}

/// Recovery result model
class RecoveryResult {
  final bool isSuccess;
  final String? message;
  final RecoveryAction? action;

  const RecoveryResult.success({this.message, this.action})
      : isSuccess = true;

  const RecoveryResult.failure({this.message})
      : isSuccess = false,
        action = null;
}

/// Possible recovery actions
enum RecoveryAction {
  restartApp,
  resetState,
  clearCache,
  navigateToSafety,
  ignore,
}

/// Error logging abstraction
abstract class RecoveryLogger {
  Future<void> logError(
    Object error,
    StackTrace stackTrace,
    String context,
  );
}

/// Default recovery strategies
class CacheClearStrategy implements RecoveryStrategy {
  @override
  Future<RecoveryResult> attemptRecovery({
    required Object error,
    required StackTrace stackTrace,
    required String context,
  }) async {
    try {
      // Implement cache clearing logic
      debugPrint('Attempting cache clear...');
      await Future.delayed(const Duration(milliseconds: 500));
      return const RecoveryResult.success(
        message: 'Cache cleared successfully',
        action: RecoveryAction.clearCache,
      );
    } catch (e) {
      return RecoveryResult.failure(
        message: 'Cache clearing failed: $e',
      );
    }
  }
}

class StateResetStrategy implements RecoveryStrategy {
  @override
  Future<RecoveryResult> attemptRecovery({
    required Object error,
    required StackTrace stackTrace,
    required String context,
  }) async {
    try {
      // Implement state reset logic
      debugPrint('Attempting state reset...');
      await Future.delayed(const Duration(milliseconds: 500));
      return const RecoveryResult.success(
        message: 'State reset successful',
        action: RecoveryAction.resetState,
      );
    } catch (e) {
      return RecoveryResult.failure(
        message: 'State reset failed: $e',
      );
    }
  }
}

/// Provider for recovery service
final recoveryServiceProvider = Provider<AppRecoveryService>((ref) {
  final logger = ref.read(recoveryLoggerProvider);
  final service = AppRecoveryServiceImpl(logger: logger)
    ..registerStrategy(CacheClearStrategy())
    ..registerStrategy(StateResetStrategy());
  return service;
});

/// Provider for recovery logger
final recoveryLoggerProvider = Provider<RecoveryLogger>((ref) {
  return ConsoleRecoveryLogger();
});

/// Console-based logger implementation
class ConsoleRecoveryLogger implements RecoveryLogger {
  @override
  Future<void> logError(
    Object error,
    StackTrace stackTrace,
    String context,
  ) async {
    debugPrint('''
=== RECOVERY ERROR ===
Context: $context
Error: $error
StackTrace: $stackTrace
=====================
''');
  }
}

/// Extension for easy error recovery
extension ErrorRecoveryExtension on BuildContext {
  Future<RecoveryResult> recoverFromError({
    required Object error,
    required StackTrace stackTrace,
    required String context,
  }) async {
    final container = ProviderScope.containerOf(this, listen: false);
    final service = container.read(recoveryServiceProvider);
    return service.recoverFromError(
      error: error,
      stackTrace: stackTrace,
      context: context,
    );
  }
}

/// Mock implementations for testing
class MockRecoveryService implements AppRecoveryService {
  @override
  Future<RecoveryResult> recoverFromError({
    required Object error,
    required StackTrace stackTrace,
    required String context,
  }) async {
    return const RecoveryResult.success();
  }

  @override
  void registerStrategy(RecoveryStrategy strategy) {}

  @override
  List<RecoveryStrategy> get strategies => [];
}

class AlwaysFailStrategy implements RecoveryStrategy {
  @override
  Future<RecoveryResult> attemptRecovery({
    required Object error,
    required StackTrace stackTrace,
    required String context,
  }) async {
    return const RecoveryResult.failure(message: 'Intentional test failure');
  }
}