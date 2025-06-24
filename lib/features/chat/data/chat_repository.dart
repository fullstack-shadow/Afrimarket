import 'dart:async';
import 'dart:io';

import 'package:afrimarket/features/chat/domain/models/message.dart';
import 'package:afrimarket/features/chat/domain/models/message_extensions.dart';
import 'package:afrimarket/features/chat/domain/repositories/chat_repository.dart';
import 'package:afrimarket/services/cloud_storage_wrapper.dart';
import 'package:afrimarket/core/encryption/encryption_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRepositoryImpl implements ChatRepository {
  final FirebaseFirestore _firestore;
  final CloudStorage _cloudStorage;
  final Geolocator _geolocator;
  final EncryptionService _encryptionService;
  final Map<String, StreamSubscription> _subscriptions = {};

  ChatRepositoryImpl({
    required FirebaseFirestore firestore,
    required CloudStorage cloudStorage,
    required Geolocator geolocator,
    required EncryptionService encryptionService,
  })  : _firestore = firestore,
        _cloudStorage = cloudStorage,
        _geolocator = geolocator,
        _encryptionService = encryptionService;

  @override
  Future<List<Message>> getMessages({
    required String chatId,
    String? before,
    int limit = 20,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => Message.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get messages: $e');
    }
  }

  @override
  Stream<List<Message>> messageStream(String chatId) {
    final controller = StreamController<List<Message>>();
    
    final subscription = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .listen((snapshot) {
      final messages = snapshot.docs
          .map((doc) => Message.fromFirestore(doc.data()))
          .toList();
      controller.add(messages);
    });

    _subscriptions[chatId] = subscription;
    return controller.stream;
  }

  @override
  Future<Message> sendMessage(Message message) async {
    try {
      final chatId = await getOrCreateChatId(message.recipientId);
      final messageData = message.toFirestore();
      final docRef = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(messageData);
      
      // Create a new message with the document ID
      return message.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  @override
  Future<void> disposeStream(String chatId) async {
    _subscriptions[chatId]?.cancel();
    _subscriptions.remove(chatId);
  }

  @override
  Future<String> uploadImage(File image) async {
    try {
      return await _cloudStorage.uploadImage(image);
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  @override
  Future<Position> getCurrentLocation() async {
    try {
      return await _geolocator.getCurrentPosition();
    } catch (e) {
      throw Exception('Failed to get current location: $e');
    }
  }
  
  @override
  Future<String> getOrCreateChatId(String recipientId) async {
    try {
      // Get current user ID from Firebase Auth
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      final currentUserId = currentUser.uid;
      
      // Create a sorted list of user IDs to ensure consistent chat IDs
      final userIds = [currentUserId, recipientId]..sort();
      final chatId = userIds.join('_');
      
      // Check if chat document exists
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      
      // If chat doesn't exist, create it
      if (!chatDoc.exists) {
        await _firestore.collection('chats').doc(chatId).set({
          'participants': userIds,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      
      return chatId;
    } catch (e) {
      throw Exception('Failed to get or create chat ID: $e');
    }
  }
}

// Moved to message_extensions.dart