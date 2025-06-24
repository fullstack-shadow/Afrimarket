import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../services/auth_service.dart';
// Import the activity models directly since we're using the same types
import '../../domain/models/admin_activity.dart' as activity_models;
import '../../domain/models/admin_analytics.dart';
import '../../domain/models/admin_stats.dart' hide AdminUser, AdminAnalytics, AdminActivity;
import '../../domain/models/admin_user.dart';
import '../../domain/models/analytics_time_frame.dart';
import '../../domain/models/time_series_sales.dart' as time_series;
import '../../domain/models/user_filter.dart';
class AdminController extends ChangeNotifier {
  final AuthService _authService;
  final FirebaseFirestore _firestore;

  AdminController({
    required AuthService authService,
    required FirebaseFirestore firestore,
  })  : _authService = authService,
        _firestore = firestore {
    _init();
  }

  bool _isLoading = false;
  bool _isLoadingUsers = false;
  bool _isLoadingAnalytics = false;
  AdminStats? _stats;
  AdminAnalytics? _analytics;
  List<AdminUser> _users = [];
  List<AdminUser> _filteredUsers = [];
  UserFilter _currentUserFilter = UserFilter.all;
  AnalyticsTimeFrame _currentTimeFrame = AnalyticsTimeFrame.last7Days;

  bool get isLoading => _isLoading;
  bool get isLoadingUsers => _isLoadingUsers;
  bool get isLoadingAnalytics => _isLoadingAnalytics;
  AdminStats? get stats => _stats;
  AdminAnalytics? get analytics => _analytics;
  List<AdminUser> get users => _users;
  List<AdminUser> get filteredUsers => _filteredUsers;
  UserFilter get currentUserFilter => _currentUserFilter;
  AnalyticsTimeFrame get currentTimeFrame => _currentTimeFrame;

  Future<void> _init() async {
    await Future.wait([
      _loadDashboardStats(),
      _loadUsers(),
      _loadAnalytics(),
    ]);
  }

  Future<void> _loadDashboardStats() async {
    if (_isLoading) return; // Prevent duplicate calls
    
    _isLoading = true;
    notifyListeners();

    try {
      // Load summary stats
      final statsDoc = await _firestore
          .collection('admin_stats')
          .doc('summary')
          .get(const GetOptions(source: Source.server));
          
      _stats = statsDoc.exists ? AdminStats(
        totalUsers: (statsDoc.data()?['total_users'] as num?)?.toInt() ?? 0,
        activeSellers: (statsDoc.data()?['active_sellers'] as num?)?.toInt() ?? 0,
        todayOrders: (statsDoc.data()?['today_orders'] as num?)?.toInt() ?? 0,
        totalRevenue: (statsDoc.data()?['total_revenue'] as num?)?.toDouble() ?? 0.0,
        salesChartData: [],
        recentActivities: [],
      ) : AdminStats(
        totalUsers: 0,
        activeSellers: 0,
        todayOrders: 0,
        totalRevenue: 0.0,
        salesChartData: [],
        recentActivities: [],
      );

      // Load recent activities
      try {
        final activities = await _firestore
            .collection('admin_activities')
            .orderBy('timestamp', descending: true)
            .limit(10)
            .get();
            
        final activityList = activities.docs
            .map((doc) => activity_models.AdminActivity.fromFirestore(doc))
            .toList();
            
        _stats = _stats?.copyWith(recentActivities: activityList);
    } catch (e) {        debugPrint('Error loading activities: $e');
      }

      // Load sales chart data
      try {
        final salesData = await _firestore
            .collection('sales_analytics')
            .orderBy('date')
            .limit(30)
            .get(const GetOptions(source: Source.server));
            
        final salesList = salesData.docs
            .map<time_series.TimeSeriesSales>((doc) {
              final data = doc.data();
              final date = data['date'] as Timestamp?;
              final amount = data['amount'] as num?;
              
              if (date == null || amount == null) {
                throw FormatException('Invalid sales data format in document ${doc.id}');
              }
              
              return time_series.TimeSeriesSales(
                time: date.toDate(),
                sales: amount.toDouble(),
              );
            })
            .toList(growable: false);
            
        _stats = _stats?.copyWith(salesChartData: salesList as List<TimeSeriesSales>?);
      } catch (e, stackTrace) {
        debugPrint('Error loading sales data: $e\n$stackTrace');
        // Continue with existing stats if sales data fails to load
      }
    } catch (e) {
      debugPrint('Error loading dashboard stats: $e');
      // Consider showing an error message to the user
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadUsers() async {
    if (_isLoadingUsers) return; // Prevent duplicate calls
    
    _isLoadingUsers = true;
    notifyListeners();

    try {
      final usersSnapshot = await _firestore
          .collection('users')
          .limit(200)
          .get(const GetOptions(source: Source.server));
          
      _users = usersSnapshot.docs
          .where((doc) => doc.exists)
          .map<AdminUser>((doc) => AdminUser.fromFirestore(doc))
          .toList(growable: false);
      
      _filteredUsers = List<AdminUser>.unmodifiable(_users);
      
      // Apply current filter if not 'all'
      if (_currentUserFilter != UserFilter.all) {
        filterUsers(_currentUserFilter);
      }
    } on FirebaseException catch (e) {
      debugPrint('Firestore error loading users: ${e.message}');
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('Unexpected error loading users: $e\n$stackTrace');
      rethrow;
    } finally {
      _isLoadingUsers = false;
      notifyListeners();
    }
  }

  Future<void> _loadAnalytics() async {
    if (_isLoadingAnalytics) return; // Prevent duplicate calls
    
    _isLoadingAnalytics = true;
    notifyListeners();

    try {
      final timeFrameStr = _currentTimeFrame.name;
      final analyticsDoc = await _firestore
          .collection('admin_analytics')
          .doc(timeFrameStr)
          .get(const GetOptions(source: Source.server));
          
      _analytics = analyticsDoc.exists 
          ? AdminAnalytics.fromFirestore(analyticsDoc)
          : AdminAnalytics(
              conversionRate: 0.0,
              avgOrderValue: 0.0,
              repeatCustomerRate: 0.0,
              refereeSignups: 0,
              salesSeries: [],
              userGrowthSeries: [],
              topProducts: [],
            );
    } on FirebaseException catch (e) {
      debugPrint('Firestore error loading analytics: ${e.message}');
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('Unexpected error loading analytics: $e\n$stackTrace');
      rethrow;
    } finally {
      _isLoadingAnalytics = false;
      notifyListeners();
    }
  }

  Future<void> refreshDashboard() async {
    _isLoading = true;
    notifyListeners();
    await _loadDashboardStats();
  }

  Future<void> refreshUsers() async {
    _isLoadingUsers = true;
    notifyListeners();
    await _loadUsers();
  }

  Future<void> refreshAnalytics() async {
    _isLoadingAnalytics = true;
    notifyListeners();
    await _loadAnalytics();
  }

  void searchUsers(String query) {
    if (query.isEmpty) {
      _filteredUsers = List<AdminUser>.from(_users);
    } else {
      _filteredUsers = _users.where((user) {
        return user.name.toLowerCase().contains(query.toLowerCase()) ||
            user.email.toLowerCase().contains(query.toLowerCase());
      }).toList();
    }
    notifyListeners();
  }

  void filterUsers(UserFilter filter) {
    _currentUserFilter = filter;
    switch (filter) {
      case UserFilter.all:
        _filteredUsers = List<AdminUser>.from(_users);
        break;
      case UserFilter.active:
        _filteredUsers = _users.where((u) => u.isActive).toList();
        break;
      case UserFilter.inactive:
        _filteredUsers = _users.where((u) => !u.isActive).toList();
        break;
      case UserFilter.sellers:
        _filteredUsers = _users.where((u) => u.isSeller).toList();
        break;
      case UserFilter.buyers:
        _filteredUsers = _users.where((u) => !u.isSeller).toList();
        break;
      case UserFilter.recent:
        final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
        _filteredUsers = _users.where((u) => u.joinedDate.isAfter(thirtyDaysAgo)).toList();
        break;
    }
    notifyListeners();
  }

  Future<void> changeAnalyticsTimeFrame(AnalyticsTimeFrame frame) async {
    _currentTimeFrame = frame;
    _isLoadingAnalytics = true;
    notifyListeners();
    await _loadAnalytics();
  }

  /// Toggles the active status of a user
  /// 
  /// Throws [StateError] if user with given ID is not found
  /// Throws [FirebaseException] if the update operation fails
  /// Toggles the active status of a user
  /// 
  /// Throws [StateError] if user with given ID is not found
  /// Throws [FirebaseException] if the update operation fails
  Future<void> toggleUserStatus(String userId) async {
    if (userId.isEmpty) {
      throw ArgumentError.value(userId, 'userId', 'User ID cannot be empty');
    }

    // Find the user in the local list
    final userIndex = _users.indexWhere((u) => u.id == userId);
    if (userIndex == -1) {
      throw StateError('User with ID $userId not found');
    }
    
    final user = _users[userIndex];
    final newStatus = !user.isActive;
    
    // Optimistic update
    _users[userIndex] = user.copyWith(isActive: newStatus);
    notifyListeners();
    
    try {
      // Update in Firestore
      await _firestore.collection('users').doc(userId).update({
        'is_active': newStatus,
        'updated_at': FieldValue.serverTimestamp(),
      });
      
      // Update filtered list if needed
      if (_currentUserFilter != UserFilter.all) {
        filterUsers(_currentUserFilter);
      }
      
      // Log the activity
      await _logAdminActivity(
        type: activity_models.AdminActivityType.user,
        description: '${newStatus ? 'Activated' : 'Deactivated'} user: ${user.email}',
      );
    } on FirebaseException catch (e) {
      // Revert on error
      _users[userIndex] = user;
      notifyListeners();
      debugPrint('Firestore error toggling user status: ${e.message}');
      rethrow;
    } catch (e, stackTrace) {
      // Revert on error
      _users[userIndex] = user;
      notifyListeners();
      debugPrint('Unexpected error toggling user status: $e\n$stackTrace');
      rethrow;
    }
  }
  
  /// Logs an admin activity to the database
  /// 
  /// Returns the ID of the created activity document, or null if logging failed
  Future<String?> _logAdminActivity({
    required activity_models.AdminActivityType type,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        debugPrint('Cannot log admin activity: No current user');
        return null;
      }
      
      final docRef = await _firestore.collection('admin_activities').add({
        'admin_id': currentUser.uid,
        'admin_email': currentUser.email,
        'type': type.index,
        'description': description,
        'metadata': metadata ?? <String, dynamic>{},
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      return docRef.id;
    } catch (e, stackTrace) {
      debugPrint('Error logging admin activity: $e\n$stackTrace');
      // Don't rethrow as this is a non-critical operation
      return null;
    }
  }
  
  @override
  void dispose() {
    // Cancel any pending operations
    _isLoading = false;
    _isLoadingUsers = false;
    _isLoadingAnalytics = false;
    super.dispose();
  }
}