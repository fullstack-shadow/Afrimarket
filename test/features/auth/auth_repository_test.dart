import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';
import 'package:afrimarket/core/exceptions/auth_exception.dart';
import 'package:afrimarket/features/auth/data/repositories/auth_repository.dart';
import 'package:afrimarket/features/auth/domain/models/user.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUserCredential extends Mock implements UserCredential {}
class MockUser extends Mock implements User {}
class MockGoogleSignIn extends Mock implements GoogleSignIn {}
class MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}
class MockGoogleSignInAuthentication extends Mock implements GoogleSignInAuthentication {}

void main() {
  late AuthRepository authRepository;
  late MockFirebaseAuth mockFirebaseAuth;
  late MockGoogleSignIn mockGoogleSignIn;
  late MockUser mockFirebaseUser;

  const testEmail = 'test@example.com';
  const testPassword = 'Password123!';
  const testName = 'Test User';
  const testPhone = '+254712345678';
  const testIdToken = 'test-id-token';
  const testAccessToken = 'test-access-token';

  setUp(() {
    mockFirebaseAuth = MockFirebaseAuth();
    mockGoogleSignIn = MockGoogleSignIn();
    mockFirebaseUser = MockUser();

    authRepository = AuthRepository(
      firebaseAuth: mockFirebaseAuth,
      googleSignIn: mockGoogleSignIn,
    );
  });

  group('AuthRepository', () {
    group('signInWithEmailAndPassword', () {
      test('successful login', () async {
        // Arrange
        final credential = MockUserCredential();
        when(() => credential.user).thenReturn(mockFirebaseUser);
        when(() => mockFirebaseUser.uid).thenReturn('user1');
        when(() => mockFirebaseUser.email).thenReturn(testEmail);
        when(() => mockFirebaseUser.displayName).thenReturn(testName);
        when(() => mockFirebaseUser.phoneNumber).thenReturn(testPhone);
        when(() => mockFirebaseUser.emailVerified).thenReturn(true);

        when(() => mockFirebaseAuth.signInWithEmailAndPassword(
              email: testEmail,
              password: testPassword,
            )).thenAnswer((_) async => credential);

        // Act
        final user = await authRepository.signInWithEmailAndPassword(
          email: testEmail,
          password: testPassword,
        );

        // Assert
        expect(user, isA<User>());
        expect(user.id, equals('user1'));
        expect(user.email, equals(testEmail));
        expect(user.name, equals(testName));
        expect(user.phoneNumber, equals(testPhone));
        expect(user.phoneVerified, isTrue);
      });

      test('invalid credentials', () async {
        // Arrange
        when(() => mockFirebaseAuth.signInWithEmailAndPassword(
              email: testEmail,
              password: testPassword,
            )).thenThrow(FirebaseAuthException(code: 'wrong-password'));

        // Act & Assert
        expect(
          () => authRepository.signInWithEmailAndPassword(
            email: testEmail,
            password: testPassword,
          ),
          throwsA(isA<AuthException>().having(
            (e) => e.message,
            'message',
            contains('Invalid email or password'),
          )),
        );
      });

      test('user not found', () async {
        // Arrange
        when(() => mockFirebaseAuth.signInWithEmailAndPassword(
              email: testEmail,
              password: testPassword,
            )).thenThrow(FirebaseAuthException(code: 'user-not-found'));

        // Act & Assert
        expect(
          () => authRepository.signInWithEmailAndPassword(
            email: testEmail,
            password: testPassword,
          ),
          throwsA(isA<AuthException>().having(
            (e) => e.message,
            'message',
            contains('No account found'),
          )),
        );
      });
    });

    group('signUpWithEmailAndPassword', () {
      test('successful signup', () async {
        // Arrange
        final credential = MockUserCredential();
        when(() => credential.user).thenReturn(mockFirebaseUser);
        when(() => mockFirebaseUser.uid).thenReturn('new-user');
        when(() => mockFirebaseUser.email).thenReturn(testEmail);
        
        when(() => mockFirebaseAuth.createUserWithEmailAndPassword(
              email: testEmail,
              password: testPassword,
            )).thenAnswer((_) async => credential);

        when(() => mockFirebaseUser.updateDisplayName(testName))
            .thenAnswer((_) async {});

        // Act
        final user = await authRepository.signUpWithEmailAndPassword(
          email: testEmail,
          password: testPassword,
          name: testName,
        );

        // Assert
        expect(user, isA<User>());
        expect(user.id, equals('new-user'));
        verify(() => mockFirebaseUser.updateDisplayName(testName)).called(1);
      });

      test('weak password', () async {
        // Arrange
        when(() => mockFirebaseAuth.createUserWithEmailAndPassword(
              email: testEmail,
              password: testPassword,
            )).thenThrow(FirebaseAuthException(code: 'weak-password'));

        // Act & Assert
        expect(
          () => authRepository.signUpWithEmailAndPassword(
            email: testEmail,
            password: testPassword,
            name: testName,
          ),
          throwsA(isA<AuthException>().having(
            (e) => e.message,
            'message',
            contains('Password is too weak'),
          )),
        );
      });
    });

    group('signInWithGoogle', () {
      test('successful google signin', () async {
        // Arrange
        final googleAccount = MockGoogleSignInAccount();
        final googleAuth = MockGoogleSignInAuthentication();
        final credential = MockUserCredential();

        when(() => mockGoogleSignIn.signIn())
            .thenAnswer((_) async => googleAccount);
        when(() => googleAccount.authentication)
            .thenAnswer((_) async => googleAuth);
        when(() => googleAuth.idToken).thenReturn(testIdToken);
        when(() => googleAuth.accessToken).thenReturn(testAccessToken);
        when(() => mockFirebaseAuth.signInWithCredential(any()))
            .thenAnswer((_) async => credential);
        when(() => credential.user).thenReturn(mockFirebaseUser);
        when(() => mockFirebaseUser.uid).thenReturn('google-user');
        when(() => mockFirebaseUser.email).thenReturn(testEmail);
        when(() => mockFirebaseUser.displayName).thenReturn('Google User');

        // Act
        final user = await authRepository.signInWithGoogle();

        // Assert
        expect(user, isA<User>());
        expect(user.id, equals('google-user'));
        verify(() => mockGoogleSignIn.signIn()).called(1);
      });

      test('google signin cancelled', () async {
        // Arrange
        when(() => mockGoogleSignIn.signIn()).thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => authRepository.signInWithGoogle(),
          throwsA(isA<AuthException>().having(
            (e) => e.message,
            'message',
            contains('Sign in cancelled'),
          )),
        );
      });
    });

    group('verifyPhoneNumber', () {
      test('successful verification', () async {
        // Arrange
        final credential = MockUserCredential();
        when(() => mockFirebaseAuth.verifyPhoneNumber(
              phoneNumber: testPhone,
              verificationCompleted: any(named: 'verificationCompleted'),
              verificationFailed: any(named: 'verificationFailed'),
              codeSent: any(named: 'codeSent'),
              codeAutoRetrievalTimeout: any(named: 'codeAutoRetrievalTimeout'),
            )).thenAnswer((invocation) {
          // Trigger verification completed
          final onCompleted = invocation
              .namedArguments[#verificationCompleted] as PhoneAuthCredential;
          return Future.value();
        });

        // Act
        final result = await authRepository.verifyPhoneNumber(testPhone);

        // Assert
        expect(result, isTrue);
      });
    });

    group('authStateChanges', () {
      test('emits user when authenticated', () {
        // Arrange
        when(() => mockFirebaseAuth.authStateChanges())
            .thenAnswer((_) => Stream.value(mockFirebaseUser));
        when(() => mockFirebaseUser.uid).thenReturn('user1');
        when(() => mockFirebaseUser.email).thenReturn(testEmail);

        // Act & Assert
        expect(
          authRepository.authStateChanges(),
          emitsThrough(isA<User>()),
        );
      });

      test('emits null when unauthenticated', () {
        // Arrange
        when(() => mockFirebaseAuth.authStateChanges())
            .thenAnswer((_) => Stream.value(null));

        // Act & Assert
        expect(
          authRepository.authStateChanges(),
          emitsThrough(null),
        );
      });
    });
  });
}