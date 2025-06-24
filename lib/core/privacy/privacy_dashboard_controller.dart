// lib/core/privacy/privacy_dashboard_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';

/// Controller for managing user privacy settings and data
class PrivacyDashboardController extends StateNotifier<PrivacyState> {
  final PrivacyRepository _repository;
  final AnalyticsService? _analytics;
  final SecureStorage? _secureStorage;

  PrivacyDashboardController({
    required PrivacyRepository repository,
    AnalyticsService? analytics,
    SecureStorage? secureStorage,
  })  : _repository = repository,
        _analytics = analytics,
        _secureStorage = secureStorage,
        super(const PrivacyState.loading()) {
    _loadInitialSettings();
  }

  Future<void> _loadInitialSettings() async {
    try {
      state = const PrivacyState.loading();
      
      final settings = await _repository.getPrivacySettings();
      final dataCollection = await _repository.getCollectedData();
      final consentHistory = await _repository.getConsentHistory();

      state = PrivacyState.loaded(
        settings: settings,
        collectedData: dataCollection,
        consentHistory: consentHistory,
      );
    } catch (e) {
      state = PrivacyState.error(
        'Failed to load privacy settings: ${e.toString()}',
      );
    }
  }

  Future<void> updateSetting({
    required PrivacySettingType type,
    required bool value,
  }) async {
    try {
      final currentSettings = state.settings;
      if (currentSettings == null) return;

      final updatedSettings = currentSettings.copyWith(
        type: type,
        value: value,
      );

      state = state.copyWith(settings: updatedSettings);
      await _repository.updatePrivacySetting(type, value);
      await _repository.recordConsentChange(
        type: type,
        value: value,
        timestamp: DateTime.now(),
      );

      if (type == PrivacySettingType.analyticsCollection) {
        await _analytics?.setCollectionEnabled(value);
      }

      if (type == PrivacySettingType.biometricAuth) {
        await _secureStorage?.setBiometricEnabled(value);
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to update setting: ${e.toString()}',
      );
      _loadInitialSettings();
    }
  }

  Future<void> requestDataDeletion() async {
    try {
      state = state.copyWith(isDeleting: true);
      
      final settings = state.settings;
      if (settings != null) {
        await Future.wait(
          PrivacySettingType.values.map((type) => 
            _repository.updatePrivacySetting(type, false),
          ),
        );
      }

      await _repository.requestDataDeletion();
      await _secureStorage?.clearAll();

      state = state.copyWith(
        isDeleting: false,
        deletionRequested: true,
      );

      await _analytics?.logEvent(
        eventName: 'privacy_data_deletion_requested',
      );
    } catch (e) {
      state = state.copyWith(
        isDeleting: false,
        errorMessage: 'Deletion request failed: ${e.toString()}',
      );
    }
  }

  Future<String> exportUserData() async {
    try {
      state = state.copyWith(isExporting: true);
      
      final data = await _repository.exportUserData();
      final exportPath = await _secureStorage?.saveDataExport(data) ?? '';

      state = state.copyWith(isExporting: false);
      return exportPath;
    } catch (e) {
      state = state.copyWith(
        isExporting: false,
        errorMessage: 'Export failed: ${e.toString()}',
      );
      rethrow;
    }
  }

  bool? getSettingValue(PrivacySettingType type) {
    return state.settings?.getValue(type);
  }
}

/// Provider for the privacy controller
final privacyDashboardControllerProvider = StateNotifierProvider<
  PrivacyDashboardController, 
  PrivacyState
>((ref) {
  return PrivacyDashboardController(
    repository: ref.read(privacyRepositoryProvider),
    analytics: ref.read(analyticsServiceProvider),
    secureStorage: ref.read(secureStorageProvider),
  );
});

/// State representation
class PrivacyState {
  final PrivacySettings? settings;
  final List<CollectedDataItem> collectedData;
  final List<ConsentRecord> consentHistory;
  final bool isLoading;
  final bool isDeleting;
  final bool isExporting;
  final bool deletionRequested;
  final String? errorMessage;

  const PrivacyState({
    this.settings,
    this.collectedData = const [],
    this.consentHistory = const [],
    this.isLoading = false,
    this.isDeleting = false,
    this.isExporting = false,
    this.deletionRequested = false,
    this.errorMessage,
  });

  const PrivacyState.loading() : this(isLoading: true);
  const PrivacyState.error(String message) : this(errorMessage: message);

  factory PrivacyState.loaded({
    required PrivacySettings settings,
    required List<CollectedDataItem> collectedData,
    required List<ConsentRecord> consentHistory,
  }) {
    return PrivacyState(
      settings: settings,
      collectedData: collectedData,
      consentHistory: consentHistory,
    );
  }

  PrivacyState copyWith({
    PrivacySettings? settings,
    List<CollectedDataItem>? collectedData,
    List<ConsentRecord>? consentHistory,
    bool? isLoading,
    bool? isDeleting,
    bool? isExporting,
    bool? deletionRequested,
    String? errorMessage,
  }) {
    return PrivacyState(
      settings: settings ?? this.settings,
      collectedData: collectedData ?? this.collectedData,
      consentHistory: consentHistory ?? this.consentHistory,
      isLoading: isLoading ?? this.isLoading,
      isDeleting: isDeleting ?? this.isDeleting,
      isExporting: isExporting ?? this.isExporting,
      deletionRequested: deletionRequested ?? this.deletionRequested,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Privacy settings model
class PrivacySettings {
  final List<PrivacySetting> _settings;

  const PrivacySettings(this._settings);

  factory PrivacySettings.defaults() {
    return PrivacySettings([
      PrivacySetting(type: PrivacySettingType.analyticsCollection, value: true),
      PrivacySetting(type: PrivacySettingType.personalizedAds, value: false),
      PrivacySetting(type: PrivacySettingType.biometricAuth, value: true),
      PrivacySetting(type: PrivacySettingType.dataSharing, value: false),
      PrivacySetting(type: PrivacySettingType.locationTracking, value: false),
    ]);
  }

  PrivacySettings copyWith({PrivacySettingType? type, bool? value}) {
    return PrivacySettings(
      _settings.map((s) => s.type == type ? s.copyWith(value: value) : s).toList(),
    );
  }

  bool? getValue(PrivacySettingType type) {
    return _settings.firstWhereOrNull((s) => s.type == type)?.value;
  }

  List<PrivacySetting> get allSettings => List.unmodifiable(_settings);
}

/// Individual privacy setting
class PrivacySetting {
  final PrivacySettingType type;
  final bool value;

  const PrivacySetting({required this.type, required this.value});

  PrivacySetting copyWith({bool? value}) {
    return PrivacySetting(type: type, value: value ?? this.value);
  }
}

/// Types of privacy settings
enum PrivacySettingType {
  analyticsCollection,
  personalizedAds,
  biometricAuth,
  dataSharing,
  locationTracking,
}

/// Collected data item
class CollectedDataItem {
  final String dataType;
  final String description;
  final DateTime lastCollected;
  final int dataSize;

  const CollectedDataItem({
    required this.dataType,
    required this.description,
    required this.lastCollected,
    required this.dataSize,
  });
}

/// Consent change record
class ConsentRecord {
  final PrivacySettingType type;
  final bool value;
  final DateTime timestamp;

  const ConsentRecord({
    required this.type,
    required this.value,
    required this.timestamp,
  });
}

/// Repository interface
abstract class PrivacyRepository {
  Future<PrivacySettings> getPrivacySettings();
  Future<List<CollectedDataItem>> getCollectedData();
  Future<List<ConsentRecord>> getConsentHistory();
  Future<void> updatePrivacySetting(PrivacySettingType type, bool value);
  Future<void> recordConsentChange({
    required PrivacySettingType type,
    required bool value,
    required DateTime timestamp,
  });
  Future<void> requestDataDeletion();
  Future<Map<String, dynamic>> exportUserData();
}

/// Analytics service interface
abstract class AnalyticsService {
  Future<void> setCollectionEnabled(bool enabled);
  Future<void> logEvent({required String eventName});
}

/// Secure storage interface
abstract class SecureStorage {
  Future<void> setBiometricEnabled(bool enabled);
  Future<void> clearAll();
  Future<String> saveDataExport(Map<String, dynamic> data);
}

/// Providers
final privacyRepositoryProvider = Provider<PrivacyRepository>((ref) {
  throw UnimplementedError('PrivacyRepository provider must be overridden');
});

final analyticsServiceProvider = Provider<AnalyticsService?>((ref) => null);
final secureStorageProvider = Provider<SecureStorage?>((ref) => null);