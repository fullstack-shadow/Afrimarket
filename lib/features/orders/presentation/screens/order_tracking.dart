import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_flutter_app/features/orders/domain/models/order.dart';
import 'package:my_flutter_app/features/orders/presentation/controllers/order_controller.dart';
import 'package:my_flutter_app/core/utils/extensions.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:intl/intl.dart';

class OrderTrackingScreen extends StatelessWidget {
  final Order order = Get.arguments['order'];

  OrderTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${order.id.substring(0, 8)}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOrderSummary(),
            const SizedBox(height: 24),
            _buildTimeline(),
            const SizedBox(height: 24),
            if (order.trackingNumber != null) _buildTrackingInfo(),
            if (order.deliveryAddress != null) _buildDeliveryAddress(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Status:'),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Items:'),
                Text('${order.itemCount}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Amount:'),
                Text(
                  order.totalAmount.toCurrency(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Order Date:'),
                Text(DateFormat('MMM dd, yyyy - hh:mm a').format(order.createdAt)),
              ],
            ),
            if (order.paymentMethod != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Payment Method:'),
                  Text(order.paymentMethod!.capitalize()),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Order Timeline',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TimelineTile(
          alignment: TimelineAlign.manual,
          lineXY: 0.2,
          isFirst: true,
          indicatorStyle: IndicatorStyle(
            width: 20,
            color: order.status.index >= OrderStatus.pending.index
                ? Colors.green
                : Colors.grey,
          ),
          beforeLineStyle: const LineStyle(color: Colors.grey),
          endChild: _buildTimelineEvent(
            'Order Placed',
            order.createdAt,
            isActive: true,
          ),
        ),
        TimelineTile(
          alignment: TimelineAlign.manual,
          lineXY: 0.2,
          indicatorStyle: IndicatorStyle(
            width: 20,
            color: order.status.index >= OrderStatus.confirmed.index
                ? Colors.green
                : Colors.grey,
          ),
          beforeLineStyle: const LineStyle(color: Colors.grey),
          afterLineStyle: LineStyle(
            color: order.status.index > OrderStatus.confirmed.index
                ? Colors.green
                : Colors.grey,
          ),
          endChild: _buildTimelineEvent(
            'Order Confirmed',
            order.status.index >= OrderStatus.confirmed.index
                ? order.updatedAt ?? order.createdAt.add(const Duration(hours: 1))
                : null,
            isActive: order.status.index >= OrderStatus.confirmed.index,
          ),
        ),
        TimelineTile(
          alignment: TimelineAlign.manual,
          lineXY: 0.2,
          indicatorStyle: IndicatorStyle(
            width: 20,
            color: order.status.index >= OrderStatus.processing.index
                ? Colors.green
                : Colors.grey,
          ),
          beforeLineStyle: const LineStyle(color: Colors.grey),
          afterLineStyle: LineStyle(
            color: order.status.index > OrderStatus.processing.index
                ? Colors.green
                : Colors.grey,
          ),
          endChild: _buildTimelineEvent(
            'Processing',
            order.status.index >= OrderStatus.processing.index
                ? order.updatedAt ?? order.createdAt.add(const Duration(days: 1))
                : null,
            isActive: order.status.index >= OrderStatus.processing.index,
          ),
        ),
        TimelineTile(
          alignment: TimelineAlign.manual,
          lineXY: 0.2,
          indicatorStyle: IndicatorStyle(
            width: 20,
            color: order.status.index >= OrderStatus.shipped.index
                ? Colors.green
                : Colors.grey,
          ),
          beforeLineStyle: const LineStyle(color: Colors.grey),
          afterLineStyle: LineStyle(
            color: order.status.index > OrderStatus.shipped.index
                ? Colors.green
                : Colors.grey,
          ),
          endChild: _buildTimelineEvent(
            'Shipped',
            order.status.index >= OrderStatus.shipped.index
                ? order.updatedAt ?? order.createdAt.add(const Duration(days: 2))
                : null,
            isActive: order.status.index >= OrderStatus.shipped.index,
          ),
        ),
        TimelineTile(
          alignment: TimelineAlign.manual,
          lineXY: 0.2,
          isLast: true,
          indicatorStyle: IndicatorStyle(
            width: 20,
            color: order.status.index >= OrderStatus.delivered.index
                ? Colors.green
                : Colors.grey,
          ),
          beforeLineStyle: const LineStyle(color: Colors.grey),
          endChild: _buildTimelineEvent(
            'Delivered',
            order.status.index >= OrderStatus.delivered.index
                ? order.updatedAt ?? order.createdAt.add(const Duration(days: 3))
                : null,
            isActive: order.status.index >= OrderStatus.delivered.index,
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineEvent(String title, DateTime? date, {bool isActive = false}) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.black : Colors.grey,
            ),
          ),
          if (date != null)
            Text(
              DateFormat('MMM dd, yyyy - hh:mm a').format(date),
              style: TextStyle(
                color: isActive ? Colors.grey.shade600 : Colors.grey,
              ),
            ),
          if (date == null)
            Text(
              'Pending',
              style: TextStyle(color: Colors.grey.shade400),
            ),
        ],
      ),
    );
  }

  Widget _buildTrackingInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tracking Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tracking Number:'),
                Text(
                  order.trackingNumber!,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (order.status == OrderStatus.shipped)
              const Text(
                'Your order is on the way',
                style: TextStyle(color: Colors.green),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryAddress() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Delivery Address',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(order.deliveryAddress!),
            if (order.deliveryNotes != null) ...[
              const SizedBox(height: 8),
              Text(
                'Notes: ${order.deliveryNotes}',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ],
        ),
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