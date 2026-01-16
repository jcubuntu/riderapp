import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:riderapp/features/auth/data/repositories/auth_repository.dart';
import 'package:riderapp/features/auth/presentation/providers/auth_provider.dart';
import 'package:riderapp/features/auth/presentation/providers/auth_state.dart';
import 'package:riderapp/shared/models/user_model.dart';

import '../../../helpers/mock_classes.dart';
import '../../../helpers/test_helpers.dart';

void main() {
  late MockAuthRepository mockAuthRepository;

  setUpAll(() {
    registerFallbackValues();
  });

  setUp(() {
    mockAuthRepository = MockAuthRepository();

    // Setup default stub for hasStoredTokens (called in constructor)
    when(() => mockAuthRepository.hasStoredTokens())
        .thenAnswer((_) async => false);
  });

  group('AuthNotifier', () {
    group('Initial State', () {
      test('should start with AuthInitial state', () {
        final container = TestHelpers.createAuthContainer(
          mockAuthRepository: mockAuthRepository,
        );
        addTearDown(container.dispose);

        // Read the provider but don't wait for async operations
        final notifier = container.read(authProvider.notifier);

        // The state is initially AuthInitial before any async work
        expect(notifier.state, isA<AuthInitial>());
      });

      test('should transition to AuthUnauthenticated when no stored tokens', () async {
        when(() => mockAuthRepository.hasStoredTokens())
            .thenAnswer((_) async => false);

        final container = TestHelpers.createAuthContainer(
          mockAuthRepository: mockAuthRepository,
        );
        addTearDown(container.dispose);

        // Trigger initialization
        container.read(authProvider);

        // Wait for the initial auth check to complete
        await container.waitForState<AuthState>(
          authProvider,
          (state) => state is! AuthInitial,
        );

        final state = container.read(authProvider);
        expect(state, isA<AuthUnauthenticated>());
      });

      test('should attempt token refresh when stored tokens exist', () async {
        final testUser = _createTestUser();
        final authResult = AuthResult(
          user: testUser,
          accessToken: 'test-access-token',
          refreshToken: 'test-refresh-token',
        );

        when(() => mockAuthRepository.hasStoredTokens())
            .thenAnswer((_) async => true);
        when(() => mockAuthRepository.refreshTokens())
            .thenAnswer((_) async => authResult);

        final container = TestHelpers.createAuthContainer(
          mockAuthRepository: mockAuthRepository,
        );
        addTearDown(container.dispose);

        // Trigger initialization
        container.read(authProvider);

        // Wait for authentication to complete
        await container.waitForState<AuthState>(
          authProvider,
          (state) => state is AuthAuthenticated,
        );

        final state = container.read(authProvider);
        expect(state, isA<AuthAuthenticated>());
        expect((state as AuthAuthenticated).user.id, equals('user-1'));
      });
    });

    group('Login', () {
      test('should set AuthLoading state when login starts', () async {
        when(() => mockAuthRepository.hasStoredTokens())
            .thenAnswer((_) async => false);
        when(() => mockAuthRepository.login(
              phone: any(named: 'phone'),
              password: any(named: 'password'),
            )).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return AuthResult(user: _createTestUser());
        });

        final container = TestHelpers.createAuthContainer(
          mockAuthRepository: mockAuthRepository,
        );
        addTearDown(container.dispose);

        await container.pumpAndSettle();

        final notifier = container.read(authProvider.notifier);

        // Start login but don't await
        final loginFuture = notifier.login(
          phone: '0811111111',
          password: 'Test1234',
        );

        // Check loading state immediately after starting
        await container.pump();
        expect(container.read(authProvider), isA<AuthLoading>());

        // Wait for login to complete
        await loginFuture;
      });

      test('should set AuthAuthenticated state on successful login with approved user', () async {
        final testUser = _createTestUser(status: UserStatus.approved);
        final authResult = AuthResult(
          user: testUser,
          accessToken: 'test-access-token',
          refreshToken: 'test-refresh-token',
        );

        when(() => mockAuthRepository.hasStoredTokens())
            .thenAnswer((_) async => false);
        when(() => mockAuthRepository.login(
              phone: any(named: 'phone'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => authResult);

        final container = TestHelpers.createAuthContainer(
          mockAuthRepository: mockAuthRepository,
        );
        addTearDown(container.dispose);

        await container.pumpAndSettle();

        final notifier = container.read(authProvider.notifier);
        await notifier.login(phone: '0811111111', password: 'Test1234');

        final state = container.read(authProvider);
        expect(state, isA<AuthAuthenticated>());
        expect((state as AuthAuthenticated).user.phone, equals('0811111111'));
        expect(state.accessToken, equals('test-access-token'));
      });

      test('should set AuthPendingApproval state for pending user', () async {
        final testUser = _createTestUser(status: UserStatus.pending);
        final authResult = AuthResult(user: testUser);

        when(() => mockAuthRepository.hasStoredTokens())
            .thenAnswer((_) async => false);
        when(() => mockAuthRepository.login(
              phone: any(named: 'phone'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => authResult);

        final container = TestHelpers.createAuthContainer(
          mockAuthRepository: mockAuthRepository,
        );
        addTearDown(container.dispose);

        await container.pumpAndSettle();

        final notifier = container.read(authProvider.notifier);
        await notifier.login(phone: '0811111111', password: 'Test1234');

        final state = container.read(authProvider);
        expect(state, isA<AuthPendingApproval>());
        expect((state as AuthPendingApproval).user.status, equals(UserStatus.pending));
      });

      test('should set AuthRejected state for rejected user', () async {
        final testUser = _createTestUser(status: UserStatus.rejected);
        final authResult = AuthResult(user: testUser);

        when(() => mockAuthRepository.hasStoredTokens())
            .thenAnswer((_) async => false);
        when(() => mockAuthRepository.login(
              phone: any(named: 'phone'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => authResult);

        final container = TestHelpers.createAuthContainer(
          mockAuthRepository: mockAuthRepository,
        );
        addTearDown(container.dispose);

        await container.pumpAndSettle();

        final notifier = container.read(authProvider.notifier);
        await notifier.login(phone: '0811111111', password: 'Test1234');

        final state = container.read(authProvider);
        expect(state, isA<AuthRejected>());
      });

      test('should set AuthError state on login failure', () async {
        when(() => mockAuthRepository.hasStoredTokens())
            .thenAnswer((_) async => false);
        when(() => mockAuthRepository.login(
              phone: any(named: 'phone'),
              password: any(named: 'password'),
            )).thenThrow(AuthException(message: 'Invalid credentials'));

        final container = TestHelpers.createAuthContainer(
          mockAuthRepository: mockAuthRepository,
        );
        addTearDown(container.dispose);

        await container.pumpAndSettle();

        final notifier = container.read(authProvider.notifier);
        await notifier.login(phone: '0811111111', password: 'wrong');

        final state = container.read(authProvider);
        expect(state, isA<AuthError>());
        expect((state as AuthError).message, equals('Invalid credentials'));
      });

      test('should call repository login with correct parameters', () async {
        final testUser = _createTestUser();
        final authResult = AuthResult(user: testUser, accessToken: 'token');

        when(() => mockAuthRepository.hasStoredTokens())
            .thenAnswer((_) async => false);
        when(() => mockAuthRepository.login(
              phone: any(named: 'phone'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => authResult);

        final container = TestHelpers.createAuthContainer(
          mockAuthRepository: mockAuthRepository,
        );
        addTearDown(container.dispose);

        await container.pumpAndSettle();

        final notifier = container.read(authProvider.notifier);
        await notifier.login(phone: '0811111111', password: 'Test1234');

        verify(() => mockAuthRepository.login(
              phone: '0811111111',
              password: 'Test1234',
            )).called(1);
      });
    });

    group('Register', () {
      test('should set AuthPendingApproval state after successful registration', () async {
        final testUser = _createTestUser(status: UserStatus.pending);
        final authResult = AuthResult(user: testUser, requiresApproval: true);

        when(() => mockAuthRepository.hasStoredTokens())
            .thenAnswer((_) async => false);
        when(() => mockAuthRepository.register(
              password: any(named: 'password'),
              fullName: any(named: 'fullName'),
              phone: any(named: 'phone'),
              idCardNumber: any(named: 'idCardNumber'),
              affiliation: any(named: 'affiliation'),
              address: any(named: 'address'),
            )).thenAnswer((_) async => authResult);

        final container = TestHelpers.createAuthContainer(
          mockAuthRepository: mockAuthRepository,
        );
        addTearDown(container.dispose);

        await container.pumpAndSettle();

        final notifier = container.read(authProvider.notifier);
        await notifier.register(
          password: 'Test1234',
          fullName: 'Test User',
          phone: '0811111111',
          idCardNumber: '1234567890123',
          affiliation: 'Test Org',
          address: 'Test Address',
        );

        final state = container.read(authProvider);
        expect(state, isA<AuthPendingApproval>());
      });

      test('should set AuthError state on registration failure', () async {
        when(() => mockAuthRepository.hasStoredTokens())
            .thenAnswer((_) async => false);
        when(() => mockAuthRepository.register(
              password: any(named: 'password'),
              fullName: any(named: 'fullName'),
              phone: any(named: 'phone'),
              idCardNumber: any(named: 'idCardNumber'),
              affiliation: any(named: 'affiliation'),
              address: any(named: 'address'),
            )).thenThrow(AuthException(message: 'Phone already registered'));

        final container = TestHelpers.createAuthContainer(
          mockAuthRepository: mockAuthRepository,
        );
        addTearDown(container.dispose);

        await container.pumpAndSettle();

        final notifier = container.read(authProvider.notifier);
        await notifier.register(
          password: 'Test1234',
          fullName: 'Test User',
          phone: '0811111111',
          idCardNumber: '1234567890123',
          affiliation: 'Test Org',
          address: 'Test Address',
        );

        final state = container.read(authProvider);
        expect(state, isA<AuthError>());
        expect((state as AuthError).message, equals('Phone already registered'));
      });
    });

    group('Logout', () {
      test('should set AuthUnauthenticated state after logout', () async {
        final testUser = _createTestUser();
        final authResult = AuthResult(
          user: testUser,
          accessToken: 'token',
          refreshToken: 'refresh',
        );

        when(() => mockAuthRepository.hasStoredTokens())
            .thenAnswer((_) async => true);
        when(() => mockAuthRepository.refreshTokens())
            .thenAnswer((_) async => authResult);
        when(() => mockAuthRepository.logout()).thenAnswer((_) async {});

        final container = TestHelpers.createAuthContainer(
          mockAuthRepository: mockAuthRepository,
        );
        addTearDown(container.dispose);

        // Trigger initialization
        container.read(authProvider);

        // Wait for authentication to complete
        await container.waitForState<AuthState>(
          authProvider,
          (state) => state is AuthAuthenticated,
        );

        // Verify we're authenticated first
        expect(container.read(authProvider), isA<AuthAuthenticated>());

        final notifier = container.read(authProvider.notifier);
        await notifier.logout();

        final state = container.read(authProvider);
        expect(state, isA<AuthUnauthenticated>());
      });

      test('should call repository logout', () async {
        when(() => mockAuthRepository.hasStoredTokens())
            .thenAnswer((_) async => false);
        when(() => mockAuthRepository.logout()).thenAnswer((_) async {});

        final container = TestHelpers.createAuthContainer(
          mockAuthRepository: mockAuthRepository,
        );
        addTearDown(container.dispose);

        await container.pumpAndSettle();

        final notifier = container.read(authProvider.notifier);
        await notifier.logout();

        verify(() => mockAuthRepository.logout()).called(1);
      });

      test('should set AuthUnauthenticated even if logout API fails', () async {
        when(() => mockAuthRepository.hasStoredTokens())
            .thenAnswer((_) async => false);
        when(() => mockAuthRepository.logout()).thenThrow(Exception('Network error'));

        final container = TestHelpers.createAuthContainer(
          mockAuthRepository: mockAuthRepository,
        );
        addTearDown(container.dispose);

        await container.pumpAndSettle();

        final notifier = container.read(authProvider.notifier);
        await notifier.logout();

        final state = container.read(authProvider);
        expect(state, isA<AuthUnauthenticated>());
      });
    });

    group('Token Refresh', () {
      test('should authenticate user when token refresh succeeds', () async {
        final testUser = _createTestUser();
        final authResult = AuthResult(
          user: testUser,
          accessToken: 'new-access-token',
          refreshToken: 'new-refresh-token',
        );

        when(() => mockAuthRepository.hasStoredTokens())
            .thenAnswer((_) async => true);
        when(() => mockAuthRepository.refreshTokens())
            .thenAnswer((_) async => authResult);

        final container = TestHelpers.createAuthContainer(
          mockAuthRepository: mockAuthRepository,
        );
        addTearDown(container.dispose);

        // Trigger initialization
        container.read(authProvider);

        // Wait for authentication to complete
        await container.waitForState<AuthState>(
          authProvider,
          (state) => state is AuthAuthenticated,
        );

        final state = container.read(authProvider);
        expect(state, isA<AuthAuthenticated>());
        expect((state as AuthAuthenticated).accessToken, equals('new-access-token'));
      });

      test('should handle refresh failure gracefully', () async {
        when(() => mockAuthRepository.hasStoredTokens())
            .thenAnswer((_) async => true);
        when(() => mockAuthRepository.refreshTokens())
            .thenThrow(AuthException(message: 'Token expired'));
        when(() => mockAuthRepository.getStoredUserId())
            .thenAnswer((_) async => null);

        final container = TestHelpers.createAuthContainer(
          mockAuthRepository: mockAuthRepository,
        );
        addTearDown(container.dispose);

        // Trigger initialization
        container.read(authProvider);

        // Wait for state to transition from initial
        await container.waitForState<AuthState>(
          authProvider,
          (state) => state is! AuthInitial,
        );

        final state = container.read(authProvider);
        expect(state, isA<AuthUnauthenticated>());
      });
    });

    group('Update User', () {
      test('should update user in AuthAuthenticated state', () async {
        final testUser = _createTestUser();
        final authResult = AuthResult(
          user: testUser,
          accessToken: 'token',
          refreshToken: 'refresh',
        );

        when(() => mockAuthRepository.hasStoredTokens())
            .thenAnswer((_) async => true);
        when(() => mockAuthRepository.refreshTokens())
            .thenAnswer((_) async => authResult);

        final container = TestHelpers.createAuthContainer(
          mockAuthRepository: mockAuthRepository,
        );
        addTearDown(container.dispose);

        // Trigger initialization
        container.read(authProvider);

        // Wait for authentication to complete
        await container.waitForState<AuthState>(
          authProvider,
          (state) => state is AuthAuthenticated,
        );

        final notifier = container.read(authProvider.notifier);

        final updatedUser = testUser.copyWith(fullName: 'Updated Name');
        notifier.updateUser(updatedUser);

        final state = container.read(authProvider);
        expect(state, isA<AuthAuthenticated>());
        expect((state as AuthAuthenticated).user.fullName, equals('Updated Name'));
      });
    });

    group('Clear Error', () {
      test('should transition from AuthError to AuthUnauthenticated', () async {
        when(() => mockAuthRepository.hasStoredTokens())
            .thenAnswer((_) async => false);
        when(() => mockAuthRepository.login(
              phone: any(named: 'phone'),
              password: any(named: 'password'),
            )).thenThrow(AuthException(message: 'Error'));

        final container = TestHelpers.createAuthContainer(
          mockAuthRepository: mockAuthRepository,
        );
        addTearDown(container.dispose);

        await container.pumpAndSettle();

        final notifier = container.read(authProvider.notifier);
        await notifier.login(phone: '0811111111', password: 'wrong');

        expect(container.read(authProvider), isA<AuthError>());

        notifier.clearError();

        expect(container.read(authProvider), isA<AuthUnauthenticated>());
      });
    });
  });

  group('Derived Providers', () {
    group('currentUserProvider', () {
      test('should return user when authenticated', () async {
        final testUser = _createTestUser();
        final authResult = AuthResult(
          user: testUser,
          accessToken: 'token',
          refreshToken: 'refresh',
        );

        when(() => mockAuthRepository.hasStoredTokens())
            .thenAnswer((_) async => true);
        when(() => mockAuthRepository.refreshTokens())
            .thenAnswer((_) async => authResult);

        final container = TestHelpers.createAuthContainer(
          mockAuthRepository: mockAuthRepository,
        );

        // First access the auth provider to trigger initialization
        container.read(authProvider);
        await container.pumpAndSettle();

        final user = container.read(currentUserProvider);
        expect(user, isNotNull);
        expect(user!.id, equals('user-1'));

        container.dispose();
      });

      test('should return null when unauthenticated', () async {
        when(() => mockAuthRepository.hasStoredTokens())
            .thenAnswer((_) async => false);

        final container = TestHelpers.createAuthContainer(
          mockAuthRepository: mockAuthRepository,
        );

        // First access the auth provider to trigger initialization
        container.read(authProvider);
        await container.pumpAndSettle();

        final user = container.read(currentUserProvider);
        expect(user, isNull);

        container.dispose();
      });
    });

    group('isAuthenticatedProvider', () {
      test('should return true when authenticated', () async {
        final testUser = _createTestUser();
        final authResult = AuthResult(
          user: testUser,
          accessToken: 'token',
          refreshToken: 'refresh',
        );

        when(() => mockAuthRepository.hasStoredTokens())
            .thenAnswer((_) async => true);
        when(() => mockAuthRepository.refreshTokens())
            .thenAnswer((_) async => authResult);

        final container = TestHelpers.createAuthContainer(
          mockAuthRepository: mockAuthRepository,
        );

        // First access the auth provider to trigger initialization
        container.read(authProvider);
        await container.pumpAndSettle();

        expect(container.read(isAuthenticatedProvider), isTrue);

        container.dispose();
      });

      test('should return false when unauthenticated', () async {
        when(() => mockAuthRepository.hasStoredTokens())
            .thenAnswer((_) async => false);

        final container = TestHelpers.createAuthContainer(
          mockAuthRepository: mockAuthRepository,
        );

        // First access the auth provider to trigger initialization
        container.read(authProvider);
        await container.pumpAndSettle();

        expect(container.read(isAuthenticatedProvider), isFalse);

        container.dispose();
      });
    });

    group('userRoleProvider', () {
      test('should return user role when authenticated', () async {
        final testUser = _createTestUser(role: UserRole.police);
        final authResult = AuthResult(
          user: testUser,
          accessToken: 'token',
          refreshToken: 'refresh',
        );

        when(() => mockAuthRepository.hasStoredTokens())
            .thenAnswer((_) async => true);
        when(() => mockAuthRepository.refreshTokens())
            .thenAnswer((_) async => authResult);

        final container = TestHelpers.createAuthContainer(
          mockAuthRepository: mockAuthRepository,
        );

        // First access the auth provider to trigger initialization
        container.read(authProvider);
        await container.pumpAndSettle();

        expect(container.read(userRoleProvider), equals(UserRole.police));

        container.dispose();
      });

      test('should return null when unauthenticated', () async {
        when(() => mockAuthRepository.hasStoredTokens())
            .thenAnswer((_) async => false);

        final container = TestHelpers.createAuthContainer(
          mockAuthRepository: mockAuthRepository,
        );

        // First access the auth provider to trigger initialization
        container.read(authProvider);
        await container.pumpAndSettle();

        expect(container.read(userRoleProvider), isNull);

        container.dispose();
      });
    });
  });
}

/// Helper function to create test users
UserModel _createTestUser({
  String id = 'user-1',
  String phone = '0811111111',
  String fullName = 'Test User',
  UserRole role = UserRole.rider,
  UserStatus status = UserStatus.approved,
}) {
  return UserModel(
    id: id,
    phone: phone,
    fullName: fullName,
    role: role,
    status: status,
    createdAt: DateTime.now(),
  );
}
