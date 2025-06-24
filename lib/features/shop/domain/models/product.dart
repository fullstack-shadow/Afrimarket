import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

class Product extends Equatable {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final int stock;
  final List<String> imageUrls;
  final String sellerId;
  final String sellerName;
  final DateTime createdAt;
  final double rating;
  final int reviewCount;
  final bool isActive;

  const Product({
    @required required this.id,
    @required required this.name,
    @required required this.description,
    @required required this.price,
    @required required this.category,
    @required required this.stock,
    @required required this.imageUrls,
    @required required this.sellerId,
    @required required this.sellerName,
    @required required this.createdAt,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.isActive = true,
  });

  factory Product.empty() {
    return Product(
      id: '',
      name: '',
      description: '',
      price: 0.0,
      category: '',
      stock: 0,
      imageUrls: [],
      sellerId: '',
      sellerName: '',
      createdAt: DateTime.now(),
    );
  }

  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? category,
    int? stock,
    List<String>? imageUrls,
    String? sellerId,
    String? sellerName,
    DateTime? createdAt,
    double? rating,
    int? reviewCount,
    bool? isActive,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      stock: stock ?? this.stock,
      imageUrls: imageUrls ?? this.imageUrls,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      createdAt: createdAt ?? this.createdAt,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'stock': stock,
      'imageUrls': imageUrls,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'createdAt': createdAt.toIso8601String(),
      'rating': rating,
      'reviewCount': reviewCount,
      'isActive': isActive,
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: json['price'] as double,
      category: json['category'] as String,
      stock: json['stock'] as int,
      imageUrls: (json['imageUrls'] as List).cast<String>(),
      sellerId: json['sellerId'] as String,
      sellerName: json['sellerName'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      rating: json['rating'] as double? ?? 0.0,
      reviewCount: json['reviewCount'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  bool get isAvailable => stock > 0 && isActive;
  bool get isOutOfStock => stock <= 0;
  bool get hasDiscount => price < 100; // Example business logic

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        price,
        category,
        stock,
        imageUrls,
        sellerId,
        sellerName,
        createdAt,
        rating,
        reviewCount,
        isActive,
      ];
}