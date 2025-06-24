import 'dart:async';
import 'dart:io';

import 'package:afrimarket/features/chat/domain/models/message.dart';

/// Interface for chat repository
abstract class ChatRepository {
  /// Fetches messages for a chat
  Future<List<Message>> getMessages({
    required String chatId,
    String? before,
    int limit = 20,
  });

  /// Stream of messages for real-time updates
  Stream<List<Message>> messageStream(String chatId);
  
  /// Sends a message
  Future<Message> sendMessage(Message message);
  
  /// Disposes the message stream
  Future<void> disposeStream(String chatId);
  
  /// Uploads an image
  Future<String> uploadImage(File image);
  
  /// Gets current device location
  Future<Position> getCurrentLocation();
  
  /// Gets or creates a chat ID for a recipient
  Future<String> getOrCreateChatId(String recipientId);
}
