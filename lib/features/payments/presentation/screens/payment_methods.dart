 import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_flutter_app/features/payments/presentation/controllers/payment_controller.dart';
import 'package:my_flutter_app/features/payments/domain/models/payment_method.dart';
import 'package:my_flutter_app/core/utils/extensions.dart';
import 'package:my_flutter_app/core/routing/app_router.dart';
import 'package:my_flutter_app/widgets/shared/buttons.dart';

class PaymentMethodsScreen extends StatelessWidget {
  final double amount;
  final String orderId;

  const PaymentMethodsScreen({
    super.key,
    required this.amount,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context) {
    final PaymentController controller = Get.find();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Payment Method'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildAmountCard(amount),
            const SizedBox(height: 24),
            Expanded(
              child: Obx(() {
                final methods = controller.availableMethods;
                if (methods.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                return ListView.builder(
                  itemCount: methods.length,
                  itemBuilder: (context, index) {
                    final method = methods[index];
                    return _buildPaymentMethodCard(method, controller);
                  },
                );
              }),
            ),
            _buildContinueButton(controller),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountCard(double amount) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Total Amount',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              amount.toCurrency(),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard(
    PaymentMethod method,
    PaymentController controller,
  ) {
    final isSelected = controller.selectedMethod.value?.id == method.id;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: isSelected ? Colors.blue.shade50 : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? Colors.blue : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        leading: Icon(
          method.icon,
          color: isSelected ? Colors.blue : Colors.grey,
          size: 36,
        ),
        title: Text(
          method.name,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(method.description),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: Colors.blue)
            : null,
        onTap: () => controller.selectPaymentMethod(method),
      ),
    );
  }

  Widget _buildContinueButton(PaymentController controller) {
    return Obx(() {
      return PrimaryButton(
        text: 'Continue to Payment',
        isLoading: controller.isLoading.value,
        onPressed: () {
          if (controller.selectedMethod.value != null) {
            Get.toNamed(
              AppRoutes.paymentProcessing,
              arguments: {
                'amount': amount,
                'orderId': orderId,
              },
            );
          } else {
            Get.snackbar('Select Method', 'Please select a payment method');
          }
        },
      );
    });
  }
}

import 'package:equatable/equatable.dart';

class PaymentMethod extends Equatable {
  final String id;
  final String name;
  final String description;
  final String icon;
  final bool isEnabled;
  final PaymentMethodType type;

  const PaymentMethod({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.type,
    this.isEnabled = true,
  });

  factory PaymentMethod.mpesa() {
    return PaymentMethod(
      id: 'mpesa',
      name: 'M-Pesa',
      description: 'Pay via M-Pesa mobile money',
      icon: 'mobile',
      type: PaymentMethodType.mobileMoney,
    );
  }

  factory PaymentMethod.card() {
    return PaymentMethod(
      id: 'card',
      name: 'Credit/Debit Card',
      description: 'Pay with Visa or Mastercard',
      icon: 'credit_card',
      type: PaymentMethodType.card,
    );
  }

  factory PaymentMethod.bank() {
    return PaymentMethod(
      id: 'bank',
      name: 'Bank Transfer',
      description: 'Direct bank transfer',
      icon: 'account_balance',
      type: PaymentMethodType.bankTransfer,
    );
  }

  factory PaymentMethod.cash() {
    return PaymentMethod(
      id: 'cash',
      name: 'Cash on Delivery',
      description: 'Pay when you receive your order',
      icon: 'local_atm',
      type: PaymentMethodType.cash,
    );
  }

  @override
  List<Object?> get props => [id, name, description, icon, isEnabled, type];
}

enum PaymentMethodType {
  mobileMoney,
  card,
  bankTransfer,
  cash,
}