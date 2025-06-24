import 'package:afrimarket/features/chat/domain/models/message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

extension MessageExtensions on Message {
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'senderId': senderId,
      'recipientId': recipientId,
      'timestamp': timestamp,
      'type': type.index,
      'text': text,
      'imageUrl': imageUrl,
      'product': product?.toJson(),
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

class MessageConverter {
  static Message fromFirestore(Map<String, dynamic> data) {
    final type = MessageType.values[data['type'] as int];
    
    switch (type) {
      case MessageType.text:
        return Message.text(
          id: data['id'] as String,
          text: data['text'] as String,
          senderId: data['senderId'] as String,
          recipientId: data['recipientId'] as String,
          timestamp: (data['timestamp'] as Timestamp).toDate(),
        );
      case MessageType.image:
        return Message.image(
          id: data['id'] as String,
          imageUrl: data['imageUrl'] as String,
          senderId: data['senderId'] as String,
          recipientId: data['recipientId'] as String,
          timestamp: (data['timestamp'] as Timestamp).toDate(),
        );
      case MessageType.product:
        return Message.product(
          id: data['id'] as String,
          product: Product.fromJson(data['product'] as Map<String, dynamic>),
          senderId: data['senderId'] as String,
          recipientId: data['recipientId'] as String,
          timestamp: (data['timestamp'] as Timestamp).toDate(),
        );
      case MessageType.location:
        return Message.location(
          id: data['id'] as String,
          latitude: data['latitude'] as double,
          longitude: data['longitude'] as double,
          senderId: data['senderId'] as String,
          recipientId: data['recipientId'] as String,
          timestamp: (data['timestamp'] as Timestamp).toDate(),
        );
      default:
        throw UnsupportedError('Unsupported message type');
    }
  }
}
