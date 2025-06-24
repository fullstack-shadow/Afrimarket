import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

class Notification extends Equatable {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime createdAt;
  final bool isRead;
  final String? imageUrl;
  final String? actionUrl;
  final Map<String, dynamic>? payload;

  const Notification({
    @required required this.id,
    @required required this.title,
    @required required this.body,
    @required required this.type,
    @required required this.createdAt,
    this.isRead = false,
    this.imageUrl,
    this.actionUrl,
    this.payload,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      type: NotificationType.values[json['type'] as int],
      createdAt: DateTime.parse(json['createdAt'] as String),
      isRead: json['isRead'] as bool? ?? false,
      imageUrl: json['imageUrl'] as String?,
      actionUrl: json['actionUrl'] as String?,
      payload: json['payload'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type.index,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'imageUrl': imageUrl,
      'actionUrl': actionUrl,
      'payload': payload,
    };
  }

  Notification copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    DateTime? createdAt,
    bool? isRead,
    String? imageUrl,
    String? actionUrl,
    Map<String, dynamic>? payload,
  }) {
    return Notification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      imageUrl: imageUrl ?? this.imageUrl,
      actionUrl: actionUrl ?? this.actionUrl,
      payload: payload ?? this.payload,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        body,
        type,
        createdAt,
        isRead,
        imageUrl,
        actionUrl,
        payload,
      ];
}

enum NotificationType {
  orderUpdate,      // Order status changes
  paymentSuccess,   // Payment confirmation
  promotion,        // Special offers
  chatMessage,      // New chat message
  systemAlert,      // Important platform updates
  friendActivity,   // Friend/seller activity
}