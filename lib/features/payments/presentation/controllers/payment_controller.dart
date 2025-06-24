import 'package:get/get.dart';
import 'package:my_flutter_app/features/payments/domain/models/payment_method.dart';
import 'package:my_flutter_app/features/payments/domain/models/payment_result.dart';
import 'package:my_flutter_app/features/payments/data/payment_repository.dart';
import 'package:my_flutter_app/services/network_client.dart';
import 'package:my_flutter_app/core/utils/logger.dart';

enum PaymentStatus {
  initial,
  processing,
  success,
  failed,
  requiresAction,
}

class PaymentController extends GetxController {
  final PaymentRepository _paymentRepository;
  final NetworkClient _networkClient;

  PaymentController(
    this._paymentRepository,
    this._networkClient,
  );

  final RxList<PaymentMethod> _availableMethods = <PaymentMethod>[].obs;
  final Rx<PaymentMethod?> _selectedMethod = Rx<PaymentMethod?>(null);
  final Rx<PaymentStatus> _paymentStatus = PaymentStatus.initial.obs;
  final RxString _errorMessage = ''.obs;
  final RxString _actionMessage = ''.obs;
  final RxBool _isLoading = false.obs;

  // Getters
  List<PaymentMethod> get availableMethods => _availableMethods;
  PaymentMethod? get selectedMethod => _selectedMethod.value;
  PaymentStatus get paymentStatus => _paymentStatus.value;
  String get errorMessage => _errorMessage.value;
  String get actionMessage => _actionMessage.value;
  bool get isLoading => _isLoading.value;

  @override
  void onInit() {
    super.onInit();
    _loadPaymentMethods();
  }

  Future<void> _loadPaymentMethods() async {
    try {
      _isLoading.value = true;
      final methods = await _paymentRepository.getAvailableMethods();
      _availableMethods.assignAll(methods);
    } catch (e) {
      Logger.error('Failed to load payment methods: $e');
      _availableMethods.assignAll([
        PaymentMethod.mpesa(),
        PaymentMethod.card(),
        PaymentMethod.bank(),
        PaymentMethod.cash(),
      ]);
    } finally {
      _isLoading.value = false;
    }
  }

  void selectPaymentMethod(PaymentMethod method) {
    _selectedMethod.value = method;
  }

  Future<void> processPayment({
    required double amount,
    required String orderId,
  }) async {
    if (selectedMethod == null) return;
    
    try {
      _paymentStatus.value = PaymentStatus.processing;
      _isLoading.value = true;
      _errorMessage.value = '';
      
      final result = await _paymentRepository.initiatePayment(
        method: selectedMethod!,
        amount: amount,
        orderId: orderId,
      );
      
      if (result.status == PaymentResultStatus.success) {
        _paymentStatus.value = PaymentStatus.success;
      } else if (result.status == PaymentResultStatus.requiresAction) {
        _actionMessage.value = result.actionMessage ?? 'Please complete the payment on your device';
        _paymentStatus.value = PaymentStatus.requiresAction;
      } else {
        _errorMessage.value = result.errorMessage ?? 'Payment failed';
        _paymentStatus.value = PaymentStatus.failed;
      }
    } catch (e) {
      Logger.error('Payment processing failed: $e');
      _errorMessage.value = 'An unexpected error occurred';
      _paymentStatus.value = PaymentStatus.failed;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> checkPaymentStatus(String orderId) async {
    try {
      _isLoading.value = true;
      final result = await _paymentRepository.checkPaymentStatus(orderId);
      
      if (result.status == PaymentResultStatus.success) {
        _paymentStatus.value = PaymentStatus.success;
      } else {
        _errorMessage.value = result.errorMessage ?? 'Payment not completed';
        _paymentStatus.value = PaymentStatus.failed;
      }
    } catch (e) {
      Logger.error('Payment status check failed: $e');
      _errorMessage.value = 'Failed to verify payment';
      _paymentStatus.value = PaymentStatus.failed;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> retryPayment({
    required double amount,
    required String orderId,
  }) async {
    _paymentStatus.value = PaymentStatus.initial;
    _errorMessage.value = '';
    await processPayment(amount: amount, orderId: orderId);
  }
}