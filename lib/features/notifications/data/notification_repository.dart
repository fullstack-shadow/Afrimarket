import 'package:my_flutter_app/features/notifications/domain/models/notification.dart';
import 'package:my_flutter_app/services/network_client.dart';
import 'package:my_flutter_app/core/utils/logger.dart';

abstract class NotificationRepository {
  Future<List<Notification>> getNotifications({bool refresh = false});
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead();
  Future<void> deleteNotification(String notificationId);
}

class NotificationRepositoryImpl implements NotificationRepository {
  final NetworkClient _networkClient;

  NotificationRepositoryImpl(this._networkClient);

  @override
  Future<List<Notification>> getNotifications({bool refresh = false}) async {
    try {
      final response = await _networkClient.get(
        '/notifications',
        queryParams: {'refresh': refresh.toString()},
      );
      return (response as List)
          .map((item) => Notification.fromJson(item))
          .toList();
    } catch (e) {
      Logger.error('Failed to fetch notifications: $e');
      rethrow;
    }
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    try {
      await _networkClient.patch(
        '/notifications/$notificationId/mark-read',
      );
    } catch (e) {
      Logger.error('Failed to mark notification as read: $e');
      rethrow;
    }
  }

  @override
  Future<void> markAllAsRead() async {
    try {
      await _networkClient.patch('/notifications/mark-all-read');
    } catch (e) {
      Logger.error('Failed to mark all notifications as read: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _networkClient.delete('/notifications/$notificationId');
    } catch (e) {
      Logger.error('Failed to delete notification: $e');
      rethrow;
    }
  }
}