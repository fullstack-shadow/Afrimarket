import 'package:get/get.dart';
import 'package:my_flutter_app/features/orders/domain/models/order.dart';
import 'package:my_flutter_app/features/orders/data/order_repository.dart';
import 'package:my_flutter_app/core/utils/logger.dart';

class OrderController extends GetxController {
  final OrderRepository _repository;

  OrderController(this._repository);

  final RxList<Order> _orders = <Order>[].obs;
  final RxBool _isLoading = false.obs;
  final RxString _errorMessage = ''.obs;

  List<Order> get orders => _orders;
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;

  @override
  void onInit() {
    super.onInit();
    loadOrders();
  }

  Future<void> loadOrders() async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';
      final orders = await _repository.getOrders();
      _orders.assignAll(orders);
    } catch (e) {
      _errorMessage.value = 'Failed to load orders';
      Logger.error('Order load failed: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> refreshOrders() async {
    try {
      final orders = await _repository.getOrders(refresh: true);
      _orders.assignAll(orders);
    } catch (e) {
      _errorMessage.value = 'Failed to refresh orders';
      Logger.error('Order refresh failed: $e');
    }
  }

  Future<Order?> getOrderById(String orderId) async {
    try {
      return await _repository.getOrderById(orderId);
    } catch (e) {
      Logger.error('Failed to fetch order $orderId: $e');
      return null;
    }
  }

  Future<void> cancelOrder(String orderId) async {
    try {
      await _repository.cancelOrder(orderId);
      final index = _orders.indexWhere((order) => order.id == orderId);
      if (index != -1) {
        _orders[index] = _orders[index].copyWith(
          status: OrderStatus.cancelled,
          updatedAt: DateTime.now(),
        );
      }
      Get.snackbar('Success', 'Order cancelled');
    } catch (e) {
      Logger.error('Failed to cancel order $orderId: $e');
      Get.snackbar('Error', 'Failed to cancel order');
    }
  }

  Future<void> trackOrder(String orderId) async {
    try {
      final order = await _repository.getOrderById(orderId);
      if (order != null) {
        Get.toNamed('/orders/tracking', arguments: {'order': order});
      }
    } catch (e) {
      Logger.error('Failed to track order $orderId: $e');
    }
  }

  List<Order> get pendingOrders =>
      _orders.where((order) => order.isPending).toList();

  List<Order> get processingOrders =>
      _orders.where((order) => order.isProcessing).toList();

  List<Order> get shippedOrders =>
      _orders.where((order) => order.isShipped).toList();

  List<Order> get completedOrders =>
      _orders.where((order) => order.isCompleted).toList();

  List<Order> get cancelledOrders =>
      _orders.where((order) => order.isCancelled).toList();
}