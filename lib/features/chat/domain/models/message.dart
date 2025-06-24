import 'package:afrimarket/features/shop/domain/models/product.dart';
import 'package:equatable/equatable.dart';

class Message extends Equatable {
  final String id;
  final String senderId;
  final String recipientId;
  final DateTime timestamp;
  final MessageType type;
  final String? text;
  final String? imageUrl;
  final Product? product;
  final double? latitude;
  final double? longitude;

  const Message({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.timestamp,
    required this.type,
    this.text,
    this.imageUrl,
    this.product,
    this.latitude,
    this.longitude,
  });

  factory Message.text({
    required String id,
    required String text,
    required String senderId,
    required String recipientId,
    required DateTime timestamp,
  }) {
    return Message(
      id: id,
      senderId: senderId,
      recipientId: recipientId,
      timestamp: timestamp,
      type: MessageType.text,
      text: text,
    );
  }

  factory Message.image({
    required String id,
    required String imageUrl,
    required String senderId,
    required String recipientId,
    required DateTime timestamp,
  }) {
    return Message(
      id: id,
      senderId: senderId,
      recipientId: recipientId,
      timestamp: timestamp,
      type: MessageType.image,
      imageUrl: imageUrl,
    );
  }

  factory Message.product({
    required String id,
    required Product product,
    required String senderId,
    required String recipientId,
    required DateTime timestamp,
  }) {
    return Message(
      id: id,
      senderId: senderId,
      recipientId: recipientId,
      timestamp: timestamp,
      type: MessageType.product,
      product: product,
    );
  }

  factory Message.location({
    required String id,
    required double latitude,
    required double longitude,
    required String senderId,
    required String recipientId,
    required DateTime timestamp,
  }) {
    return Message(
      id: id,
      senderId: senderId,
      recipientId: recipientId,
      timestamp: timestamp,
      type: MessageType.location,
      latitude: latitude,
      longitude: longitude,
    );
  }

  @override
  List<Object?> get props => [
        id,
        senderId,
        recipientId,
        timestamp,
        type,
        text,
        imageUrl,
        product,
        latitude,
        longitude,
      ];

  Message copyWith({
    String? id,
    String? senderId,
    String? recipientId,
    DateTime? timestamp,
    MessageType? type,
    String? text,
    String? imageUrl,
    Product? product,
    double? latitude,
    double? longitude,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      recipientId: recipientId ?? this.recipientId,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      text: text ?? this.text,
      imageUrl: imageUrl ?? this.imageUrl,
      product: product ?? this.product,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}

enum MessageType {
  text,
  image,
  product,
  location,
  system,
}