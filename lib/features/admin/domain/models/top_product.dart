class TopProduct {
  final String id;
  final String name;
  final String imageUrl;
  final int sales;
  final double revenue;

  TopProduct({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.sales,
    required this.revenue,
  });

  factory TopProduct.fromJson(Map<String, dynamic> json) {
    return TopProduct(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Unnamed Product',
      imageUrl: json['imageUrl'] as String? ?? '',
      sales: (json['sales'] as num?)?.toInt() ?? 0,
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'sales': sales,
      'revenue': revenue,
    };
  }
}
