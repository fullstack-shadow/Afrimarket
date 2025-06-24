// lib/core/routing/app_router.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:afrimarket/core/routing/route_guard.dart';
import 'package:afrimarket/features/auth/presentation/screens/login_screen.dart';
import 'package:afrimarket/features/auth/presentation/screens/register_screen.dart';
import 'package:afrimarket/features/home/presentation/screens/home_screen.dart';
import 'package:afrimarket/features/profile/presentation/screens/profile_screen.dart';
import 'package:afrimarket/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:afrimarket/features/admin/presentation/screens/user_management_screen.dart';
import 'package:afrimarket/core/widgets/main_layout.dart';
import 'package:afrimarket/core/widgets/error_screen.dart';

/// Centralized application router configuration
class AppRouter {
  final Ref _ref;

  AppRouter(this._ref);

  /// Global navigator key
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Route configuration
  final routes = [
    // Public routes
    _RouteDefinition(
      path: '/login',
      builder: (context) => const LoginScreen(),
    ),
    _RouteDefinition(
      path: '/register',
      builder: (context) => const RegisterScreen(),
    ),

    // Protected routes
    _RouteDefinition(
      path: '/',
      builder: (context) => const MainLayout(child: HomeScreen()),
      guards: [RouteGuard.requireAuth()],
    ),
    _RouteDefinition(
      path: '/profile',
      builder: (context) => MainLayout(child: ProfileScreen(userId: 'currentUserId')),
      guards: [RouteGuard.requireAuth()],
    ),

    // Admin routes
    _RouteDefinition(
      path: '/admin',
      builder: (context) => const MainLayout(child: AdminDashboardScreen()),
      guards: [RouteGuard.requireAuth(), RouteGuard.requireAdmin()],
    ),
    _RouteDefinition(
      path: '/admin/users',
      builder: (context) => const MainLayout(child: UserManagementScreen()),
      guards: [RouteGuard.requireAuth(), RouteGuard.requireAdmin()],
    ),
  ];

  /// Generate route based on settings
  Route<dynamic> generateRoute(RouteSettings settings) {
    final route = routes.firstWhere(
      (r) => r.path == settings.name,
      orElse: () => _RouteDefinition(
        path: settings.name ?? '/404',
        builder: (context) => const ErrorScreen(message: 'Page not found'),
      ),
    );

    // Apply route guards
    for (final guard in route.guards) {
      final result = guard.canActivate(_ref, settings);
      if (!result.allowed) {
        return MaterialPageRoute(
          builder: (context) => result.redirect ?? const LoginScreen(),
        );
      }
    }

    return MaterialPageRoute(
      builder: (context) => route.builder(context),
      settings: settings,
    );
  }

  /// Helper method for navigation
  static void navigateTo(
    BuildContext context,
    String path, {
    Object? arguments,
  }) {
    Navigator.of(context).pushNamed(path, arguments: arguments);
  }

  /// Helper to get current route state
  static RouteState getCurrentRoute(BuildContext context) {
    final route = ModalRoute.of(context);
    return RouteState(
      location: route?.settings.name ?? '',
      arguments: route?.settings.arguments,
    );
  }
}

/// Provider for app router
final appRouterProvider = Provider<AppRouter>((ref) {
  return AppRouter(ref);
});

/// Current route state model
class RouteState {
  final String location;
  final Object? arguments;

  const RouteState({
    required this.location,
    this.arguments,
  });

  /// Gets path parameters (simulated for compatibility)
  Map<String, String> get pathParams => {};

  /// Gets query parameters (simulated for compatibility)
  Map<String, String> get queryParams => {};
}

/// Internal route definition
class _RouteDefinition {
  final String path;
  final Widget Function(BuildContext) builder;
  final List<RouteGuard> guards;

  const _RouteDefinition({
    required this.path,
    required this.builder,
    this.guards = const [],
  });
}
