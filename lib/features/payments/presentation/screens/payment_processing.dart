import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_flutter_app/features/payments/presentation/controllers/payment_controller.dart';
import 'package:my_flutter_app/core/utils/extensions.dart';
import 'package:my_flutter_app/core/routing/app_router.dart';
import 'package:my_flutter_app/widgets/shared/buttons.dart';
import 'package:lottie/lottie.dart';

class PaymentProcessingScreen extends StatefulWidget {
  final double amount;
  final String orderId;

  const PaymentProcessingScreen({
    super.key,
    required this.amount,
    required this.orderId,
  });

  @override
  State<PaymentProcessingScreen> createState() => _PaymentProcessingScreenState();
}

class _PaymentProcessingScreenState extends State<PaymentProcessingScreen> {
  final PaymentController controller = Get.find();

  @override
  void initState() {
    super.initState();
    _initiatePayment();
  }

  Future<void> _initiatePayment() async {
    await controller.processPayment(
      amount: widget.amount,
      orderId: widget.orderId,
    );
  }

  Widget _buildPaymentStatus() {
    return Obx(() {
      switch (controller.paymentStatus.value) {
        case PaymentStatus.processing:
          return _buildProcessingState();
        case PaymentStatus.success:
          return _buildSuccessState();
        case PaymentStatus.failed:
          return _buildFailedState();
        case PaymentStatus.requiresAction:
          return _buildActionRequiredState();
        default:
          return _buildProcessingState();
      }
    });
  }

  Widget _buildProcessingState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Lottie.asset(
          'assets/lottie/payment_processing.json',
          width: 200,
          height: 200,
        ),
        const SizedBox(height: 24),
        const Text(
          'Processing your payment...',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        Text(
          'Please wait while we process your payment',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildSuccessState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Lottie.asset(
          'assets/lottie/payment_success.json',
          width: 200,
          height: 200,
        ),
        const SizedBox(height: 24),
        const Text(
          'Payment Successful!',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Text(
          'Your payment of ${widget.amount.toCurrency()} was processed successfully',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18),
        ),
        const SizedBox(height: 32),
        PrimaryButton(
          text: 'View Order Details',
          onPressed: () {
            Get.offAllNamed(AppRoutes.orderTracking, arguments: {
              'orderId': widget.orderId,
            });
          },
        ),
        TextButton(
          onPressed: () => Get.offAllNamed(AppRoutes.shopHome),
          child: const Text('Continue Shopping'),
        ),
      ],
    );
  }

  Widget _buildFailedState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Lottie.asset(
          'assets/lottie/payment_failed.json',
          width: 200,
          height: 200,
        ),
        const SizedBox(height: 24),
        const Text(
          'Payment Failed',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red),
        ),
        const SizedBox(height: 16),
        Obx(() => Text(
              controller.errorMessage.value,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            )),
        const SizedBox(height: 32),
        PrimaryButton(
          text: 'Try Again',
          onPressed: _initiatePayment,
        ),
        TextButton(
          onPressed: () => Get.toNamed(AppRoutes.paymentMethods, arguments: {
            'amount': widget.amount,
            'orderId': widget.orderId,
          }),
          child: const Text('Choose Different Method'),
        ),
      ],
    );
  }

  Widget _buildActionRequiredState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.phone_android, size: 100, color: Colors.blue),
        const SizedBox(height: 24),
        const Text(
          'Action Required',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Obx(() => Text(
              controller.actionMessage.value,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            )),
        const SizedBox(height: 32),
        PrimaryButton(
          text: 'I Have Completed the Action',
          onPressed: () => controller.checkPaymentStatus(widget.orderId),
        ),
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('Cancel Payment'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Processing'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _buildPaymentStatus(),
      ),
    );
  }
}