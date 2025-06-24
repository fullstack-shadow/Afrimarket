import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Product data model with serialization
///
/// Principles:
/// 1. Readability: Clear field definitions
/// 2. Immutability: Final fields with copyWith
/// 3. Safety: Nullable vs non-nullable separation
/// 4. Serialization: Firestore and JSON support
@immutable
class ProductModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final String sellerId;
  final String category;
  final List<String> imageUrls;
  final int stockCount;
  final double? discountPercent;
  final double? rating;
  final int? reviewCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.sellerId,
    required this.category,
    required this.imageUrls,
    required this.stockCount,
    this.discountPercent,
    this.rating,
    this.reviewCount,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Current price after discount
  double get discountedPrice {
    if (discountPercent != null) {
      return price * (1 - discountPercent! / 100);
    }
    return price;
  }

  /// Indicates if product is out of stock
  bool get isOutOfStock => stockCount <= 0;

  /// Creates a copy with updated values
  ProductModel copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? sellerId,
    String? category,
    List<String>? imageUrls,
    int? stockCount,
    double? discountPercent,
    double? rating,
    int? reviewCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      sellerId: sellerId ?? this.sellerId,
      category: category ?? this.category,
      imageUrls: imageUrls ?? this.imageUrls,
      stockCount: stockCount ?? this.stockCount,
      discountPercent: discountPercent ?? this.discountPercent,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Creates from Firestore DocumentSnapshot
  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] as num).toDouble(),
      sellerId: data['sellerId'] ?? '',
      category: data['category'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      stockCount: data['stockCount'] ?? 0,
      discountPercent: data['discountPercent']?.toDouble(),
      rating: data['rating']?.toDouble(),
      reviewCount: data['reviewCount']?.toInt(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Converts to Firestore-compatible map
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'sellerId': sellerId,
      'category': category,
      'imageUrls': imageUrls,
      'stockCount': stockCount,
      'discountPercent': discountPercent,
      'rating': rating,
      'reviewCount': reviewCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Creates from JSON map
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] as num).toDouble(),
      sellerId: json['sellerId'] ?? '',
      category: json['category'] ?? '',
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      stockCount: json['stockCount'] ?? 0,
      discountPercent: json['discountPercent']?.toDouble(),
      rating: json['rating']?.toDouble(),
      reviewCount: json['reviewCount']?.toInt(),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  /// Converts to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'sellerId': sellerId,
      'category': category,
      'imageUrls': imageUrls,
      'stockCount': stockCount,
      'discountPercent': discountPercent,
      'rating': rating,
      'reviewCount': reviewCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Provider for empty product state
final emptyProductProvider = Provider<ProductModel>((ref) {
  final now = DateTime.now();
  return ProductModel(
    id: '',
    name: '',
    description: '',
    price: 0.0,
    sellerId: '',
    category: '',
    imageUrls: const [],
    stockCount: 0,
    createdAt: now,
    updatedAt: now,
  );
});