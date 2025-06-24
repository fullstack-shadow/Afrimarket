import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// Represents a payment transaction in the system
class Payment extends Equatable {
  final String id;
  final String orderId;
  final String userId;
  final double amount;
  final String currency;
  final PaymentStatus status;
  final PaymentMethod method;
  final DateTime createdAt;
  final DateTime? processedAt;
  final String? transactionId;
  final String? failureReason;
  final String? payerPhone;
  final String? payerName;

  const Payment({
    @required required this.id,
    @required required this.orderId,
    @required required this.userId,
    @required required this.amount,
    @required required this.currency,
    @required required this.status,
    @required required this.method,
    @required required this.createdAt,
    this.processedAt,
    this.transactionId,
    this.failureReason,
    this.payerPhone,
    this.payerName,
  });

  factory Payment.initiate({
    required String orderId,
    required String userId,
    required double amount,
    required PaymentMethod method,
    String? payerPhone,
    String? payerName,
  }) {
    return Payment(
      id: '',
      orderId: orderId,
      userId: userId,
      amount: amount,
      currency: 'KES', // Default to Kenyan Shilling
      status: PaymentStatus.pending,
      method: method,
      createdAt: DateTime.now(),
      payerPhone: payerPhone,
      payerName: payerName,
    );
  }

  Payment copyWith({
    String? id,
    String? orderId,
    String? userId,
    double? amount,
    String? currency,
    PaymentStatus? status,
    PaymentMethod? method,
    DateTime? createdAt,
    DateTime? processedAt,
    String? transactionId,
    String? failureReason,
    String? payerPhone,
    String? payerName,
  }) {
    return Payment(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      method: method ?? this.method,
      createdAt: createdAt ?? this.createdAt,
      processedAt: processedAt ?? this.processedAt,
      transactionId: transactionId ?? this.transactionId,
      failureReason: failureReason ?? this.failureReason,
      payerPhone: payerPhone ?? this.payerPhone,
      payerName: payerName ?? this.payerName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'userId': userId,
      'amount': amount,
      'currency': currency,
      'status': status.index,
      'method': method.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'processedAt': processedAt?.toIso8601String(),
      'transactionId': transactionId,
      'failureReason': failureReason,
      'payerPhone': payerPhone,
      'payerName': payerName,
    };
  }

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as String,
      orderId: json['orderId'] as String,
      userId: json['userId'] as String,
      amount: json['amount'] as double,
      currency: json['currency'] as String? ?? 'KES',
      status: PaymentStatus.values[json['status'] as int],
      method: PaymentMethod.fromJson(json['method'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
      processedAt: json['processedAt'] != null
          ? DateTime.parse(json['processedAt'] as String)
          : null,
      transactionId: json['transactionId'] as String?,
      failureReason: json['failureReason'] as String?,
      payerPhone: json['payerPhone'] as String?,
      payerName: json['payerName'] as String?,
    );
  }

  bool get isPending => status == PaymentStatus.pending;
  bool get isSuccessful => status == PaymentStatus.succeeded;
  bool get isFailed => status == PaymentStatus.failed;
  bool get isProcessing => status == PaymentStatus.processing;

  @override
  List<Object?> get props => [
        id,
        orderId,
        userId,
        amount,
        currency,
        status,
        method,
        createdAt,
        processedAt,
        transactionId,
        failureReason,
        payerPhone,
        payerName,
      ];
}

/// Represents a payment method
class PaymentMethod extends Equatable {
  final String id;
  final String name;
  final String description;
  final PaymentMethodType type;
  final bool isEnabled;
  final String? iconCode;

  const PaymentMethod({
    @required required this.id,
    @required required this.name,
    @required required this.description,
    @required required this.type,
    this.isEnabled = true,
    this.iconCode,
  });

  // Predefined payment methods for Africa
  factory PaymentMethod.mpesa() {
    return PaymentMethod(
      id: 'mpesa',
      name: 'M-Pesa',
      description: 'Mobile money payment via M-Pesa',
      type: PaymentMethodType.mobileMoney,
      iconCode: 'mobile',
    );
  }

  factory PaymentMethod.airtelMoney() {
    return PaymentMethod(
      id: 'airtel_money',
      name: 'Airtel Money',
      description: 'Mobile money payment via Airtel',
      type: PaymentMethodType.mobileMoney,
      iconCode: 'sim_card',
    );
  }

  factory PaymentMethod.creditCard() {
    return PaymentMethod(
      id: 'credit_card',
      name: 'Credit Card',
      description: 'Pay with Visa or Mastercard',
      type: PaymentMethodType.card,
      iconCode: 'credit_card',
    );
  }

  factory PaymentMethod.bankTransfer() {
    return PaymentMethod(
      id: 'bank_transfer',
      name: 'Bank Transfer',
      description: 'Direct bank transfer',
      type: PaymentMethodType.bankTransfer,
      iconCode: 'account_balance',
    );
  }

  factory PaymentMethod.cashOnDelivery() {
    return PaymentMethod(
      id: 'cash_on_delivery',
      name: 'Cash on Delivery',
      description: 'Pay when you receive your order',
      type: PaymentMethodType.cash,
      iconCode: 'local_atm',
    );
  }

  PaymentMethod copyWith({
    String? id,
    String? name,
    String? description,
    PaymentMethodType? type,
    bool? isEnabled,
    String? iconCode,
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      isEnabled: isEnabled ?? this.isEnabled,
      iconCode: iconCode ?? this.iconCode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.index,
      'isEnabled': isEnabled,
      'iconCode': iconCode,
    };
  }

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      type: PaymentMethodType.values[json['type'] as int],
      isEnabled: json['isEnabled'] as bool? ?? true,
      iconCode: json['iconCode'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        type,
        isEnabled,
        iconCode,
      ];
}

/// Types of payment methods supported in Africa
enum PaymentMethodType {
  mobileMoney,
  card,
  bankTransfer,
  cash,
  voucher,
}

/// Status of a payment transaction
enum PaymentStatus {
  pending,      // Payment created but not processed
  processing,   // Payment is being processed
  succeeded,    // Payment completed successfully
  failed,       // Payment failed
  requiresAction, // Requires user action (e.g., M-Pesa PIN)
  refunded,     // Payment was refunded
}