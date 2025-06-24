import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:your_app/features/orders/data/order_repository.dart';
import 'package:your_app/features/orders/domain/models/order.dart';
import 'package:your_app/features/orders/domain/models/order_status.dart';
import 'package:your_app/features/orders/presentation/controllers/order_controller.dart';

class MockOrderRepository extends Mock implements OrderRepository {}

void main() {
  late OrderController orderController;
  late MockOrderRepository mockOrderRepository;
  late Listener<OrderState> listener;

  final testOrder = Order(
    id: 'order1',
    userId: 'user1',
    items: [
      OrderItem(
        productId: 'prod1',
        quantity: 2,
        price: 100.0,
      ),
    ],
    totalAmount: 200.0,
    status: OrderStatus.processing,
    createdAt: DateTime(2023, 1, 1),
    updatedAt: DateTime(2023, 1, 1),
    shippingAddress: '123 Main St',
    paymentMethod: 'M-Pesa',
  );

  setUp(() {
    mockOrderRepository = MockOrderRepository();
    orderController = OrderController(repository: mockOrderRepository);
    listener = Listener<OrderState>();
    
    registerFallbackValue(OrderState.initial());
  });

  group('OrderController', () {
    test('initial state is OrderState.initial', () {
      expect(orderController.state, equals(OrderState.initial()));
    });

    group('loadOrders', () {
      test('successful orders loading', () async {
        // Arrange
        final orders = [testOrder];
        when(() => mockOrderRepository.getUserOrders('user1'))
            .thenAnswer((_) async => orders);

        orderController.addListener(listener);

        // Act
        await orderController.loadOrders('user1');

        // Assert
        verifyInOrder([
          () => listener(null, const OrderState.loading()),
          () => listener(const OrderState.loading(), 
                OrderState.loaded(orders)),
        ]);
      });

      test('empty orders list', () async {
        // Arrange
        when(() => mockOrderRepository.getUserOrders('user1'))
            .thenAnswer((_) async => []);

        orderController.addListener(listener);

        // Act
        await orderController.loadOrders('user1');

        // Assert
        verifyInOrder([
          () => listener(null, const OrderState.loading()),
          () => listener(const OrderState.loading(), 
                const OrderState.loaded([])),
        ]);
      });

      test('error loading orders', () async {
        // Arrange
        final exception = Exception('Failed to load orders');
        when(() => mockOrderRepository.getUserOrders('user1'))
            .thenThrow(exception);

        orderController.addListener(listener);

        // Act
        await orderController.loadOrders('user1');

        // Assert
        verifyInOrder([
          () => listener(null, const OrderState.loading()),
          () => listener(const OrderState.loading(), 
                OrderState.error('Failed to load orders')),
        ]);
      });
    });

    group('createOrder', () {
      test('successful order creation', () async {
        // Arrange
        when(() => mockOrderRepository.createOrder(testOrder))
            .thenAnswer((_) async => testOrder);

        // Preload orders
        orderController.state = OrderState.loaded([]);
        orderController.addListener(listener);

        // Act
        await orderController.createOrder(testOrder);

        // Assert
        verifyInOrder([
          () => listener(OrderState.loaded([]), 
                OrderState.loaded([testOrder])),
        ]);
      });

      test('optimistic UI update', () async {
        // Arrange
        when(() => mockOrderRepository.createOrder(testOrder))
            .thenAnswer((_) async => testOrder.copyWith(id: 'new-order'));

        // Preload orders
        orderController.state = OrderState.loaded([]);
        orderController.addListener(listener);

        // Act
        final future = orderController.createOrder(testOrder);

        // Immediately after creation
        verify(() => listener(OrderState.loaded([]), 
              OrderState.loaded([any(that: isA<Order>())]))).called(1);
        
        await future;
        
        // After completion
        verify(() => listener(
              OrderState.loaded([any(that: isA<Order>())]), 
              OrderState.loaded([testOrder.copyWith(id: 'new-order')]))).called(1);
      });
    });

    group('updateOrderStatus', () {
      const orderId = 'order1';
      const newStatus = OrderStatus.shipped;

      test('successful status update', () async {
        // Arrange
        final updatedOrder = testOrder.copyWith(status: newStatus);
        when(() => mockOrderRepository.updateOrderStatus(orderId, newStatus))
            .thenAnswer((_) async => updatedOrder);

        // Preload orders
        orderController.state = OrderState.loaded([testOrder]);
        orderController.addListener(listener);

        // Act
        await orderController.updateOrderStatus(orderId, newStatus);

        // Assert
        verify(() => listener(
              OrderState.loaded([testOrder]), 
              OrderState.loaded([updatedOrder]))).called(1);
      });

      test('status update with error', () async {
        // Arrange
        final exception = Exception('Update failed');
        when(() => mockOrderRepository.updateOrderStatus(orderId, newStatus))
            .thenThrow(exception);

        // Preload orders
        orderController.state = OrderState.loaded([testOrder]);
        orderController.addListener(listener);

        // Act
        await orderController.updateOrderStatus(orderId, newStatus);

        // Assert
        verifyInOrder([
          () => listener(OrderState.loaded([testOrder]), 
                OrderState.error('Update failed')),
          () => listener(OrderState.error('Update failed'), 
                OrderState.loaded([testOrder])), // Reverts to previous state
        ]);
      });
    });

    group('cancelOrder', () {
      const orderId = 'order1';

      test('successful cancellation', () async {
        // Arrange
        final cancelledOrder = testOrder.copyWith(
          status: OrderStatus.cancelled,
          cancellationReason: 'User request',
        );
        when(() => mockOrderRepository.cancelOrder(orderId, 'User request'))
            .thenAnswer((_) async => cancelledOrder);

        // Preload orders
        orderController.state = OrderState.loaded([testOrder]);
        orderController.addListener(listener);

        // Act
        await orderController.cancelOrder(orderId, 'User request');

        // Assert
        verify(() => listener(
              OrderState.loaded([testOrder]), 
              OrderState.loaded([cancelledOrder]))).called(1);
      });

      test('cancellation failure', () async {
        // Arrange
        when(() => mockOrderRepository.cancelOrder(orderId, 'User request'))
            .thenThrow(Exception('Cancellation failed'));

        // Preload orders
        orderController.state = OrderState.loaded([testOrder]);
        orderController.addListener(listener);

        // Act
        await orderController.cancelOrder(orderId, 'User request');

        // Assert
        verify(() => listener(
              OrderState.loaded([testOrder]), 
              OrderState.error('Cancellation failed'))).called(1);
      });
    });

    group('trackOrder', () {
      const orderId = 'order1';

      test('successful tracking info retrieval', () async {
        // Arrange
        final trackingInfo = TrackingInfo(
          orderId: orderId,
          currentStatus: OrderStatus.shipped,
          history: [
            TrackingEvent(
              status: OrderStatus.processing,
              timestamp: DateTime(2023, 1, 1),
            ),
          ],
          estimatedDelivery: DateTime(2023, 1, 10),
        );
        when(() => mockOrderRepository.getTrackingInfo(orderId))
            .thenAnswer((_) async => trackingInfo);

        orderController.addListener(listener);

        // Act
        await orderController.trackOrder(orderId);

        // Assert
        verifyInOrder([
          () => listener(null, const OrderState.loadingTracking()),
          () => listener(const OrderState.loadingTracking(), 
                OrderState.trackingLoaded(trackingInfo)),
        ]);
      });
    });

    group('real-time order updates', () {
      test('order status change notification', () async {
        // Arrange
        final streamController = StreamController<Order>.broadcast();
        when(() => mockOrderRepository.orderStream('user1'))
            .thenAnswer((_) => streamController.stream);

        // Preload orders
        orderController.state = OrderState.loaded([testOrder]);
        orderController.addListener(listener);
        orderController.listenToOrderUpdates('user1');

        // Act
        final updatedOrder = testOrder.copyWith(status: OrderStatus.delivered);
        streamController.add(updatedOrder);

        // Wait for stream to process
        await Future.delayed(Duration.zero);

        // Assert
        verify(() => listener(
              OrderState.loaded([testOrder]), 
              OrderState.loaded([updatedOrder]))).called(1);
      });
    });

    group('filterOrders', () {
      test('filter by status', () async {
        // Arrange
        final processingOrder = testOrder.copyWith(status: OrderStatus.processing);
        final deliveredOrder = testOrder.copyWith(
          id: 'order2',
          status: OrderStatus.delivered,
        );
        final orders = [processingOrder, deliveredOrder];

        // Preload orders
        orderController.state = OrderState.loaded(orders);
        orderController.addListener(listener);

        // Act
        orderController.filterOrders(status: OrderStatus.delivered);

        // Assert
        verify(() => listener(
              OrderState.loaded(orders), 
              OrderState.loaded([deliveredOrder]))).called(1);
      });

      test('filter by date range', () async {
        // Arrange
        final recentOrder = testOrder.copyWith(
          id: 'order2',
          createdAt: DateTime(2023, 2, 1),
        );
        final orders = [testOrder, recentOrder];

        // Preload orders
        orderController.state = OrderState.loaded(orders);
        orderController.addListener(listener);

        // Act
        orderController.filterOrders(
          startDate: DateTime(2023, 1, 15),
          endDate: DateTime(2023, 2, 15),
        );

        // Assert
        verify(() => listener(
              OrderState.loaded(orders), 
              OrderState.loaded([recentOrder]))).called(1);
      });

      test('clear filters', () async {
        // Arrange
        final filteredOrder = testOrder.copyWith(status: OrderStatus.delivered);
        final allOrders = [testOrder, filteredOrder];

        // Preload filtered state
        orderController.state = OrderState.loaded([filteredOrder]);
        orderController.addListener(listener);

        // Act
        orderController.clearFilters(allOrders);

        // Assert
        verify(() => listener(
              OrderState.loaded([filteredOrder]), 
              OrderState.loaded(allOrders))).called(1);
      });
    });
  });
}