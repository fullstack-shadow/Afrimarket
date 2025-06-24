import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Centralized application configuration manager
///
/// Handles environment-specific settings with compile-time safety
///
/// Principles:
/// 1. Readability: Clear structure and naming
/// 2. Modularity: Separate concerns per environment
/// 3. Immutability: Config values are final
/// 4. Testability: Easy environment switching
/// 5. Safety: Compile-time validation
abstract class AppConfig {
  /// Base API endpoint for the environment
  String get baseApiUrl;

  /// Firebase project ID
  String get firebaseProjectId;

  /// Payment gateway API key
  String get paymentApiKey;

  /// Analytics tracking ID
  String get analyticsId;

  /// Feature flags for environment-specific capabilities
  Map<FeatureFlag, bool> get featureFlags;

  /// Remote configuration endpoint
  String get remoteConfigUrl;

  /// Logging verbosity level
  LogLevel get logLevel;

  /// M-Pesa integration credentials
  MpesaCredentials get mpesaCredentials;

  /// Deep link base URL
  String get deepLinkBaseUrl;

  /// Validates configuration completeness
  void validate() {
    assert(baseApiUrl.isNotEmpty, 'baseApiUrl must be defined');
    assert(firebaseProjectId.isNotEmpty, 'firebaseProjectId must be defined');
    assert(paymentApiKey.isNotEmpty, 'paymentApiKey must be defined');
    assert(mpesaCredentials.consumerKey.isNotEmpty, 'M-Pesa consumerKey required');
    assert(mpesaCredentials.consumerSecret.isNotEmpty, 'M-Pesa consumerSecret required');
  }

  /// Returns feature flag status (defaults to false if not found)
  bool isFeatureEnabled(FeatureFlag flag) {
    return featureFlags[flag] ?? false;
  }
}

/// Production environment configuration
class ProdConfig implements AppConfig {
  @override
  final String baseApiUrl = 'https://api.commerceapp.com/v1';

  @override
  final String firebaseProjectId = 'prod-commerce-app';

  @override
  final String paymentApiKey = 'pk_live_...';

  @override
  final String analyticsId = 'UA-PROD-12345';

  @override
  final Map<FeatureFlag, bool> featureFlags = {
    FeatureFlag.chatNotifications: true,
    FeatureFlag.referralProgram: true,
    FeatureFlag.advancedAnalytics: true,
    FeatureFlag.offlineMode: false,
  };

  @override
  final String remoteConfigUrl = 'https://config.commerceapp.com/prod';

  @override
  final LogLevel logLevel = LogLevel.warning;

  @override
  final MpesaCredentials mpesaCredentials = MpesaCredentials(
    consumerKey: 'prod_consumer_key',
    consumerSecret: 'prod_consumer_secret',
    shortCode: '174379',
    passKey: 'prod_pass_key',
  );

  @override
  final String deepLinkBaseUrl = 'https://app.commerceapp.com';

  @override
  void validate() {
    assert(baseApiUrl.isNotEmpty, 'baseApiUrl must be defined');
    assert(firebaseProjectId.isNotEmpty, 'firebaseProjectId must be defined');
    assert(paymentApiKey.isNotEmpty, 'paymentApiKey must be defined');
    assert(mpesaCredentials.consumerKey.isNotEmpty, 'M-Pesa consumerKey required');
    assert(mpesaCredentials.consumerSecret.isNotEmpty, 'M-Pesa consumerSecret required');
  }

  @override
  bool isFeatureEnabled(FeatureFlag flag) {
    return featureFlags[flag] ?? false;
  }
}

/// Staging environment configuration
class StagingConfig implements AppConfig {
  @override
  final String baseApiUrl = 'https://staging-api.commerceapp.com/v1';

  @override
  final String firebaseProjectId = 'staging-commerce-app';

  @override
  final String paymentApiKey = 'pk_test_...';

  @override
  final String analyticsId = 'UA-STAGING-12345';

  @override
  final Map<FeatureFlag, bool> featureFlags = {
    FeatureFlag.chatNotifications: true,
    FeatureFlag.referralProgram: false,
    FeatureFlag.advancedAnalytics: true,
    FeatureFlag.offlineMode: true,
  };

  @override
  final String remoteConfigUrl = 'https://config.commerceapp.com/staging';

  @override
  final LogLevel logLevel = LogLevel.info;

  @override
  final MpesaCredentials mpesaCredentials = MpesaCredentials(
    consumerKey: 'staging_consumer_key',
    consumerSecret: 'staging_consumer_secret',
    shortCode: '174379',
    passKey: 'staging_pass_key',
  );

  @override
  final String deepLinkBaseUrl = 'https://staging.commerceapp.com';

  @override
  void validate() {
    assert(baseApiUrl.isNotEmpty, 'baseApiUrl must be defined');
    assert(firebaseProjectId.isNotEmpty, 'firebaseProjectId must be defined');
    assert(paymentApiKey.isNotEmpty, 'paymentApiKey must be defined');
    assert(mpesaCredentials.consumerKey.isNotEmpty, 'M-Pesa consumerKey required');
    assert(mpesaCredentials.consumerSecret.isNotEmpty, 'M-Pesa consumerSecret required');
  }

  @override
  bool isFeatureEnabled(FeatureFlag flag) {
    return featureFlags[flag] ?? false;
  }
}

/// Development environment configuration
class DevConfig implements AppConfig {
  @override
  final String baseApiUrl = 'http://localhost:8080/v1';

  @override
  final String firebaseProjectId = 'dev-commerce-app';

  @override
  final String paymentApiKey = 'pk_dev_...';

  @override
  final String analyticsId = 'UA-DEV-12345';

  @override
  final Map<FeatureFlag, bool> featureFlags = {
    FeatureFlag.chatNotifications: false,
    FeatureFlag.referralProgram: false,
    FeatureFlag.advancedAnalytics: false,
    FeatureFlag.offlineMode: true,
  };

  @override
  final String remoteConfigUrl = 'http://localhost:8081/config';

  @override
  final LogLevel logLevel = LogLevel.verbose;

  @override
  final MpesaCredentials mpesaCredentials = MpesaCredentials(
    consumerKey: 'dev_consumer_key',
    consumerSecret: 'dev_consumer_secret',
    shortCode: '174379',
    passKey: 'dev_pass_key',
  );

  @override
  final String deepLinkBaseUrl = 'com.commerceapp.dev://';

  @override
  void validate() {
    assert(baseApiUrl.isNotEmpty, 'baseApiUrl must be defined');
    assert(firebaseProjectId.isNotEmpty, 'firebaseProjectId must be defined');
    assert(paymentApiKey.isNotEmpty, 'paymentApiKey must be defined');
    assert(mpesaCredentials.consumerKey.isNotEmpty, 'M-Pesa consumerKey required');
    assert(mpesaCredentials.consumerSecret.isNotEmpty, 'M-Pesa consumerSecret required');
  }

  @override
  bool isFeatureEnabled(FeatureFlag flag) {
    return featureFlags[flag] ?? false;
  }
}

/// M-Pesa credentials container
class MpesaCredentials {
  final String consumerKey;
  final String consumerSecret;
  final String shortCode;
  final String passKey;

  const MpesaCredentials({
    required this.consumerKey,
    required this.consumerSecret,
    required this.shortCode,
    required this.passKey,
  });
}

/// Application feature flags
enum FeatureFlag {
  chatNotifications,
  referralProgram,
  advancedAnalytics,
  offlineMode,
  experimentalUi,
}

/// Logging verbosity levels
enum LogLevel {
  none,
  warning,
  info,
  verbose,
}

/// Environment types
enum EnvironmentType {
  development,
  staging,
  production,
}

/// Provider for application configuration
final appConfigProvider = Provider<AppConfig>((ref) {
  // Determine environment from compile-time constants
  const environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  switch (environment) {
    case 'production':
      return ProdConfig()..validate();
    case 'staging':
      return StagingConfig()..validate();
    case 'development':
    default:
      return DevConfig()..validate();
  }
});

/// Extension for environment helpers
extension EnvironmentChecks on AppConfig {
  bool get isProduction => this is ProdConfig;
  bool get isStaging => this is StagingConfig;
  bool get isDevelopment => this is DevConfig;

  /// Debug-only features (never enabled in prod)
  bool get enableDebugTools {
    return !isProduction && isFeatureEnabled(FeatureFlag.experimentalUi);
  }
}
