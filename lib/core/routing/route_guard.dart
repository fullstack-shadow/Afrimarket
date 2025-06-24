// lib/core/routing/route_guard.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:afrimarket/features/auth/presentation/screens/login_screen.dart';
import 'package:afrimarket/core/widgets/error_screen.dart';

/// Result of a route guard check
class GuardResult {
  final bool allowed;
  final Widget? redirect;

  const GuardResult({required this.allowed, this.redirect});
}

/// Route protection mechanism
abstract class RouteGuard {
  const RouteGuard();

  /// Factory constructor for authentication guard
  factory RouteGuard.requireAuth() => _AuthenticationGuard();

  /// Factory constructor for admin guard
  factory RouteGuard.requireAdmin() => _AdminGuard();

  /// Determines if route can be activated
  GuardResult canActivate(Ref ref, RouteSettings settings);
}

/// Authentication guard implementation
class _AuthenticationGuard implements RouteGuard {
  const _AuthenticationGuard();

  @override
  GuardResult canActivate(Ref ref, RouteSettings settings) {
    // Replace with actual auth check from your auth provider
    // Example:
    // final authState = ref.read(authProvider);
    // final isAuthenticated = authState.isAuthenticated;

    // Temporary placeholder - set to false to test guard
    const isAuthenticated = false;

    if (!isAuthenticated) {
      return GuardResult(
        allowed: false,
        redirect: const LoginScreen(),
      );
    }
    return const GuardResult(allowed: true);
  }
}

/// Admin guard implementation
class _AdminGuard implements RouteGuard {
  const _AdminGuard();

  @override
  GuardResult canActivate(Ref ref, RouteSettings settings) {
    // Replace with actual admin check from your user provider
    // Example:
    // final userState = ref.read(userProvider);
    // final isAdmin = userState.role == UserRole.admin;

    // Temporary placeholder - set to false to test guard
    const isAdmin = false;

    if (!isAdmin) {
      return GuardResult(
        allowed: false,
        redirect: const ErrorScreen(message: 'Admin access required'),
      );
    }
    return const GuardResult(allowed: true);
  }
}
