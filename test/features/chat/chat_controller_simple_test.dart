import 'package:flutter_test/flutter_test.dart';
import 'package:afrimarket/features/chat/domain/models/message.dart';

void main() {
  group('Message', () {
    test('should create a text message', () {
      final message = Message(
        id: 'msg1',
        senderId: 'user1',
        recipientId: 'user2',
        timestamp: DateTime(2023, 1, 1),
        type: MessageType.text,
        text: 'Hello there!',
      );

      expect(message.id, 'msg1');
      expect(message.senderId, 'user1');
      expect(message.recipientId, 'user2');
      expect(message.type, MessageType.text);
      expect(message.text, 'Hello there!');
    });
  });
}
