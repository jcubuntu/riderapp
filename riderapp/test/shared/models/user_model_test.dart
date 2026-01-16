import 'package:flutter_test/flutter_test.dart';
import 'package:riderapp/shared/models/user_model.dart';

void main() {
  group('UserRole', () {
    group('displayName', () {
      test('should return correct display name for rider', () {
        expect(UserRole.rider.displayName, equals('Rider'));
      });

      test('should return correct display name for volunteer', () {
        expect(UserRole.volunteer.displayName, equals('Volunteer'));
      });

      test('should return correct display name for police', () {
        expect(UserRole.police.displayName, equals('Police'));
      });

      test('should return correct display name for admin', () {
        expect(UserRole.admin.displayName, equals('Admin'));
      });

      test('should return correct display name for superAdmin', () {
        expect(UserRole.superAdmin.displayName, equals('Super Admin'));
      });
    });

    group('fromString', () {
      test('should parse rider', () {
        expect(UserRole.fromString('rider'), equals(UserRole.rider));
      });

      test('should parse volunteer', () {
        expect(UserRole.fromString('volunteer'), equals(UserRole.volunteer));
      });

      test('should parse police', () {
        expect(UserRole.fromString('police'), equals(UserRole.police));
      });

      test('should parse admin', () {
        expect(UserRole.fromString('admin'), equals(UserRole.admin));
      });

      test('should parse super_admin', () {
        expect(UserRole.fromString('super_admin'), equals(UserRole.superAdmin));
      });

      test('should be case insensitive', () {
        expect(UserRole.fromString('RIDER'), equals(UserRole.rider));
        expect(UserRole.fromString('Police'), equals(UserRole.police));
        expect(UserRole.fromString('SUPER_ADMIN'), equals(UserRole.superAdmin));
      });

      test('should default to rider for unknown values', () {
        expect(UserRole.fromString('unknown'), equals(UserRole.rider));
        expect(UserRole.fromString(''), equals(UserRole.rider));
      });
    });
  });

  group('UserStatus', () {
    group('displayName', () {
      test('should return correct display name for pending', () {
        expect(UserStatus.pending.displayName, equals('Pending Approval'));
      });

      test('should return correct display name for approved', () {
        expect(UserStatus.approved.displayName, equals('Approved'));
      });

      test('should return correct display name for rejected', () {
        expect(UserStatus.rejected.displayName, equals('Rejected'));
      });

      test('should return correct display name for suspended', () {
        expect(UserStatus.suspended.displayName, equals('Suspended'));
      });
    });

    group('fromString', () {
      test('should parse pending', () {
        expect(UserStatus.fromString('pending'), equals(UserStatus.pending));
      });

      test('should parse approved', () {
        expect(UserStatus.fromString('approved'), equals(UserStatus.approved));
      });

      test('should parse rejected', () {
        expect(UserStatus.fromString('rejected'), equals(UserStatus.rejected));
      });

      test('should parse suspended', () {
        expect(UserStatus.fromString('suspended'), equals(UserStatus.suspended));
      });

      test('should be case insensitive', () {
        expect(UserStatus.fromString('PENDING'), equals(UserStatus.pending));
        expect(UserStatus.fromString('Approved'), equals(UserStatus.approved));
      });

      test('should default to pending for unknown values', () {
        expect(UserStatus.fromString('unknown'), equals(UserStatus.pending));
        expect(UserStatus.fromString(''), equals(UserStatus.pending));
      });
    });
  });

  group('UserModel', () {
    final testDate = DateTime(2024, 1, 15, 10, 30);
    final testDateString = '2024-01-15T10:30:00.000';

    group('fromJson', () {
      test('should parse valid JSON with snake_case keys', () {
        final json = {
          'id': 'user-123',
          'phone': '0811111111',
          'full_name': 'Test User',
          'id_card_number': '1234567890123',
          'affiliation': 'Test Company',
          'address': '123 Test Street',
          'role': 'rider',
          'status': 'approved',
          'profile_image_url': 'https://example.com/image.jpg',
          'approved_at': testDateString,
          'created_at': testDateString,
          'last_login_at': testDateString,
        };

        final user = UserModel.fromJson(json);

        expect(user.id, equals('user-123'));
        expect(user.phone, equals('0811111111'));
        expect(user.fullName, equals('Test User'));
        expect(user.idCardNumber, equals('1234567890123'));
        expect(user.affiliation, equals('Test Company'));
        expect(user.address, equals('123 Test Street'));
        expect(user.role, equals(UserRole.rider));
        expect(user.status, equals(UserStatus.approved));
        expect(user.profileImageUrl, equals('https://example.com/image.jpg'));
        expect(user.approvedAt, isNotNull);
        expect(user.createdAt, isNotNull);
        expect(user.lastLoginAt, isNotNull);
      });

      test('should parse valid JSON with camelCase keys', () {
        final json = {
          'id': 'user-123',
          'phone': '0811111111',
          'fullName': 'Test User',
          'idCardNumber': '1234567890123',
          'role': 'police',
          'status': 'pending',
          'profileImageUrl': 'https://example.com/image.jpg',
          'approvedAt': testDateString,
          'createdAt': testDateString,
          'lastLoginAt': testDateString,
        };

        final user = UserModel.fromJson(json);

        expect(user.fullName, equals('Test User'));
        expect(user.idCardNumber, equals('1234567890123'));
        expect(user.role, equals(UserRole.police));
        expect(user.status, equals(UserStatus.pending));
        expect(user.profileImageUrl, equals('https://example.com/image.jpg'));
      });

      test('should handle null optional values', () {
        final json = {
          'id': 'user-123',
          'phone': '0811111111',
          'full_name': 'Test User',
          'role': 'rider',
          'status': 'pending',
          'created_at': testDateString,
        };

        final user = UserModel.fromJson(json);

        expect(user.idCardNumber, isNull);
        expect(user.affiliation, isNull);
        expect(user.address, isNull);
        expect(user.profileImageUrl, isNull);
        expect(user.approvedAt, isNull);
        expect(user.lastLoginAt, isNull);
      });

      test('should default phone to empty string if null', () {
        final json = {
          'id': 'user-123',
          'full_name': 'Test User',
          'role': 'rider',
          'status': 'pending',
          'created_at': testDateString,
        };

        final user = UserModel.fromJson(json);

        expect(user.phone, equals(''));
      });

      test('should default role to rider if not provided', () {
        final json = {
          'id': 'user-123',
          'phone': '0811111111',
          'full_name': 'Test User',
          'status': 'pending',
          'created_at': testDateString,
        };

        final user = UserModel.fromJson(json);

        expect(user.role, equals(UserRole.rider));
      });

      test('should default status to pending if not provided', () {
        final json = {
          'id': 'user-123',
          'phone': '0811111111',
          'full_name': 'Test User',
          'role': 'rider',
          'created_at': testDateString,
        };

        final user = UserModel.fromJson(json);

        expect(user.status, equals(UserStatus.pending));
      });
    });

    group('toJson', () {
      test('should serialize correctly', () {
        final user = UserModel(
          id: 'user-123',
          phone: '0811111111',
          fullName: 'Test User',
          idCardNumber: '1234567890123',
          affiliation: 'Test Company',
          address: '123 Test Street',
          role: UserRole.admin,
          status: UserStatus.approved,
          profileImageUrl: 'https://example.com/image.jpg',
          approvedAt: testDate,
          createdAt: testDate,
          lastLoginAt: testDate,
        );

        final json = user.toJson();

        expect(json['id'], equals('user-123'));
        expect(json['phone'], equals('0811111111'));
        expect(json['full_name'], equals('Test User'));
        expect(json['id_card_number'], equals('1234567890123'));
        expect(json['affiliation'], equals('Test Company'));
        expect(json['address'], equals('123 Test Street'));
        expect(json['role'], equals('admin'));
        expect(json['status'], equals('approved'));
        expect(json['profile_image_url'], equals('https://example.com/image.jpg'));
        expect(json['approved_at'], isNotNull);
        expect(json['created_at'], isNotNull);
        expect(json['last_login_at'], isNotNull);
      });

      test('should serialize null values correctly', () {
        final user = UserModel(
          id: 'user-123',
          phone: '0811111111',
          fullName: 'Test User',
          role: UserRole.rider,
          status: UserStatus.pending,
          createdAt: testDate,
        );

        final json = user.toJson();

        expect(json['id_card_number'], isNull);
        expect(json['affiliation'], isNull);
        expect(json['address'], isNull);
        expect(json['profile_image_url'], isNull);
        expect(json['approved_at'], isNull);
        expect(json['last_login_at'], isNull);
      });
    });

    group('copyWith', () {
      test('should create copy with updated values', () {
        final user = UserModel(
          id: 'user-123',
          phone: '0811111111',
          fullName: 'Test User',
          role: UserRole.rider,
          status: UserStatus.pending,
          createdAt: testDate,
        );

        final updatedUser = user.copyWith(
          fullName: 'Updated User',
          role: UserRole.admin,
          status: UserStatus.approved,
        );

        expect(updatedUser.id, equals('user-123'));
        expect(updatedUser.phone, equals('0811111111'));
        expect(updatedUser.fullName, equals('Updated User'));
        expect(updatedUser.role, equals(UserRole.admin));
        expect(updatedUser.status, equals(UserStatus.approved));
      });

      test('should keep original values when not provided', () {
        final user = UserModel(
          id: 'user-123',
          phone: '0811111111',
          fullName: 'Test User',
          idCardNumber: '1234567890123',
          role: UserRole.rider,
          status: UserStatus.pending,
          createdAt: testDate,
        );

        final updatedUser = user.copyWith(fullName: 'Updated User');

        expect(updatedUser.id, equals('user-123'));
        expect(updatedUser.phone, equals('0811111111'));
        expect(updatedUser.idCardNumber, equals('1234567890123'));
        expect(updatedUser.role, equals(UserRole.rider));
        expect(updatedUser.status, equals(UserStatus.pending));
      });
    });

    group('role permissions', () {
      test('rider should have limited permissions', () {
        final user = UserModel(
          id: 'user-123',
          phone: '0811111111',
          fullName: 'Test Rider',
          role: UserRole.rider,
          status: UserStatus.approved,
          createdAt: testDate,
        );

        expect(user.isRider, isTrue);
        expect(user.isPolice, isFalse);
        expect(user.isAdmin, isFalse);
        expect(user.isVolunteer, isFalse);
        expect(user.isSuperAdmin, isFalse);
        expect(user.canApproveUsers, isFalse);
        expect(user.canManageUsers, isFalse);
        expect(user.canManageAdmins, isFalse);
        expect(user.canAccessSystemConfig, isFalse);
        expect(user.canCreateAnnouncements, isFalse);
      });

      test('volunteer should have limited permissions', () {
        final user = UserModel(
          id: 'user-123',
          phone: '0811111111',
          fullName: 'Test Volunteer',
          role: UserRole.volunteer,
          status: UserStatus.approved,
          createdAt: testDate,
        );

        expect(user.isRider, isFalse);
        expect(user.isVolunteer, isTrue);
        expect(user.canApproveUsers, isFalse);
        expect(user.canManageUsers, isFalse);
        expect(user.canManageAdmins, isFalse);
        expect(user.canAccessSystemConfig, isFalse);
        expect(user.canCreateAnnouncements, isFalse);
      });

      test('police should have approval permissions', () {
        final user = UserModel(
          id: 'user-123',
          phone: '0811111111',
          fullName: 'Test Police',
          role: UserRole.police,
          status: UserStatus.approved,
          createdAt: testDate,
        );

        expect(user.isPolice, isTrue);
        expect(user.canApproveUsers, isTrue);
        expect(user.canManageUsers, isFalse);
        expect(user.canManageAdmins, isFalse);
        expect(user.canAccessSystemConfig, isFalse);
        expect(user.canCreateAnnouncements, isTrue);
      });

      test('admin should have management permissions', () {
        final user = UserModel(
          id: 'user-123',
          phone: '0811111111',
          fullName: 'Test Admin',
          role: UserRole.admin,
          status: UserStatus.approved,
          createdAt: testDate,
        );

        expect(user.isAdmin, isTrue);
        expect(user.canApproveUsers, isTrue);
        expect(user.canManageUsers, isTrue);
        expect(user.canManageAdmins, isFalse);
        expect(user.canAccessSystemConfig, isFalse);
        expect(user.canCreateAnnouncements, isTrue);
      });

      test('super admin should have all permissions', () {
        final user = UserModel(
          id: 'user-123',
          phone: '0811111111',
          fullName: 'Test Super Admin',
          role: UserRole.superAdmin,
          status: UserStatus.approved,
          createdAt: testDate,
        );

        expect(user.isSuperAdmin, isTrue);
        expect(user.canApproveUsers, isTrue);
        expect(user.canManageUsers, isTrue);
        expect(user.canManageAdmins, isTrue);
        expect(user.canAccessSystemConfig, isTrue);
        expect(user.canCreateAnnouncements, isTrue);
      });
    });

    group('status helpers', () {
      test('isApproved should return true for approved status', () {
        final user = UserModel(
          id: 'user-123',
          phone: '0811111111',
          fullName: 'Test User',
          role: UserRole.rider,
          status: UserStatus.approved,
          createdAt: testDate,
        );

        expect(user.isApproved, isTrue);
        expect(user.isPending, isFalse);
      });

      test('isPending should return true for pending status', () {
        final user = UserModel(
          id: 'user-123',
          phone: '0811111111',
          fullName: 'Test User',
          role: UserRole.rider,
          status: UserStatus.pending,
          createdAt: testDate,
        );

        expect(user.isApproved, isFalse);
        expect(user.isPending, isTrue);
      });
    });

    group('equality', () {
      test('two users with same properties should be equal', () {
        final user1 = UserModel(
          id: 'user-123',
          phone: '0811111111',
          fullName: 'Test User',
          role: UserRole.rider,
          status: UserStatus.approved,
          createdAt: testDate,
        );

        final user2 = UserModel(
          id: 'user-123',
          phone: '0811111111',
          fullName: 'Test User',
          role: UserRole.rider,
          status: UserStatus.approved,
          createdAt: testDate,
        );

        expect(user1, equals(user2));
      });

      test('two users with different properties should not be equal', () {
        final user1 = UserModel(
          id: 'user-123',
          phone: '0811111111',
          fullName: 'Test User',
          role: UserRole.rider,
          status: UserStatus.approved,
          createdAt: testDate,
        );

        final user2 = UserModel(
          id: 'user-456',
          phone: '0822222222',
          fullName: 'Different User',
          role: UserRole.admin,
          status: UserStatus.pending,
          createdAt: testDate,
        );

        expect(user1, isNot(equals(user2)));
      });
    });
  });
}
