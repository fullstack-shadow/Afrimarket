import 'package:my_flutter_app/features/payments/domain/models/payment_method.dart';
import 'package:my_flutter_app/features/payments/domain/models/payment_result.dart';
import 'package:my_flutter_app/services/network_client.dart';
import 'package:my_flutter_app/core/utils/logger.dart';

abstract class PaymentRepository {
  Future<List<PaymentMethod>> getAvailableMethods();
  Future<PaymentResult> initiatePayment({
    required PaymentMethod method,
    required double amount,
    required String orderId,
  });
  Future<PaymentResult> checkPaymentStatus(String orderId);
}

class PaymentRepositoryImpl implements PaymentRepository {
  final NetworkClient _networkClient;

  PaymentRepositoryImpl(this._networkClient);

  @override
  Future<List<PaymentMethod>> getAvailableMethods() async {
    try {
      final response = await _networkClient.get('/payment/methods');
      return (response as List)
          .map((item) => PaymentMethod.fromJson(item))
          .toList();
    } catch (e) {
      Logger.error('Failed to fetch payment methods: $e');
      rethrow;
    }
  }

  @override
  Future<PaymentResult> initiatePayment({
    required PaymentMethod method,
    required double amount,
    required String orderId,
  }) async {
    try {
      final response = await _networkClient.post(
        '/payment/initiate',
        body: {
          'method': method.id,
          'amount': amount,
          'orderId': orderId,
        },
      );
      
      return PaymentResult.fromJson(response);
    } catch (e) {
      Logger.error('Payment initiation failed: $e');
      return PaymentResult.failure(
        errorMessage: 'Failed to initiate payment',
      );
    }
  }

  @override
  Future<PaymentResult> checkPaymentStatus(String orderId) async {
    try {
      final response = await _networkClient.get('/payment/status/$orderId');
      return PaymentResult.fromJson(response);
    } catch (e) {
      Logger.error('Payment status check failed: $e');
      return PaymentResult.failure(
        errorMessage: 'Failed to check payment status',
      );
    }
  }
}

// Add to PaymentMethod class
extension PaymentMethodJson on PaymentMethod {
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'isEnabled': isEnabled,
      'type': type.index,
    };
  }

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      isEnabled: json['isEnabled'] as bool? ?? true,
      type: PaymentMethodType.values[json['type'] as int],
    );
  }
}

// Add to PaymentResult class
class PaymentResult {
  final PaymentResultStatus status;
  final String? transactionId;
  final String? errorMessage;
  final String? actionMessage;

  PaymentResult({
    required this.status,
    this.transactionId,
    this.errorMessage,
    this.actionMessage,
  });

  factory PaymentResult.success({String? transactionId}) {
    return PaymentResult(
      status: PaymentResultStatus.success,
      transactionId: transactionId,
    );
  }

  factory PaymentResult.failure({String? errorMessage}) {
    return PaymentResult(
      status: PaymentResultStatus.failed,
      errorMessage: errorMessage,
    );
  }

  factory PaymentResult.actionRequired({String? actionMessage}) {
    return PaymentResult(
      status: PaymentResultStatus.requiresAction,
      actionMessage: actionMessage,
    );
  }

  factory PaymentResult.fromJson(Map<String, dynamic> json) {
    return PaymentResult(
      status: PaymentResultStatus.values[json['status'] as int],
      transactionId: json['transactionId'] as String?,
      errorMessage: json['errorMessage'] as String?,
      actionMessage: json['actionMessage'] as String?,
    );
  }
}

enum PaymentResultStatus {
  success,
  failed,
  requiresAction,
  pending,
}