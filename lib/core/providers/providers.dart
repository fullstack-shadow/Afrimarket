import 'package:afrimarket/core/encryption/encryption_service.dart';
import 'package:afrimarket/features/chat/data/chat_repository.dart';
import 'package:afrimarket/features/chat/domain/models/message.dart';
import 'package:afrimarket/features/chat/domain/repositories/chat_repository.dart';
import 'package:afrimarket/features/chat/presentation/state/chat_state.dart';
import 'package:afrimarket/services/cloud_storage_wrapper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

// Enable Riverpod code generation
part 'providers.g.dart';

// This is needed to make the generated code work with Riverpod 2.0
typedef Ref = WidgetRef; // For providers that need WidgetRef
// ignore: invalid_use_of_internal_member
void _dummy() => throw UnimplementedError(); // To force code generation

/// Firebase Auth Provider
@riverpod
FirebaseAuth firebaseAuth(FirebaseAuthRef ref) => FirebaseAuth.instance;

/// Firestore Provider
@riverpod
FirebaseFirestore firestore(FirestoreRef ref) => FirebaseFirestore.instance;

/// Image Picker Provider
@riverpod
ImagePicker imagePicker(ImagePickerRef ref) => ImagePicker();

/// Encryption Service Provider
@riverpod
Future<EncryptionService> encryptionService(EncryptionServiceRef ref) async {
  if (kDebugMode && const bool.fromEnvironment('TEST_MODE')) {
    return MockEncryptionService();
  }
  
  // In production, get the key from secure storage
  // final secureStorage = ref.read(secureStorageProvider);
  // final key = await secureStorage.getEncryptionKey();
  // return AesEncryptionService(encryptionKey: key);
  
  // For development, generate a new key
  final key = await EncryptionService.generateEncryptionKey();
  return AesEncryptionService(encryptionKey: key);
}

/// Chat Repository Provider
@riverpod
ChatRepository chatRepository(ChatRepositoryRef ref) {
  final encryptionService = ref.watch(encryptionServiceProvider);
  
  return encryptionService.when(
    data: (service) => ChatRepositoryImpl(
      firestore: ref.watch(firestoreProvider),
      cloudStorage: CloudStorage(),
      geolocator: Geolocator(),
      encryptionService: service,
    ),
    loading: () => throw Exception('Encryption service not initialized'),
    error: (error, stack) => throw Exception('Failed to initialize encryption: $error'),
  );
}

/// Chat Controller Notifier
@riverpod
class ChatController extends _$ChatController {
  @override
  ChatState build() {
    // Subscribe to any providers you need here
    // final someValue = ref.watch(someProvider);
    return const ChatState();
  }
  
  Future<void> sendMessage(Message message) async {
    try {
      final chatId = state.chatId;
      if (chatId.isEmpty) {
        throw Exception('Chat not initialized');
      }
      
      final repository = ref.read(chatRepositoryProvider);
      await repository.sendMessage(message);
      
      // State will be updated via the message stream
    } catch (e) {
      state = state.copyWith(
        status: ChatStatus.error,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  /// Initializes chat with a recipient
  Future<void> initializeChat({
    required String chatId,
    required String recipientId,
    String? productId,
  }) async {
    state = state.copyWith(status: ChatStatus.loading);
    try {
      // Initialize chat logic here
      state = state.copyWith(
        status: ChatStatus.active,
        chatId: chatId,
      );
    } catch (e) {
      state = state.copyWith(
        status: ChatStatus.error,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  // Add any other methods your controller needs
}
