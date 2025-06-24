import 'package:afrimarket/features/chat/data/chat_repository.dart';
import 'package:afrimarket/features/chat/domain/repositories/chat_repository.dart';
import 'package:afrimarket/features/chat/presentation/providers/chat_providers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

/// List of overrides for chat-related providers
List<Override> chatProviderOverrides = [
  // Override the chatRepositoryProvider with the actual implementation
  chatRepositoryProvider.overrideWithValue(
    ChatRepositoryImpl(
      firestore: FirebaseFirestore.instance,
      cloudStorage: FirebaseStorage.instance,
      geolocator: GeolocatorPlatform.instance,
      auth: FirebaseAuth.instance,
    ),
  ),
];
