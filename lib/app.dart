// lib/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:afrimarket/core/routing/app_router.dart';
import 'package:afrimarket/core/routing/route_guard.dart';
import 'package:afrimarket/core/theming/theme_manager.dart';
import 'package:afrimarket/features/auth/presentation/screens/login_screen.dart';
import 'package:afrimarket/features/home/presentation/screens/home_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: AfriMarketApp(),
    ),
  );
}

class AfriMarketApp extends ConsumerWidget {
  const AfriMarketApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeManager = ref.watch(themeManagerProvider);

    return MaterialApp(
      title: 'AfriMarket',
      debugShowCheckedModeBanner: false,
      theme: themeManager.currentTheme,
      navigatorKey: router.navigatorKey,
      onGenerateRoute: router.generateRoute,
      initialRoute: '/',
      home: const HomeScreen(), // Fallback if no route matches
    );
  }
}

// Example ThemeManager provider if not already defined
final themeManagerProvider = Provider<ThemeManager>((ref) {
  return ThemeManager();
});

class ThemeManager {
  ThemeData get currentTheme => ThemeData.light(); // Replace with your theme logic
}
