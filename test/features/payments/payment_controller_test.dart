import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:afrimarket/features/payments/data/payment_repository.dart';
import 'package:afrimarket/features/payments/domain/models/payment.dart';
import 'package:afrimarket/features/payments/presentation/controllers/payment_controller.dart';
import 'package:afrimarket/features/auth/domain/models/user.dart';
import 'package:afrimarket/features/auth/presentation/controllers/auth_controller.dart';

class MockPaymentRepository extends Mock implements PaymentRepository {
  @override
  Future<Payment> initiateMpesaPayment({
    required String orderId,
    required double amount,
    required String phoneNumber,
  }) => throw UnimplementedError();
  
  @override
  Future<Payment> verifyPayment(String paymentId) => throw UnimplementedError();
  
  @override
  Future<List<Payment>> getPaymentHistory() => throw UnimplementedError();
}

class MockAuthController extends GetxController implements AuthController {
  @override
  User? get currentUser => const User(
    id: 'user1',
    email: 'test@example.com',
    name: 'Test User',
    isSeller: false,
    phoneVerified: true,
  );
  
  @override
  Future<void> signInWithEmailAndPassword({
    required String email, 
    required String password
  }) => throw UnimplementedError();
  
  @override
  Future<void> signOut() => throw UnimplementedError();
}

void main() {
  late PaymentController paymentController;
  late MockPaymentRepository mockPaymentRepository;
  late MockAuthController mockAuthController;

  const testPayment = Payment(
    id: 'pay1',
    amount: 100.0,
    currency: 'USD',
    status: PaymentStatus.pending,
    createdAt: DateTime(2023, 1, 1),
    orderId: 'order1',
  );

  setUp(() {
    mockPaymentRepository = MockPaymentRepository();
    mockAuthController = MockAuthController();
    
    Get.put<AuthController>(mockAuthController);
    
    paymentController = PaymentController(
      repository: mockPaymentRepository,
    );
    
    // Register fallback values for mocktail
    registerFallbackValue(testPayment);
  });
  
  tearDown(() {
    Get.reset();
  });

  group('PaymentController', () {
    test('initial state has empty payment history', () {
      expect(paymentController.payments, isEmpty);
      expect(paymentController.isLoading, isFalse);
    });

    group('initiatePayment', () {
      const orderId = 'order1';
      const amount = 100.0;
      const phoneNumber = '+254712345678';

      test('successful payment initiation', () async {
        // Arrange
        when(() => mockPaymentRepository.initiateMpesaPayment(
              orderId: orderId,
              amount: amount,
              phoneNumber: phoneNumber,
            )).thenAnswer((_) async => testPayment);

        // Act
        await paymentController.initiatePayment(
          orderId: orderId,
          amount: amount,
          phoneNumber: phoneNumber,
        );

        // Assert
        verifyInOrder([
          () => listener(null, const PaymentState.processing()),
          () => listener(const PaymentState.processing(), 
                PaymentState.initiated(testPayment)),
        ]);
      });

      test('payment failure', () async {
        // Arrange
        final exception = Exception('Payment failed');
        when(() => mockPaymentRepository.initiateMpesaPayment(
              orderId: orderId,
              amount: amount,
              phoneNumber: phoneNumber,
            )).thenThrow(exception);

        paymentController.addListener(listener);

        // Act
        await paymentController.initiatePayment(
          orderId: orderId,
          amount: amount,
          phoneNumber: phoneNumber,
        );

        // Assert
        verifyInOrder([
          () => listener(null, const PaymentState.processing()),
          () => listener(const PaymentState.processing(), 
                PaymentState.error('Payment failed')),
        ]);
      });
    });

    group('verifyPayment', () {
      const paymentId = 'pay1';

      test('successful payment verification', () async {
        // Arrange
        final completedPayment = testPayment.copyWith(
          status: PaymentStatus.completed,
        );
        when(() => mockPaymentRepository.verifyPayment(paymentId))
            .thenAnswer((_) async => completedPayment);

        // Set initial state
        paymentController.state = PaymentState.initiated(testPayment);
        paymentController.addListener(listener);

        // Act
        await paymentController.verifyPayment(paymentId);

        // Assert
        verifyInOrder([
          () => listener(PaymentState.initiated(testPayment), 
                const PaymentState.processing()),
          () => listener(const PaymentState.processing(), 
                PaymentState.completed(completedPayment)),
        ]);
      });

      test('payment verification failed', () async {
        // Arrange
        final failedPayment = testPayment.copyWith(
          status: PaymentStatus.failed,
          failureReason: 'Insufficient funds',
        );
        when(() => mockPaymentRepository.verifyPayment(paymentId))
            .thenAnswer((_) async => failedPayment);

        // Set initial state
        paymentController.state = PaymentState.initiated(testPayment);
        paymentController.addListener(listener);

        // Act
        await paymentController.verifyPayment(paymentId);

        // Assert
        verifyInOrder([
          () => listener(PaymentState.initiated(testPayment), 
                const PaymentState.processing()),
          () => listener(const PaymentState.processing(), 
                PaymentState.failed(failedPayment)),
        ]);
      });
    });

    group('retryPayment', () {
      const orderId = 'order1';
      const paymentId = 'pay1';

      test('successful retry', () async {
        // Arrange
        final retriedPayment = testPayment.copyWith(
          status: PaymentStatus.pending,
          retryCount: 1,
        );
        when(() => mockPaymentRepository.retryPayment(paymentId))
            .thenAnswer((_) async => retriedPayment);

        // Set initial state (failed payment)
        final failedPayment = testPayment.copyWith(
          status: PaymentStatus.failed,
        );
        paymentController.state = PaymentState.failed(failedPayment);
        paymentController.addListener(listener);

        // Act
        await paymentController.retryPayment(paymentId);

        // Assert
        verifyInOrder([
          () => listener(PaymentState.failed(failedPayment), 
                const PaymentState.processing()),
          () => listener(const PaymentState.processing(), 
                PaymentState.initiated(retriedPayment)),
        ]);
      });
    });

    group('paymentHistory', () {
      test('load payment history', () async {
        // Arrange
        final payments = [testPayment];
        when(() => mockPaymentRepository.getPaymentHistory())
            .thenAnswer((_) async => payments);

        paymentController.addListener(listener);

        // Act
        await paymentController.loadPaymentHistory();

        // Assert
        verifyInOrder([
          () => listener(null, const PaymentState.loadingHistory()),
          () => listener(const PaymentState.loadingHistory(), 
                PaymentState.historyLoaded(payments)),
        ]);
      });
    });
  });
}