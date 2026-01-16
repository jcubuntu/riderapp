import 'package:flutter_test/flutter_test.dart';
import 'package:riderapp/shared/models/affiliation_model.dart';

void main() {
  group('AffiliationModel', () {
    final testDate = DateTime(2024, 1, 15, 10, 30);
    final testDateString = '2024-01-15T10:30:00.000';

    group('fromJson', () {
      test('should parse valid JSON with snake_case keys', () {
        final json = {
          'id': 'aff-123',
          'name': 'Test Company',
          'description': 'A test company description',
          'is_active': true,
          'created_at': testDateString,
          'updated_at': testDateString,
        };

        final affiliation = AffiliationModel.fromJson(json);

        expect(affiliation.id, equals('aff-123'));
        expect(affiliation.name, equals('Test Company'));
        expect(affiliation.description, equals('A test company description'));
        expect(affiliation.isActive, isTrue);
        expect(affiliation.createdAt, isNotNull);
        expect(affiliation.updatedAt, isNotNull);
      });

      test('should parse valid JSON with camelCase keys', () {
        final json = {
          'id': 'aff-123',
          'name': 'Test Company',
          'description': 'Description',
          'isActive': true,
          'createdAt': testDateString,
          'updatedAt': testDateString,
        };

        final affiliation = AffiliationModel.fromJson(json);

        expect(affiliation.name, equals('Test Company'));
        expect(affiliation.isActive, isTrue);
        expect(affiliation.createdAt, isNotNull);
        expect(affiliation.updatedAt, isNotNull);
      });

      test('should handle is_active as boolean true', () {
        final json = {
          'id': 'aff-123',
          'name': 'Test Company',
          'is_active': true,
          'created_at': testDateString,
        };

        final affiliation = AffiliationModel.fromJson(json);

        expect(affiliation.isActive, isTrue);
      });

      test('should handle is_active as boolean false', () {
        final json = {
          'id': 'aff-123',
          'name': 'Test Company',
          'is_active': false,
          'created_at': testDateString,
        };

        final affiliation = AffiliationModel.fromJson(json);

        expect(affiliation.isActive, isFalse);
      });

      test('should handle is_active as int 1', () {
        final json = {
          'id': 'aff-123',
          'name': 'Test Company',
          'is_active': 1,
          'created_at': testDateString,
        };

        final affiliation = AffiliationModel.fromJson(json);

        expect(affiliation.isActive, isTrue);
      });

      test('should handle is_active as int 0', () {
        final json = {
          'id': 'aff-123',
          'name': 'Test Company',
          'is_active': 0,
          'created_at': testDateString,
        };

        final affiliation = AffiliationModel.fromJson(json);

        expect(affiliation.isActive, isFalse);
      });

      test('should default is_active to true when null', () {
        final json = {
          'id': 'aff-123',
          'name': 'Test Company',
          'is_active': null,
          'created_at': testDateString,
        };

        final affiliation = AffiliationModel.fromJson(json);

        expect(affiliation.isActive, isTrue);
      });

      test('should default is_active to true when not provided', () {
        final json = {
          'id': 'aff-123',
          'name': 'Test Company',
          'created_at': testDateString,
        };

        final affiliation = AffiliationModel.fromJson(json);

        expect(affiliation.isActive, isTrue);
      });

      test('should handle null description', () {
        final json = {
          'id': 'aff-123',
          'name': 'Test Company',
          'description': null,
          'created_at': testDateString,
        };

        final affiliation = AffiliationModel.fromJson(json);

        expect(affiliation.description, isNull);
      });

      test('should handle null updated_at', () {
        final json = {
          'id': 'aff-123',
          'name': 'Test Company',
          'created_at': testDateString,
          'updated_at': null,
        };

        final affiliation = AffiliationModel.fromJson(json);

        expect(affiliation.updatedAt, isNull);
      });

      test('should handle missing created_at by defaulting to now', () {
        final json = {
          'id': 'aff-123',
          'name': 'Test Company',
        };

        final beforeCreate = DateTime.now();
        final affiliation = AffiliationModel.fromJson(json);
        final afterCreate = DateTime.now();

        expect(affiliation.createdAt.isAfter(beforeCreate.subtract(const Duration(seconds: 1))), isTrue);
        expect(affiliation.createdAt.isBefore(afterCreate.add(const Duration(seconds: 1))), isTrue);
      });
    });

    group('toJson', () {
      test('should serialize correctly', () {
        final affiliation = AffiliationModel(
          id: 'aff-123',
          name: 'Test Company',
          description: 'A test company description',
          isActive: true,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final json = affiliation.toJson();

        expect(json['id'], equals('aff-123'));
        expect(json['name'], equals('Test Company'));
        expect(json['description'], equals('A test company description'));
        expect(json['is_active'], isTrue);
        expect(json['created_at'], isNotNull);
        expect(json['updated_at'], isNotNull);
      });

      test('should serialize null values correctly', () {
        final affiliation = AffiliationModel(
          id: 'aff-123',
          name: 'Test Company',
          isActive: true,
          createdAt: testDate,
        );

        final json = affiliation.toJson();

        expect(json['description'], isNull);
        expect(json['updated_at'], isNull);
      });

      test('should serialize isActive false correctly', () {
        final affiliation = AffiliationModel(
          id: 'aff-123',
          name: 'Test Company',
          isActive: false,
          createdAt: testDate,
        );

        final json = affiliation.toJson();

        expect(json['is_active'], isFalse);
      });
    });

    group('equality', () {
      test('two affiliations with same properties should be equal', () {
        final affiliation1 = AffiliationModel(
          id: 'aff-123',
          name: 'Test Company',
          description: 'Description',
          isActive: true,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final affiliation2 = AffiliationModel(
          id: 'aff-123',
          name: 'Test Company',
          description: 'Description',
          isActive: true,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(affiliation1, equals(affiliation2));
      });

      test('two affiliations with different properties should not be equal', () {
        final affiliation1 = AffiliationModel(
          id: 'aff-123',
          name: 'Test Company',
          createdAt: testDate,
        );

        final affiliation2 = AffiliationModel(
          id: 'aff-456',
          name: 'Different Company',
          createdAt: testDate,
        );

        expect(affiliation1, isNot(equals(affiliation2)));
      });

      test('affiliations with different isActive should not be equal', () {
        final affiliation1 = AffiliationModel(
          id: 'aff-123',
          name: 'Test Company',
          isActive: true,
          createdAt: testDate,
        );

        final affiliation2 = AffiliationModel(
          id: 'aff-123',
          name: 'Test Company',
          isActive: false,
          createdAt: testDate,
        );

        expect(affiliation1, isNot(equals(affiliation2)));
      });
    });

    group('constructor defaults', () {
      test('should default isActive to true', () {
        final affiliation = AffiliationModel(
          id: 'aff-123',
          name: 'Test Company',
          createdAt: testDate,
        );

        expect(affiliation.isActive, isTrue);
      });
    });

    group('props', () {
      test('should include all properties in props', () {
        final affiliation = AffiliationModel(
          id: 'aff-123',
          name: 'Test Company',
          description: 'Description',
          isActive: true,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(affiliation.props.length, equals(6));
        expect(affiliation.props, contains('aff-123'));
        expect(affiliation.props, contains('Test Company'));
        expect(affiliation.props, contains('Description'));
        expect(affiliation.props, contains(true));
        expect(affiliation.props, contains(testDate));
      });
    });
  });
}
