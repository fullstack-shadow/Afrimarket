import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAnalytics {
  final double conversionRate;
  final double avgOrderValue;
  final double repeatCustomerRate;
  final int refereeSignups;
  final List<OrdinalSales> salesSeries;
  final List<OrdinalCount> userGrowthSeries;
  final List<TopProduct> topProducts;

  AdminAnalytics({
    required this.conversionRate,
    required this.avgOrderValue,
    required this.repeatCustomerRate,
    required this.refereeSignups,
    required this.salesSeries,
    required this.userGrowthSeries,
    required this.topProducts,
  });

  factory AdminAnalytics.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdminAnalytics(
      conversionRate: (data['conversion_rate'] ?? 0).toDouble(),
      avgOrderValue: (data['avg_order_value'] ?? 0).toDouble(),
      repeatCustomerRate: (data['repeat_customer_rate'] ?? 0).toDouble(),
      refereeSignups: data['referee_signups'] ?? 0,
      salesSeries: _parseSalesSeries(data['sales_series']),
      userGrowthSeries: _parseUserGrowthSeries(data['user_growth']),
      topProducts: _parseTopProducts(data['top_products']),
    );
  }

  static List<OrdinalSales> _parseSalesSeries(dynamic data) {
    if (data is! Map) return [];
    return data.entries.map((e) {
      return OrdinalSales(
        period: e.key,
        sales: (e.value as num).toDouble(),
      );
    }).toList();
  }

  static List<OrdinalCount> _parseUserGrowthSeries(dynamic data) {
    if (data is! Map) return [];
    return data.entries.map((e) {
      return OrdinalCount(
        period: e.key,
        count: e.value as int,
      );
    }).toList();
  }

  static List<TopProduct> _parseTopProducts(dynamic data) {
    if (data is! List) return [];
    return data.map((item) {
      return TopProduct(
        id: item['id'],
        name: item['name'],
        imageUrl: item['image_url'],
        sales: item['sales'],
        revenue: (item['revenue'] as num).toDouble(),
      );
    }).toList();
  }
}

class OrdinalSales {
  final String period;
  final double sales;

  OrdinalSales({required this.period, required this.sales});
}

class OrdinalCount {
  final String period;
  final int count;

  OrdinalCount({required this.period, required this.count});
}

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
}
