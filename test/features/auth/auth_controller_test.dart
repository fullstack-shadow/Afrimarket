import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:afrimarket/features/auth/data/repositories/auth_repository.dart';
import 'package:afrimarket/features/auth/domain/models/user.dart';
import 'package:afrimarket/features/auth/presentation/controllers/auth_controller.dart';
import 'package:afrimarket/features/auth/presentation/state/auth_state.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class Listener<T> extends Mock {
  void call(T? previous, T next);
}

void main() {
  late AuthController authController;
  late MockAuthRepository mockAuthRepository;
  late Listener<AuthState> listener;

  const testUser = User(
    id: 'user1',
    email: 'test@example.com',
    name: 'Test User',
    isSeller: false,
    phoneVerified: false,
  );

  setUpAll(() {
    registerFallbackValue(AuthState.initial());
  });

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    authController = AuthController(authRepository: mockAuthRepository);
    listener = Listener<AuthState>();
  });

  group('AuthController', () {
    test('initial state is unauthenticated', () {
      expect(authController.state, equals(const AuthState.unauthenticated()));
    });

    group('signInWithEmailAndPassword', () {
      const email = 'test@example.com';
      const password = 'Password123!';

      test('successful login', () async {
        // Arrange
        when(() => mockAuthRepository.signInWithEmailAndPassword(
              email: email,
              password: password,
            )).thenAnswer((_) async => testUser);

        // Listen to state changes
        authController.addListener(listener);

        // Act
        await authController.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Assert
        verifyInOrder([
          // Initial loading state
          () => listener(null, const AuthState.loading()),
          // Successful authentication
          () => listener(const AuthState.loading(), 
                AuthState.authenticated(testUser)),
        ]);
        verifyNoMoreInteractions(listener);
        
        expect(authController.state, 
              equals(AuthState.authenticated(testUser)));
      });

      test('failed login', () async {
        // Arrange
        final exception = Exception('Invalid credentials');
        when(() => mockAuthRepository.signInWithEmailAndPassword(
              email: email,
              password: password,
            )).thenThrow(exception);

        authController.addListener(listener);

        // Act
        await authController.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Assert
        verifyInOrder([
          () => listener(null, const AuthState.loading()),
          () => listener(const AuthState.loading(), 
                AuthState.error('Invalid credentials')),
        ]);
        
        expect(authController.state, 
              equals(const AuthState.error('Invalid credentials')));
      });
    });

    group('signUpWithEmailAndPassword', () {
      const email = 'new@example.com';
      const password = 'SecurePass123!';
      const name = 'New User';

      test('successful signup', () async {
        // Arrange
        when(() => mockAuthRepository.signUpWithEmailAndPassword(
              email: email,
              password: password,
              name: name,
            )).thenAnswer((_) async => testUser.copyWith(email: email, name: name));

        authController.addListener(listener);

        // Act
        await authController.signUpWithEmailAndPassword(
          email: email,
          password: password,
          name: name,
        );

        // Assert
        verifyInOrder([
          () => listener(null, const AuthState.loading()),
          () => listener(const AuthState.loading(), 
                AuthState.authenticated(testUser.copyWith(email: email, name: name))),
        ]);
      });

      test('failed signup - email already in use', () async {
        // Arrange
        when(() => mockAuthRepository.signUpWithEmailAndPassword(
              email: email,
              password: password,
              name: name,
            )).thenThrow(const AuthException('Email already in use'));

        authController.addListener(listener);

        // Act
        await authController.signUpWithEmailAndPassword(
          email: email,
          password: password,
          name: name,
        );

        // Assert
        verifyInOrder([
          () => listener(null, const AuthState.loading()),
          () => listener(const AuthState.loading(), 
                const AuthState.error('Email already in use')),
        ]);
      });
    });

    group('signOut', () {
      test('successful signout', () async {
        // Arrange
        authController.state = AuthState.authenticated(testUser);
        when(() => mockAuthRepository.signOut()).thenAnswer((_) async {});

        authController.addListener(listener);

        // Act
        await authController.signOut();

        // Assert
        verifyInOrder([
          () => listener(AuthState.authenticated(testUser), const AuthState.loading()),
          () => listener(const AuthState.loading(), const AuthState.unauthenticated()),
        ]);
      });

      test('signout when not authenticated', () async {
        // Arrange
        authController.state = const AuthState.unauthenticated();
        
        // Act & Assert
        expect(() => authController.signOut(), throwsStateError);
      });
    });

    group('authStateChanges', () {
      test('emits authenticated when user logs in', () async {
        // Arrange
        when(() => mockAuthRepository.authStateChanges())
            .thenAnswer((_) => Stream.value(testUser));
        
        // Act
        authController.listenToAuthChanges();
        
        // Assert
        await expectLater(
          authController.stream,
          emitsInOrder([
            const AuthState.loading(),
            AuthState.authenticated(testUser),
          ]),
        );
      });

      test('emits unauthenticated when user logs out', () async {
        // Arrange
        final authStream = Stream<User?>.fromIterable([testUser, null]);
        when(() => mockAuthRepository.authStateChanges())
            .thenAnswer((_) => authStream);
        
        // Act
        authController.listenToAuthChanges();
        
        // Assert
        await expectLater(
          authController.stream,
          emitsInOrder([
            const AuthState.loading(),
            AuthState.authenticated(testUser),
            const AuthState.loading(),
            const AuthState.unauthenticated(),
          ]),
        );
      });
    });

    group('verifyPhoneNumber', () {
      const phone = '+254712345678';

      test('successful verification', () async {
        // Arrange
        when(() => mockAuthRepository.verifyPhoneNumber(phone))
            .thenAnswer((_) async => true);

        authController.addListener(listener);

        // Act
        await authController.verifyPhoneNumber(phone);

        // Assert
        verifyInOrder([
          () => listener(null, const AuthState.loading()),
          () => listener(const AuthState.loading(), 
                const AuthState.phoneVerificationSuccess()),
        ]);
      });
    });
  });
}