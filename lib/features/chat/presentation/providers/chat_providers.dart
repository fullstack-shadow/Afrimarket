import 'dart:io';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:afrimarket/features/chat/domain/models/message.dart';
import 'package:afrimarket/features/chat/domain/repositories/chat_repository.dart';
import 'package:afrimarket/features/chat/presentation/state/chat_state.dart';

part 'chat_providers.g.dart';

/// Provider for the chat repository
@riverpod
ChatRepository chatRepository(Ref ref) {
  throw UnimplementedError('ChatRepository must be overridden in main.dart');
}

/// Provider for the chat controller
@riverpod
class ChatControllerNotifier extends AutoDisposeNotifier<ChatState> {
  @override
  ChatState build() {
    return const ChatState();
  }

  /// Initializes the chat with the given parameters
  Future<void> initializeChat({
    required String recipientId,
    String? chatId,
    String? productId,
  }) async {
    state = state.copyWith(status: ChatStatus.loading);
    try {
      final chatId = await ref.read(chatRepositoryProvider).getOrCreateChatId(recipientId);
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

  /// Sends a text message
  Future<void> sendTextMessage(String text, String recipientId) async {
    if (state.status != ChatStatus.active) {
      throw StateError('Chat must be initialized before sending messages');
    }

    final message = Message.text(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      senderId: state.currentUser?.id ?? '',
      recipientId: recipientId,
      text: text,
      timestamp: DateTime.now(),
    );

    await _sendMessage(message);
  }

  /// Sends an image message
  Future<void> sendImageMessage(File image, String recipientId) async {
    if (state.status != ChatStatus.active) {
      throw StateError('Chat must be initialized before sending messages');
    }

    state = state.copyWith(status: ChatStatus.sending);
    try {
      final imageUrl = await ref.read(chatRepositoryProvider).uploadImage(image);
      
      final message = Message.image(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        senderId: state.currentUser?.id ?? '',
        recipientId: recipientId,
        imageUrl: imageUrl,
        timestamp: DateTime.now(),
      );

      await _sendMessage(message);
    } finally {
      state = state.copyWith(status: ChatStatus.active);
    }
  }

  /// Sends a location message
  Future<void> sendLocationMessage(String recipientId) async {
    if (state.status != ChatStatus.active) {
      throw StateError('Chat must be initialized before sending messages');
    }

    state = state.copyWith(status: ChatStatus.loading);
    try {
      final position = await ref.read(chatRepositoryProvider).getCurrentLocation();
      
      final message = Message.location(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        senderId: state.currentUser?.id ?? '',
        recipientId: recipientId,
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now(),
      );

      await _sendMessage(message);
    } finally {
      state = state.copyWith(status: ChatStatus.active);
    }
  }

  /// Loads more messages
  Future<void> loadMoreMessages() async {
    if (state.status != ChatStatus.active || 
        state.status == ChatStatus.loadingMore || 
        state.hasReachedMax) {
      return;
    }

    state = state.copyWith(status: ChatStatus.loadingMore);
    try {
      final messages = await ref.read(chatRepositoryProvider).getMessages(
            chatId: state.chatId,
            before: state.messages.lastOrNull?.id,
          );

      if (messages.isEmpty) {
        state = state.copyWith(hasReachedMax: true);
        return;
      }

      state = state.copyWith(
        messages: [...state.messages, ...messages],
        status: ChatStatus.active,
      );
    } catch (e) {
      state = state.copyWith(
        status: ChatStatus.error,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  /// Clears any error message
  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(errorMessage: null);
    }
  }

  /// Internal method to send a message
  Future<void> _sendMessage(Message message) async {
    try {
      await ref.read(chatRepositoryProvider).sendMessage(message);
    } catch (e) {
      state = state.copyWith(
        status: ChatStatus.error,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }
}

/// Provider for the chat stream
@riverpod
Stream<List<Message>> chatMessages(Ref ref, String chatId) {
  final repository = ref.watch(chatRepositoryProvider);
  return repository.messageStream(chatId);
}