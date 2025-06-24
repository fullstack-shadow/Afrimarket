import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:afrimarket/features/chat/domain/models/message.dart';
import 'package:afrimarket/features/chat/domain/repositories/chat_repository.dart';
import 'package:afrimarket/features/shop/domain/models/product.dart';
import 'package:afrimarket/core/encryption/encryption_service.dart' as encryption;
import 'package:afrimarket/features/auth/domain/models/user.dart';
import 'package:afrimarket/core/providers/providers.dart' as providers;
import 'package:afrimarket/core/utils/logger.dart' as app_logger;
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

// Provider for ChatController
final chatControllerProvider = StateNotifierProvider.autoDispose<ChatController, ChatState>((ref) {
  return ChatController(
    ref.watch(providers.chatRepositoryProvider),
    ref.watch(providers.encryptionServiceProvider).asData?.value,
    ref.read(providers.imagePickerProvider),
  );
});

// State class for ChatController
class ChatState {
  final List<Message> messages;
  final User? recipient;
  final ChatStatus status;
  final String? chatId;
  final String? errorMessage;

  const ChatState({
    this.messages = const [],
    this.recipient,
    this.status = ChatStatus.initial,
    this.chatId,
    this.errorMessage,
  });

  ChatState copyWith({
    List<Message>? messages,
    User? recipient,
    ChatStatus? status,
    String? chatId,
    String? errorMessage,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      recipient: recipient ?? this.recipient,
      status: status ?? this.status,
      chatId: chatId ?? this.chatId,
      errorMessage: errorMessage,
    );
  }
}

class ChatController extends StateNotifier<ChatState> {
  final ChatRepository _chatRepository;
  final encryption.EncryptionService? _encryptionService;
  final ImagePicker _imagePicker;
  StreamSubscription<List<Message>>? _messageSubscription;
  String? _currentUserId;

  ChatController(
    this._chatRepository,
    this._encryptionService,
    this._imagePicker,
  ) : super(const ChatState());

  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }

  void setCurrentUser(String userId) {
    _currentUserId = userId;
  }

  Future<void> initializeChat({
    required String recipientId,
    String? chatId,
    String? productId,
  }) async {
    try {
      state = state.copyWith(status: ChatStatus.loading);

      // Get or create chat ID
      final chatId = await _chatRepository.getOrCreateChatId(recipientId);
      
      // Set up message stream
      _messageSubscription = _chatRepository.messageStream(chatId).listen(
        (messages) {
          state = state.copyWith(
            messages: messages,
            status: ChatStatus.active,
            chatId: chatId,
          );
        },
        onError: (error) {
          state = state.copyWith(
            status: ChatStatus.error,
            errorMessage: 'Failed to load messages: $error',
          );
        },
      );

      // Load initial messages
      await loadMoreMessages();

      // Load product preview if productId is provided
      if (productId != null) {
        await _loadProductPreview(productId, recipientId);
      }
    } catch (e) {
      state = state.copyWith(
        status: ChatStatus.error,
        errorMessage: 'Failed to initialize chat: $e',
      );
      app_logger.logger.e('Error initializing chat', error: e);
    }
  }

  Future<void> sendTextMessage(String text, String recipientId) async {
    if (text.trim().isEmpty || _currentUserId == null) return;

    try {
      final message = Message.text(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: await _encryptMessage(text),
        senderId: _currentUserId!,
        recipientId: recipientId,
        timestamp: DateTime.now(),
      );

      await _chatRepository.sendMessage(message);
    } catch (e) {
      state = state.copyWith(
        status: ChatStatus.error,
        errorMessage: 'Failed to send message',
      );
      app_logger.logger.e('Error sending text message', error: e);
    }
  }

  Future<void> pickAndSendImage(String recipientId) async {
    try {
      final pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;

      final imageFile = File(pickedFile.path);
      final imageUrl = await _chatRepository.uploadImage(imageFile);

      final message = Message.image(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        imageUrl: imageUrl,
        senderId: _currentUserId!,
        recipientId: recipientId,
        timestamp: DateTime.now(),
      );

      await _chatRepository.sendMessage(message);
    } catch (e) {
      state = state.copyWith(
        status: ChatStatus.error,
        errorMessage: 'Failed to send image',
      );
      app_logger.logger.e('Error sending image', error: e);
    }
  }

  Future<void> sendLocationMessage(String recipientId) async {
    try {
      final position = await _getCurrentLocation();
      final message = Message.location(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        latitude: position.latitude,
        longitude: position.longitude,
        senderId: _currentUserId!,
        recipientId: recipientId,
        timestamp: DateTime.now(),
      );

      await _chatRepository.sendMessage(message);
    } catch (e) {
      state = state.copyWith(
        status: ChatStatus.error,
        errorMessage: 'Failed to send location',
      );
      app_logger.logger.e('Error sending location', error: e);
    }
  }

  Future<void> loadMoreMessages() async {
    if (state.chatId == null) return;

    try {
      final messages = await _chatRepository.getMessages(
        chatId: state.chatId!,
        before: state.messages.isNotEmpty ? state.messages.last.id : null,
        limit: 20,
      );

      state = state.copyWith(
        messages: [...state.messages, ...messages],
      );
    } catch (e) {
      app_logger.logger.e('Error loading more messages', error: e);
    }
  }

  Future<void> disposeChat() async {
    if (state.chatId != null) {
      await _chatRepository.disposeStream(state.chatId!);
    }
    _messageSubscription?.cancel();
  }

  // Helper methods
  Future<String> _encryptMessage(String message) async {
    if (_encryptionService == null) return message;
    return await _encryptionService!.encrypt(message);
  }

  Future<Position> _getCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition();
    return position;
  }

  Future<void> _loadProductPreview(String productId, String recipientId) async {
    try {
      // This would typically fetch product details using a product repository
      // For now, we'll just log it
      app_logger.logger.i('Loading product preview for $productId');
    } catch (e) {
      app_logger.logger.e('Error loading product preview', error: e);
    }
  }
}

enum ChatStatus {
  initial,
  loading,
  active,
  error,
}