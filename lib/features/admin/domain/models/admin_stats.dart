import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_activity.dart';
import 'time_series_sales.dart';

class AdminStats {
  final int totalUsers;
  final int activeSellers;
  final int todayOrders;
  final double totalRevenue;
  final List<TimeSeriesSales> salesChartData;
  final List<AdminActivity> recentActivities;

  AdminStats({
    required this.totalUsers,
    required this.activeSellers,
    required this.todayOrders,
    required this.totalRevenue,
    required this.salesChartData,
    required this.recentActivities,
  });

  factory AdminStats.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdminStats(
      totalUsers: data['total_users'] ?? 0,
      activeSellers: data['active_sellers'] ?? 0,
      todayOrders: data['today_orders'] ?? 0,
      totalRevenue: (data['total_revenue'] ?? 0).toDouble(),
      salesChartData: [],
      recentActivities: [],
    );
  }

  AdminStats copyWith({
    List<TimeSeriesSales>? salesChartData,
    List<AdminActivity>? recentActivities,
  }) {
    return AdminStats(
      totalUsers: totalUsers,
      activeSellers: activeSellers,
      todayOrders: todayOrders,
      totalRevenue: totalRevenue,
      salesChartData: salesChartData ?? this.salesChartData,
      recentActivities: recentActivities ?? this.recentActivities,
    );
  }
}

class TimeSeriesSales {
  final DateTime time;
  final double sales;

  TimeSeriesSales({required this.time, required this.sales});
}

// admin_activity.dart

enum AdminActivityType { order, user, payment, system }

class AdminActivity {
  final String id;
  final AdminActivityType type;
  final String description;
  final DateTime timestamp;
  final String timeAgo;

  AdminActivity({
    required this.id,
    required this.type,
    required this.description,
    required this.timestamp,
    required this.timeAgo,
  });

  factory AdminActivity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final timestamp = (data['timestamp'] as Timestamp).toDate();
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    String timeAgo;
    if (difference.inDays > 0) {
      timeAgo = '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      timeAgo = '${difference.inHours}h ago';
    } else {
      timeAgo = '${difference.inMinutes}m ago';
    }

    return AdminActivity(
      id: doc.id,
      type: AdminActivityType.values[data['type'] ?? 0],
      description: data['description'] ?? '',
      timestamp: timestamp,
      timeAgo: timeAgo,
    );
  }
}

// admin_user.dart

class AdminUser {
  final String id;
  final String name;
  final String email;
  final bool isSeller;
  final bool isActive;
  final DateTime joinedDate;

  AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.isSeller,
    required this.isActive,
    required this.joinedDate,
  });

  factory AdminUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdminUser(
      id: doc.id,
      name: data['name'] ?? 'No Name',
      email: data['email'] ?? '',
      isSeller: data['is_seller'] ?? false,
      isActive: data['is_active'] ?? true,
      joinedDate: (data['joined_date'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  AdminUser copyWith({
    bool? isActive,
  }) {
    return AdminUser(
      id: id,
      name: name,
      email: email,
      isSeller: isSeller,
      isActive: isActive ?? this.isActive,
      joinedDate: joinedDate,
    );
  }
}

// admin_analytics.dart
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