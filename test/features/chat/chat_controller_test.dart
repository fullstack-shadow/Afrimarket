import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:afrimarket/features/chat/domain/models/message.dart';
import 'package:afrimarket/features/chat/presentation/controllers/chat_controller.dart';
import 'package:afrimarket/features/chat/domain/repositories/chat_repository.dart';
import 'package:afrimarket/core/services/cloud_storage.dart';
import 'package:afrimarket/core/services/encryption_service.dart';
import 'package:afrimarket/core/network/network_client.dart';
import 'package:afrimarket/features/auth/domain/models/user_model.dart';

// Test user data
final testUser = User(
  id: 'test_user_1',
  name: 'Test User',
  email: 'test@example.com',
  phoneNumber: '+1234567890',
);

// Mock Position class for testing
class MockPosition extends Mock implements geo.Position {
  @override
  double get latitude => 0.0;
  
  @override
  double get longitude => 0.0;
  
  @override
  DateTime get timestamp => DateTime.now();
  
  @override
  double get accuracy => 0.0;
  
  @override
  double? get altitude => 0.0;
  
  @override
  double? get heading => 0.0;
  
  @override
  double? get speed => 0.0;
  
  @override
  double? get speedAccuracy => 0.0;
  
  @override
  double? get headingAccuracy => 0.0;
  
  @override
  double? get altitudeAccuracy => 0.0;
  
  @override
  int? get floor => null;
  
  @override
  bool get isMocked => false;
  
  @override
  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'timestamp': timestamp.toIso8601String(),
  };
}

// Mock implementations
class MockChatRepository extends Mock implements ChatRepository {
  final _messages = <Message>[];
  final _streamControllers = <String, StreamController<List<Message>>>{};
  
  @override
  Future<List<Message>> getMessages({
    required String chatId,
    String? before,
    int limit = 20,
  }) async {
    return _messages
        .where((m) => m.chatId == chatId)
        .take(limit)
        .toList();
  }
  
  @override
  Stream<List<Message>> messageStream(String chatId) {
    _streamControllers[chatId] ??= StreamController<List<Message>>.broadcast();
    return _streamControllers[chatId]!.stream;
  }
  
  @override
  Future<Message> sendMessage(Message message) async {
    _messages.add(message);
    if (_streamControllers.containsKey(message.chatId)) {
      _streamControllers[message.chatId]!.add([..._messages]);
    }
    return message;
  }
  
  @override
  Future<String> uploadImage(File image) async => 'https://example.com/image.jpg';
  
  @override
  Future<geo.Position> getCurrentLocation() async => MockPosition();
  
  @override
  Future<String> getOrCreateChatId(String recipientId) async => 'chat_1';
  
  @override
  Future<void> dispose() async {
    for (final controller in _streamControllers.values) {
      await controller.close();
    }
    _streamControllers.clear();
  }
}

class MockCloudStorage extends Mock implements CloudStorage {}
class MockEncryptionServiceImpl extends Mock implements EncryptionService {}
class MockNetworkClient extends Mock implements NetworkClient {}

void main() {
  late MockChatRepository mockChatRepository;
  late ChatController chatController;
  late ProviderContainer container;
  
  setUp(() {
    mockChatRepository = MockChatRepository();
    container = ProviderContainer(
      overrides: [
        chatRepositoryProvider.overrideWithValue(mockChatRepository),
      ],
    );
    chatController = container.read(chatControllerProvider.notifier);
  });
  
  tearDown(() async {
    await container.dispose();
  });
  
  test('initial state is correct', () {
    expect(chatController.state, equals(const ChatState()));
  });
  
  test('can initialize chat', () async {
    // Arrange
    const chatId = 'chat_1';
    const recipientId = 'test_user_2';
    
    // Act
    await chatController.initializeChat(
      chatId: chatId,
      recipientId: recipientId,
    );
    
    // Assert
    expect(chatController.state.chatId, equals(chatId));
    expect(chatController.state.recipientId, equals(recipientId));
  });
  
  test('can send text message', () async {
    // Arrange
    const chatId = 'chat_1';
    const recipientId = 'test_user_2';
    const messageText = 'Hello, world!';
    
    await chatController.initializeChat(
      chatId: chatId,
      recipientId: recipientId,
    );
    
    // Act
    await chatController.sendTextMessage(messageText);
    
    // Assert
    expect(chatController.state.messages, hasLength(1));
    expect(chatController.state.messages.first.text, equals(messageText));
  });
  
  test('can load more messages', () async {
    // Arrange
    const chatId = 'chat_1';
    const recipientId = 'test_user_2';
    
    // Initialize chat
    await chatController.initializeChat(
      chatId: chatId,
      recipientId: recipientId,
    );
    
    // Act & Assert
    expect(
      () => chatController.loadMoreMessages(),
      returnsNormally,
    );
  });
  
  test('can send image message', () async {
    // Arrange
    const chatId = 'chat_1';
    const recipientId = 'test_user_2';
    final testImage = File('test/fixtures/test_image.jpg');
    
    await chatController.initializeChat(
      chatId: chatId,
      recipientId: recipientId,
    );
    
    // Act & Assert
    expect(
      () => chatController.sendImageMessage(testImage),
      returnsNormally,
    );
  });
  
  test('can send location message', () async {
    // Arrange
    const chatId = 'chat_1';
    const recipientId = 'test_user_2';
    
    await chatController.initializeChat(
      chatId: chatId,
      recipientId: recipientId,
    );
    
    // Act & Assert
    expect(
      () => chatController.sendLocationMessage(),
      returnsNormally,
    );
  });
  
  test('can dispose resources', () async {
    // Arrange
    const chatId = 'chat_1';
    const recipientId = 'test_user_2';
    
    await chatController.initializeChat(
      chatId: chatId,
      recipientId: recipientId,
    );
    
    // Act & Assert
    expect(
      () => chatController.dispose(),
      returnsNormally,
    );
  });
}
