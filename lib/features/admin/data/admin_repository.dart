import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart' as logger;

// Import all domain models with aliases to avoid conflicts
import '../domain/models/admin_analytics.dart' as admin_analytics;
import '../domain/models/admin_stats.dart' as admin_stats;
import '../domain/models/admin_user.dart' as admin_user;
import '../domain/models/admin_activity.dart' as admin_activity;
import '../domain/models/time_series_sales.dart' as time_series;
import '../domain/models/top_product.dart' as top_product;
import '../domain/models/user_filter.dart';
import '../domain/models/analytics_time_frame.dart';

/// Custom exceptions for admin operations
class AdminRepositoryException implements Exception {
  final String message;
  final StackTrace? stackTrace;

  AdminRepositoryException(this.message, [this.stackTrace]);

  @override
  String toString() => 'AdminRepositoryException: $message';
}

class InsufficientPrivilegesException extends AdminRepositoryException {
  InsufficientPrivilegesException() : super('Admin privileges required');
}

class DocumentNotFoundException extends AdminRepositoryException {
  DocumentNotFoundException(String docPath) : super('Document not found: $docPath');
}

/// Interface for AdminRepository
abstract class IAdminRepository {
  Future<Either<AdminRepositoryException, admin_stats.AdminStats>> getDashboardStats();
  Stream<Either<AdminRepositoryException, admin_stats.AdminStats>> dashboardStatsStream();
  Future<Either<AdminRepositoryException, List<admin_user.AdminUser>>> getUsers({
    int? limit,
    String? lastUserId,
    UserFilter? filter,
  });
  Future<Either<AdminRepositoryException, Unit>> updateUserStatus({
    required String userId,
    required bool isActive,
  });
  Future<Either<AdminRepositoryException, admin_analytics.AdminAnalytics>> getAnalytics({
    required AnalyticsTimeFrame timeFrame,
  });
  Future<Either<AdminRepositoryException, List<admin_activity.AdminActivity>>> getRecentActivities({
    int limit,
  });
  Future<Either<AdminRepositoryException, List<admin_user.AdminUser>>> searchUsers(String query);
  Future<Either<AdminRepositoryException, List<time_series.TimeSeriesSales>>> getSalesData({
    required DateTime startDate,
    required DateTime endDate,
  });
  Future<Either<AdminRepositoryException, List<top_product.TopProduct>>> getTopProducts({
    int limit,
    DateTime? startDate,
    DateTime? endDate,
  });
}

class AdminRepository implements IAdminRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final logger.Logger _logger = logger.Logger();

  AdminRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Verifies admin privileges before operations
  Future<Either<AdminRepositoryException, Unit>> _verifyAdmin() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Left(AdminRepositoryException('Not authenticated'));
      }

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!(userDoc.data()?['is_admin'] ?? false)) {
        return Left(InsufficientPrivilegesException());
      }

      return const Right(unit);
    } catch (e, stack) {
      _logger.e('Admin verification failed', error: e, stackTrace: stack);
      return Left(AdminRepositoryException('Failed to verify admin privileges', stack));
    }
  }

  @override
  Future<Either<AdminRepositoryException, admin_stats.AdminStats>> getDashboardStats() async {
    final verification = await _verifyAdmin();
    return verification.fold(
      (failure) => Left(failure),
      (_) async {
        try {
          const statsDocPath = 'admin_stats/summary';
          final statsDoc = await _firestore.doc(statsDocPath).get();

          if (!statsDoc.exists) {
            return Left(DocumentNotFoundException(statsDocPath));
          }

          return Right(admin_stats.AdminStats.fromFirestore(statsDoc));
        } on FirebaseException catch (e, stack) {
          _logger.e('Failed to fetch dashboard stats', error: e, stackTrace: stack);
          return Left(AdminRepositoryException('Failed to fetch dashboard stats', stack));
        } catch (e, stack) {
          _logger.e('Unexpected error fetching dashboard stats', error: e, stackTrace: stack);
          return Left(AdminRepositoryException('Unexpected error', stack));
        }
      },
    );
  }

  @override
  Stream<Either<AdminRepositoryException, admin_stats.AdminStats>> dashboardStatsStream() {
    return _firestore
        .doc('admin_stats/summary')
        .snapshots()
        .map<Either<AdminRepositoryException, admin_stats.AdminStats>>((doc) {
          if (!doc.exists) {
            return Left<AdminRepositoryException, admin_stats.AdminStats>(
              DocumentNotFoundException('admin_stats/summary')
            );
          }
          try {
            return Right<AdminRepositoryException, admin_stats.AdminStats>(
              admin_stats.AdminStats.fromFirestore(doc)
            );
          } catch (e, stack) {
            _logger.e('Error parsing dashboard stats', error: e, stackTrace: stack);
            return Left<AdminRepositoryException, admin_stats.AdminStats>(
              AdminRepositoryException('Error parsing dashboard stats', stack)
            );
          }
        })
        .handleError((error, stackTrace) {
          _logger.e('Error in dashboard stats stream', error: error, stackTrace: stackTrace);
          return Left<AdminRepositoryException, admin_stats.AdminStats>(
            AdminRepositoryException('Error in dashboard stats stream', stackTrace)
          );
        });
  }

  @override
  Future<Either<AdminRepositoryException, List<admin_user.AdminUser>>> getUsers({
    int? limit,
    String? lastUserId,
    UserFilter? filter,
  }) async {
    final effectiveLimit = limit ?? 20;
    final effectiveFilter = filter ?? UserFilter.all;
    try {
      Query query = _firestore.collection('users').limit(effectiveLimit);
      
      // Apply filters
      switch (effectiveFilter) {
        case UserFilter.active:
          query = query.where('is_active', isEqualTo: true);
          break;
        case UserFilter.inactive:
          query = query.where('is_active', isEqualTo: false);
          break;
        case UserFilter.sellers:
          query = query.where('is_seller', isEqualTo: true);
          break;
        case UserFilter.buyers:
          query = query.where('is_seller', isEqualTo: false);
          break;
        case UserFilter.recent:
          query = query.orderBy('joined_date', descending: true);
          break;
        case UserFilter.all:
        default:
          break;
      }

      if (lastUserId != null) {
        final lastDoc = await _firestore.collection('users').doc(lastUserId).get();
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();
      final users = snapshot.docs
          .map((doc) => admin_user.AdminUser.fromFirestore(doc))
          .toList();

      return Right(users);
    } catch (e, stack) {
      _logger.e('Failed to fetch users', error: e, stackTrace: stack);
      return Left(AdminRepositoryException('Failed to fetch users', stack));
    }
  }

  @override
  Future<Either<AdminRepositoryException, Unit>> updateUserStatus({
    required String userId,
    required bool isActive,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'is_active': isActive,
        'updated_at': FieldValue.serverTimestamp(),
      });
      return const Right(unit);
    } catch (e, stack) {
      _logger.e('Failed to update user status', error: e, stackTrace: stack);
      return Left(AdminRepositoryException('Failed to update user status', stack));
    }
  }

  @override
  Future<Either<AdminRepositoryException, admin_analytics.AdminAnalytics>> getAnalytics({
    required AnalyticsTimeFrame timeFrame,
  }) async {
    try {
      final now = DateTime.now();
      late final DateTime startDate;
      late final DateTime endDate = now;
      
      switch (timeFrame) {
        case AnalyticsTimeFrame.last7Days:
          startDate = now.subtract(const Duration(days: 7));
          break;
        case AnalyticsTimeFrame.last30Days:
          startDate = now.subtract(const Duration(days: 30));
          break;
        case AnalyticsTimeFrame.last90Days:
          startDate = now.subtract(const Duration(days: 90));
          break;
        case AnalyticsTimeFrame.thisYear:
          startDate = DateTime(now.year);
          break;
        case AnalyticsTimeFrame.allTime:
          startDate = DateTime(2020); // App launch date or similar
          break;
        case AnalyticsTimeFrame.custom:
          // TODO: Implement custom time frame logic
          startDate = DateTime(2020); // App launch date or similar
          break;
      }

      // Fetch analytics data from Firestore
      final analyticsDoc = await _firestore
          .collection('analytics')
          .doc('summary')
          .get();

      if (!analyticsDoc.exists) {
        return Left(DocumentNotFoundException('analytics/summary'));
      }

      return Right(admin_analytics.AdminAnalytics.fromFirestore(analyticsDoc));
    } catch (e, stack) {
      _logger.e('Failed to fetch analytics', error: e, stackTrace: stack);
      return Left(AdminRepositoryException('Failed to fetch analytics', stack));
    }
  }

  @override
  Future<Either<AdminRepositoryException, List<admin_activity.AdminActivity>>> getRecentActivities({
    int limit = 10,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('activities')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      final activities = snapshot.docs
          .map((doc) => admin_activity.AdminActivity.fromFirestore(doc))
          .toList();

      return Right(activities);
    } catch (e, stack) {
      _logger.e('Failed to fetch recent activities', error: e, stackTrace: stack);
      return Left(AdminRepositoryException('Failed to fetch recent activities', stack));
    }
  }

  @override
  Future<Either<AdminRepositoryException, List<admin_user.AdminUser>>> searchUsers(String query) async {
    try {
      if (query.length < 3) {
        return const Right([]);
      }

      final snapshot = await _firestore
          .collection('users')
          .where('search_terms', arrayContains: query.toLowerCase())
          .limit(20)
          .get();

      final users = snapshot.docs
          .map((doc) => admin_user.AdminUser.fromFirestore(doc))
          .toList();

      return Right(users);
    } catch (e, stack) {
      _logger.e('Failed to search users', error: e, stackTrace: stack);
      return Left(AdminRepositoryException('Failed to search users', stack));
    }
  }

  @override
  Future<Either<AdminRepositoryException, List<time_series.TimeSeriesSales>>> getSalesData({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('sales')
          .where('date', isGreaterThanOrEqualTo: startDate)
          .where('date', isLessThanOrEqualTo: endDate)
          .orderBy('date')
          .get();

      final sales = snapshot.docs.map((doc) {
        final data = doc.data();
        return time_series.TimeSeriesSales(
          time: (data['date'] as Timestamp).toDate(),
          sales: (data['amount'] as num).toDouble(),
        );
      }).toList();

      return Right(sales);
    } catch (e, stack) {
      _logger.e('Failed to fetch sales data', error: e, stackTrace: stack);
      return Left(AdminRepositoryException('Failed to fetch sales data', stack));
    }
  }

  @override
  Future<Either<AdminRepositoryException, List<top_product.TopProduct>>> getTopProducts({
    int limit = 10,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      await _verifyAdmin();
      Query query = _firestore
          .collection('products')
          .orderBy('sales_count', descending: true)
          .limit(limit);

      if (startDate != null && endDate != null) {
        query = query
            .where('last_sold', isGreaterThanOrEqualTo: startDate)
            .where('last_sold', isLessThanOrEqualTo: endDate);
      }

      final snapshot = await query.get();

      final products = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        return top_product.TopProduct(
          id: doc.id,
          name: data['name'] as String? ?? 'Unnamed Product',
          imageUrl: (data['image_urls'] as List<dynamic>?)?.isNotEmpty == true 
              ? (data['image_urls'] as List<dynamic>).first as String 
              : '',
          sales: (data['sales_count'] as int?) ?? 0,
          revenue: (data['revenue'] ?? 0).toDouble(),
        );
      }).toList();

      return Right(products);
    } on FirebaseException catch (e, stack) {
      _logger.e('Firebase error while fetching top products', error: e, stackTrace: stack);
      return Left(AdminRepositoryException('Failed to fetch top products: ${e.message}', stack));
    } on AdminRepositoryException {
      rethrow;
    } catch (e, stack) {
      _logger.e('Unexpected error while fetching top products', error: e, stackTrace: stack);
      return Left(AdminRepositoryException('An unexpected error occurred', stack));
    }
  }
}