import 'package:get/get.dart';
import 'package:my_flutter_app/features/notifications/domain/models/notification.dart';
import 'package:my_flutter_app/features/notifications/data/notification_repository.dart';
import 'package:my_flutter_app/core/utils/logger.dart';

class NotificationController extends GetxController {
  final NotificationRepository _repository;

  NotificationController(this._repository);

  final RxList<Notification> _notifications = <Notification>[].obs;
  final RxInt _unreadCount = 0.obs;
  final RxBool _isLoading = false.obs;

  List<Notification> get notifications => _notifications;
  int get unreadCount => _unreadCount.value;
  bool get isLoading => _isLoading.value;

  @override
  void onInit() {
    super.onInit();
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    try {
      _isLoading.value = true;
      final notifications = await _repository.getNotifications();
      _notifications.assignAll(notifications);
      _updateUnreadCount();
    } catch (e) {
      Logger.error('Failed to load notifications: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> refreshNotifications() async {
    try {
      final notifications = await _repository.getNotifications(refresh: true);
      _notifications.assignAll(notifications);
      _updateUnreadCount();
    } catch (e) {
      Logger.error('Failed to refresh notifications: $e');
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _repository.markAsRead(notificationId);
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        _updateUnreadCount();
      }
    } catch (e) {
      Logger.error('Failed to mark notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _repository.markAllAsRead();
      _notifications.value = _notifications
          .map((n) => n.copyWith(isRead: true))
          .toList();
      _unreadCount.value = 0;
    } catch (e) {
      Logger.error('Failed to mark all notifications as read: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _repository.deleteNotification(notificationId);
      _notifications.removeWhere((n) => n.id == notificationId);
      _updateUnreadCount();
    } catch (e) {
      Logger.error('Failed to delete notification: $e');
    }
  }

  void _updateUnreadCount() {
    _unreadCount.value = _notifications.where((n) => !n.isRead).length;
  }

  void handleNotificationTap(Notification notification) {
    if (!notification.isRead) {
      markAsRead(notification.id);
    }

    // Handle different notification types
    switch (notification.type) {
      case NotificationType.orderUpdate:
        _handleOrderNotification(notification);
        break;
      case NotificationType.paymentSuccess:
        _handlePaymentNotification(notification);
        break;
      case NotificationType.chatMessage:
        _handleChatNotification(notification);
        break;
      default:
        // No specific action for other types
        break;
    }
  }

  void _handleOrderNotification(Notification notification) {
    final orderId = notification.payload?['orderId'];
    if (orderId != null) {
      Get.toNamed('/orders/$orderId');
    }
  }

  void _handlePaymentNotification(Notification notification) {
    final transactionId = notification.payload?['transactionId'];
    if (transactionId != null) {
      Get.toNamed('/payments/$transactionId');
    }
  }

  void _handleChatNotification(Notification notification) {
    final chatId = notification.payload?['chatId'];
    if (chatId != null) {
      Get.toNamed('/chats/$chatId');
    }
  }
}