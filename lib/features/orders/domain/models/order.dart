import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:my_flutter_app/features/shop/domain/models/product.dart';

class Order extends Equatable {
  final String id;
  final String userId;
  final List<OrderItem> items;
  final double totalAmount;
  final String currency;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? trackingNumber;
  final String? deliveryAddress;
  final String? paymentMethod;
  final String? paymentId;
  final String? deliveryNotes;

  const Order({
    @required required this.id,
    @required required this.userId,
    @required required this.items,
    @required required this.totalAmount,
    @required required this.currency,
    @required required this.status,
    @required required this.createdAt,
    this.updatedAt,
    this.trackingNumber,
    this.deliveryAddress,
    this.paymentMethod,
    this.paymentId,
    this.deliveryNotes,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      userId: json['userId'] as String,
      items: (json['items'] as List)
          .map((item) => OrderItem.fromJson(item))
          .toList(),
      totalAmount: json['totalAmount'] as double,
      currency: json['currency'] as String? ?? 'KES',
      status: OrderStatus.values[json['status'] as int],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      trackingNumber: json['trackingNumber'] as String?,
      deliveryAddress: json['deliveryAddress'] as String?,
      paymentMethod: json['paymentMethod'] as String?,
      paymentId: json['paymentId'] as String?,
      deliveryNotes: json['deliveryNotes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'items': items.map((item) => item.toJson()).toList(),
      'totalAmount': totalAmount,
      'currency': currency,
      'status': status.index,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'trackingNumber': trackingNumber,
      'deliveryAddress': deliveryAddress,
      'paymentMethod': paymentMethod,
      'paymentId': paymentId,
      'deliveryNotes': deliveryNotes,
    };
  }

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  bool get isCompleted => status == OrderStatus.delivered;
  bool get isCancelled => status == OrderStatus.cancelled;
  bool get isPending => status == OrderStatus.pending;
  bool get isProcessing => status == OrderStatus.processing;
  bool get isShipped => status == OrderStatus.shipped;

  @override
  List<Object?> get props => [
        id,
        userId,
        items,
        totalAmount,
        currency,
        status,
        createdAt,
        updatedAt,
        trackingNumber,
        deliveryAddress,
        paymentMethod,
        paymentId,
        deliveryNotes,
      ];
}

class OrderItem extends Equatable {
  final String productId;
  final String productName;
  final double unitPrice;
  final int quantity;
  final String? imageUrl;
  final String? sellerId;

  const OrderItem({
    @required required this.productId,
    @required required this.productName,
    @required required this.unitPrice,
    @required required this.quantity,
    this.imageUrl,
    this.sellerId,
  });

  factory OrderItem.fromProduct(Product product, {int quantity = 1}) {
    return OrderItem(
      productId: product.id,
      productName: product.name,
      unitPrice: product.price,
      quantity: quantity,
      imageUrl: product.imageUrls.isNotEmpty ? product.imageUrls.first : null,
      sellerId: product.sellerId,
    );
  }

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      unitPrice: json['unitPrice'] as double,
      quantity: json['quantity'] as int,
      imageUrl: json['imageUrl'] as String?,
      sellerId: json['sellerId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'imageUrl': imageUrl,
      'sellerId': sellerId,
    };
  }

  double get totalPrice => unitPrice * quantity;

  @override
  List<Object?> get props => [
        productId,
        productName,
        unitPrice,
        quantity,
        imageUrl,
        sellerId,
      ];
}

enum OrderStatus {
  pending,     // Order placed but not processed
  confirmed,   // Seller confirmed order
  processing,  // Preparing for shipment
  shipped,     // Sent to delivery
  delivered,   // Successfully delivered
  cancelled,   // Order cancelled
  returned,    // Order returned
}