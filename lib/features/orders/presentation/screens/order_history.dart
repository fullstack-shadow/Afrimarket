import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_flutter_app/features/orders/presentation/controllers/order_controller.dart';
import 'package:my_flutter_app/features/orders/domain/models/order.dart';
import 'package:my_flutter_app/core/utils/extensions.dart';
import 'package:my_flutter_app/widgets/shared/empty_state.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

class OrderHistoryScreen extends StatelessWidget {
  final OrderController _controller = Get.find();

  OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Orders'),
          bottom: TabBar(
            isScrollable: true,
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Pending'),
              Tab(text: 'Processing'),
              Tab(text: 'Shipped'),
              Tab(text: 'Completed'),
            ],
          ),
        ),
        body: RefreshIndicator(
          onRefresh: _controller.refreshOrders,
          child: Obx(() {
            if (_controller.isLoading && _controller.orders.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (_controller.orders.isEmpty) {
              return EmptyState(
                icon: Icons.shopping_bag_outlined,
                title: 'No Orders Yet',
                subtitle: 'Your orders will appear here',
              );
            }

            return TabBarView(
              children: [
                _buildOrderList(_controller.orders),
                _buildOrderList(_controller.pendingOrders),
                _buildOrderList(_controller.processingOrders),
                _buildOrderList(_controller.shippedOrders),
                _buildOrderList(_controller.completedOrders),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildOrderList(List<Order> orders) {
    if (orders.isEmpty) {
      return EmptyState(
        icon: Icons.filter_alt_outlined,
        title: 'No Orders',
        subtitle: 'No orders match this filter',
      );
    }

    return ListView.builder(
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return _buildOrderCard(order);
      },
    );
  }

  Widget _buildOrderCard(Order order) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: InkWell(
        onTap: () => Get.toNamed('/orders/${order.id}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #${order.id.substring(0, 8)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Chip(
                    label: Text(
                      order.status.toString().split('.').last.capitalize(),
                      style: TextStyle(
                        color: _getStatusColor(order.status),
                      ),
                    ),
                    backgroundColor: _getStatusColor(order.status).withOpacity(0.1),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${order.itemCount} item${order.itemCount > 1 ? 's' : ''}',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              ...order.items.take(2).map(_buildOrderItem).toList(),
              if (order.items.length > 2)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    '+ ${order.items.length - 2} more item${order.items.length - 2 > 1 ? 's' : ''}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total: ${order.totalAmount.toCurrency()}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    DateFormat('MMM dd, yyyy').format(order.createdAt),
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
              if (order.isShipped && order.trackingNumber != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.local_shipping),
                    label: const Text('Track Order'),
                    onPressed: () => _controller.trackOrder(order.id),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderItem(OrderItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          if (item.imageUrl != null)
            CachedNetworkImage(
              imageUrl: item.imageUrl!,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            ),
          if (item.imageUrl == null)
            Container(
              width: 50,
              height: 50,
              color: Colors.grey.shade200,
              child: const Icon(Icons.shopping_bag),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${item.quantity} × ${item.unitPrice.toCurrency()}',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.blue;
      case OrderStatus.processing:
        return Colors.blue.shade800;
      case OrderStatus.shipped:
        return Colors.purple;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
      case OrderStatus.returned:
        return Colors.amber.shade800;
    }
  }
}