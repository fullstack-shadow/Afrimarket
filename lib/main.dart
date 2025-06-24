import 'package:afrimarket/core/routing/app_router.dart';
import 'package:afrimarket/core/theming/theme_manager.dart';
import 'package:afrimarket/features/auth/presentation/controllers/auth_controller.dart';
import 'package:afrimarket/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:afrimarket/features/splash/presentation/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Main app router configuration
final appRouterProvider = Provider<AppRouter>((ref) {
  final authState = ref.watch(authControllerProvider);
  return AppRouter(authState: authState);
});

class AppRouter {
  final AuthState authState;
  
  AppRouter({required this.authState});
  
  late final GoRouter config = GoRouter(
    refreshListenable: authState,
    initialLocation: '/splash',
    routes: [
      // Splash Screen
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      
      // Onboarding Flow
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      
      // Auth Routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),
      
      // Main App Shell
      ShellRoute(
        builder: (context, state, child) => MainAppShell(child: child),
        routes: [
          // Home
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),
          
          // Shop
          GoRoute(
            path: '/shop',
            name: 'shop',
            builder: (context, state) => const ShopHomeScreen(),
            routes: [
              GoRoute(
                path: 'product/:id',
                name: 'product-detail',
                builder: (context, state) => ProductDetailScreen(
                  productId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          
          // Chat
          GoRoute(
            path: '/chat',
            name: 'chat',
            builder: (context, state) => const ChatListScreen(),
            routes: [
              GoRoute(
                path: 'conversation/:id',
                name: 'chat-conversation',
                builder: (context, state) => ChatScreen(
                  chatId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          
          // Profile
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
    
    // Redirect based on auth state
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final isOnboardingComplete = authState.isOnboardingComplete;
      final isSplash = state.location == '/splash';
      final isAuthPage = state.location.startsWith('/login') || 
                          state.location.startsWith('/signup');
      final isOnboardingPage = state.location == '/onboarding';
      
      // Still initializing
      if (authState.isLoading) return null;
      
      // Redirect logic
      if (!isOnboardingComplete && !isOnboardingPage && !isSplash) {
        return '/onboarding';
      }
      
      if (!isLoggedIn && !isAuthPage && !isSplash && !isOnboardingPage) {
        return '/login';
      }
      
      if (isLoggedIn && (isAuthPage || isOnboardingPage || isSplash)) {
        return '/home';
      }
      
      return null;
    },
    
    // Error handling
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.error}'),
      ),
    ),
  );
}

class MainAppShell extends ConsumerWidget {
  final Widget child;
  
  const MainAppShell({super.key, required this.child});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: child,
      bottomNavigationBar: const AppBottomNavBar(),
    );
  }
}