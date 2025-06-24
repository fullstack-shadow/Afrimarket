import 'package:my_flutter_app/features/orders/domain/models/order.dart';
import 'package:my_flutter_app/services/network_client.dart';
import 'package:my_flutter_app/core/utils/logger.dart';

abstract class OrderRepository {
  Future<List<Order>> getOrders({bool refresh = false});
  Future<Order> getOrderById(String orderId);
  Future<void> cancelOrder(String orderId);
}

class OrderRepositoryImpl implements OrderRepository {
  final NetworkClient _networkClient;

  OrderRepositoryImpl(this._networkClient);

  @override
  Future<List<Order>> getOrders({bool refresh = false}) async {
    try {
      final response = await _networkClient.get(
        '/orders',
        queryParams: {'refresh': refresh.toString()},
      );
      return (response as List)
          .map((item) => Order.fromJson(item))
          .toList();
    } catch (e) {
      Logger.error('Failed to fetch orders: $e');
      rethrow;
    }
  }

  @override
  Future<Order> getOrderById(String orderId) async {
    try {
      final response = await _networkClient.get('/orders/$orderId');
      return Order.fromJson(response);
    } catch (e) {
      Logger.error('Failed to fetch order $orderId: $e');
      rethrow;
    }
  }

  @override
  Future<void> cancelOrder(String orderId) async {
    try {
      await _networkClient.post('/orders/$orderId/cancel');
    } catch (e) {
      Logger.error('Failed to cancel order $orderId: $e');
      rethrow;
    }
  }
}