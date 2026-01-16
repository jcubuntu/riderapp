import 'package:flutter_test/flutter_test.dart';
import 'package:riderapp/features/incidents/domain/entities/incident.dart';

void main() {
  group('IncidentCategory', () {
    group('displayName', () {
      test('should return correct display name for intelligence', () {
        expect(IncidentCategory.intelligence.displayName, equals('Intelligence/Tips'));
      });

      test('should return correct display name for accident', () {
        expect(IncidentCategory.accident.displayName, equals('Accident'));
      });

      test('should return correct display name for general', () {
        expect(IncidentCategory.general.displayName, equals('General Assistance'));
      });
    });

    group('fromString', () {
      test('should parse intelligence', () {
        expect(IncidentCategory.fromString('intelligence'), equals(IncidentCategory.intelligence));
      });

      test('should parse accident', () {
        expect(IncidentCategory.fromString('accident'), equals(IncidentCategory.accident));
      });

      test('should parse general', () {
        expect(IncidentCategory.fromString('general'), equals(IncidentCategory.general));
      });

      test('should be case insensitive', () {
        expect(IncidentCategory.fromString('INTELLIGENCE'), equals(IncidentCategory.intelligence));
        expect(IncidentCategory.fromString('Accident'), equals(IncidentCategory.accident));
      });

      test('should default to general for unknown values', () {
        expect(IncidentCategory.fromString('unknown'), equals(IncidentCategory.general));
        expect(IncidentCategory.fromString(''), equals(IncidentCategory.general));
      });
    });
  });

  group('IncidentStatus', () {
    group('displayName', () {
      test('should return correct display name for pending', () {
        expect(IncidentStatus.pending.displayName, equals('Pending'));
      });

      test('should return correct display name for reviewing', () {
        expect(IncidentStatus.reviewing.displayName, equals('Under Review'));
      });

      test('should return correct display name for verified', () {
        expect(IncidentStatus.verified.displayName, equals('Verified'));
      });

      test('should return correct display name for resolved', () {
        expect(IncidentStatus.resolved.displayName, equals('Resolved'));
      });

      test('should return correct display name for rejected', () {
        expect(IncidentStatus.rejected.displayName, equals('Rejected'));
      });
    });

    group('fromString', () {
      test('should parse all status values', () {
        expect(IncidentStatus.fromString('pending'), equals(IncidentStatus.pending));
        expect(IncidentStatus.fromString('reviewing'), equals(IncidentStatus.reviewing));
        expect(IncidentStatus.fromString('verified'), equals(IncidentStatus.verified));
        expect(IncidentStatus.fromString('resolved'), equals(IncidentStatus.resolved));
        expect(IncidentStatus.fromString('rejected'), equals(IncidentStatus.rejected));
      });

      test('should be case insensitive', () {
        expect(IncidentStatus.fromString('PENDING'), equals(IncidentStatus.pending));
        expect(IncidentStatus.fromString('Resolved'), equals(IncidentStatus.resolved));
      });

      test('should default to pending for unknown values', () {
        expect(IncidentStatus.fromString('unknown'), equals(IncidentStatus.pending));
        expect(IncidentStatus.fromString(''), equals(IncidentStatus.pending));
      });
    });
  });

  group('IncidentPriority', () {
    group('displayName', () {
      test('should return correct display name for all priorities', () {
        expect(IncidentPriority.low.displayName, equals('Low'));
        expect(IncidentPriority.medium.displayName, equals('Medium'));
        expect(IncidentPriority.high.displayName, equals('High'));
        expect(IncidentPriority.critical.displayName, equals('Critical'));
      });
    });

    group('fromString', () {
      test('should parse all priority values', () {
        expect(IncidentPriority.fromString('low'), equals(IncidentPriority.low));
        expect(IncidentPriority.fromString('medium'), equals(IncidentPriority.medium));
        expect(IncidentPriority.fromString('high'), equals(IncidentPriority.high));
        expect(IncidentPriority.fromString('critical'), equals(IncidentPriority.critical));
      });

      test('should be case insensitive', () {
        expect(IncidentPriority.fromString('LOW'), equals(IncidentPriority.low));
        expect(IncidentPriority.fromString('Critical'), equals(IncidentPriority.critical));
      });

      test('should default to medium for unknown values', () {
        expect(IncidentPriority.fromString('unknown'), equals(IncidentPriority.medium));
        expect(IncidentPriority.fromString(''), equals(IncidentPriority.medium));
      });
    });
  });

  group('IncidentLocation', () {
    group('fromJson', () {
      test('should parse valid JSON with snake_case keys', () {
        final json = {
          'location_lat': '13.7563',
          'location_lng': '100.5018',
          'location_address': '123 Test Street',
          'location_province': 'Bangkok',
          'location_district': 'Bangrak',
        };

        final location = IncidentLocation.fromJson(json);

        expect(location.latitude, equals(13.7563));
        expect(location.longitude, equals(100.5018));
        expect(location.address, equals('123 Test Street'));
        expect(location.province, equals('Bangkok'));
        expect(location.district, equals('Bangrak'));
      });

      test('should parse valid JSON with camelCase keys', () {
        final json = {
          'locationLat': '13.7563',
          'locationLng': '100.5018',
          'locationAddress': '123 Test Street',
          'locationProvince': 'Bangkok',
          'locationDistrict': 'Bangrak',
        };

        final location = IncidentLocation.fromJson(json);

        expect(location.latitude, equals(13.7563));
        expect(location.longitude, equals(100.5018));
        expect(location.address, equals('123 Test Street'));
        expect(location.province, equals('Bangkok'));
        expect(location.district, equals('Bangrak'));
      });

      test('should handle null values', () {
        final json = <String, dynamic>{};

        final location = IncidentLocation.fromJson(json);

        expect(location.latitude, isNull);
        expect(location.longitude, isNull);
        expect(location.address, isNull);
        expect(location.province, isNull);
        expect(location.district, isNull);
      });

      test('should handle numeric lat/lng', () {
        final json = {
          'location_lat': 13.7563,
          'location_lng': 100.5018,
        };

        final location = IncidentLocation.fromJson(json);

        expect(location.latitude, equals(13.7563));
        expect(location.longitude, equals(100.5018));
      });
    });

    group('toJson', () {
      test('should serialize correctly', () {
        const location = IncidentLocation(
          latitude: 13.7563,
          longitude: 100.5018,
          address: '123 Test Street',
          province: 'Bangkok',
          district: 'Bangrak',
        );

        final json = location.toJson();

        expect(json['locationLat'], equals(13.7563));
        expect(json['locationLng'], equals(100.5018));
        expect(json['locationAddress'], equals('123 Test Street'));
        expect(json['locationProvince'], equals('Bangkok'));
        expect(json['locationDistrict'], equals('Bangrak'));
      });
    });

    group('hasCoordinates', () {
      test('should return true when both lat and lng are present', () {
        const location = IncidentLocation(
          latitude: 13.7563,
          longitude: 100.5018,
        );

        expect(location.hasCoordinates, isTrue);
      });

      test('should return false when latitude is null', () {
        const location = IncidentLocation(
          longitude: 100.5018,
        );

        expect(location.hasCoordinates, isFalse);
      });

      test('should return false when longitude is null', () {
        const location = IncidentLocation(
          latitude: 13.7563,
        );

        expect(location.hasCoordinates, isFalse);
      });

      test('should return false when both are null', () {
        const location = IncidentLocation();

        expect(location.hasCoordinates, isFalse);
      });
    });

    group('copyWith', () {
      test('should create copy with updated values', () {
        const location = IncidentLocation(
          latitude: 13.7563,
          longitude: 100.5018,
          address: '123 Test Street',
        );

        final updatedLocation = location.copyWith(
          address: 'Updated Address',
          province: 'New Province',
        );

        expect(updatedLocation.latitude, equals(13.7563));
        expect(updatedLocation.longitude, equals(100.5018));
        expect(updatedLocation.address, equals('Updated Address'));
        expect(updatedLocation.province, equals('New Province'));
      });
    });
  });

  group('IncidentAttachment', () {
    final testDate = DateTime(2024, 1, 15, 10, 30);
    final testDateString = '2024-01-15T10:30:00.000';

    group('fromJson', () {
      test('should parse valid JSON with snake_case keys', () {
        final json = {
          'id': 'att-123',
          'incident_id': 'inc-123',
          'file_name': 'photo.jpg',
          'file_path': '/uploads/photo.jpg',
          'file_url': 'https://example.com/photo.jpg',
          'file_type': 'image',
          'mime_type': 'image/jpeg',
          'file_size': 1024,
          'width': 800,
          'height': 600,
          'duration': null,
          'thumbnail_url': 'https://example.com/thumb.jpg',
          'description': 'Test description',
          'sort_order': 1,
          'is_primary': true,
          'uploaded_by': 'user-123',
          'created_at': testDateString,
        };

        final attachment = IncidentAttachment.fromJson(json);

        expect(attachment.id, equals('att-123'));
        expect(attachment.incidentId, equals('inc-123'));
        expect(attachment.fileName, equals('photo.jpg'));
        expect(attachment.filePath, equals('/uploads/photo.jpg'));
        expect(attachment.fileUrl, equals('https://example.com/photo.jpg'));
        expect(attachment.fileType, equals('image'));
        expect(attachment.mimeType, equals('image/jpeg'));
        expect(attachment.fileSize, equals(1024));
        expect(attachment.width, equals(800));
        expect(attachment.height, equals(600));
        expect(attachment.duration, isNull);
        expect(attachment.thumbnailUrl, equals('https://example.com/thumb.jpg'));
        expect(attachment.description, equals('Test description'));
        expect(attachment.sortOrder, equals(1));
        expect(attachment.isPrimary, isTrue);
        expect(attachment.uploadedBy, equals('user-123'));
      });

      test('should handle camelCase keys', () {
        final json = {
          'id': 'att-123',
          'incidentId': 'inc-123',
          'fileName': 'photo.jpg',
          'fileUrl': 'https://example.com/photo.jpg',
          'fileType': 'image',
          'createdAt': testDateString,
        };

        final attachment = IncidentAttachment.fromJson(json);

        expect(attachment.incidentId, equals('inc-123'));
        expect(attachment.fileName, equals('photo.jpg'));
      });

      test('should handle default values', () {
        final json = {
          'id': 'att-123',
          'created_at': testDateString,
        };

        final attachment = IncidentAttachment.fromJson(json);

        expect(attachment.incidentId, equals(''));
        expect(attachment.fileName, equals(''));
        expect(attachment.fileUrl, equals(''));
        expect(attachment.fileType, equals('image'));
        expect(attachment.sortOrder, equals(0));
        expect(attachment.isPrimary, isFalse);
      });
    });

    group('toJson', () {
      test('should serialize correctly', () {
        final attachment = IncidentAttachment(
          id: 'att-123',
          incidentId: 'inc-123',
          fileName: 'photo.jpg',
          fileUrl: 'https://example.com/photo.jpg',
          fileType: 'image',
          createdAt: testDate,
        );

        final json = attachment.toJson();

        expect(json['id'], equals('att-123'));
        expect(json['incidentId'], equals('inc-123'));
        expect(json['fileName'], equals('photo.jpg'));
        expect(json['fileUrl'], equals('https://example.com/photo.jpg'));
        expect(json['fileType'], equals('image'));
      });
    });

    group('type helpers', () {
      test('isImage should return true for image type', () {
        final attachment = IncidentAttachment(
          id: 'att-123',
          incidentId: 'inc-123',
          fileName: 'photo.jpg',
          fileUrl: 'https://example.com/photo.jpg',
          fileType: 'image',
          createdAt: testDate,
        );

        expect(attachment.isImage, isTrue);
        expect(attachment.isVideo, isFalse);
        expect(attachment.isDocument, isFalse);
      });

      test('isVideo should return true for video type', () {
        final attachment = IncidentAttachment(
          id: 'att-123',
          incidentId: 'inc-123',
          fileName: 'video.mp4',
          fileUrl: 'https://example.com/video.mp4',
          fileType: 'video',
          createdAt: testDate,
        );

        expect(attachment.isImage, isFalse);
        expect(attachment.isVideo, isTrue);
        expect(attachment.isDocument, isFalse);
      });

      test('isDocument should return true for document type', () {
        final attachment = IncidentAttachment(
          id: 'att-123',
          incidentId: 'inc-123',
          fileName: 'doc.pdf',
          fileUrl: 'https://example.com/doc.pdf',
          fileType: 'document',
          createdAt: testDate,
        );

        expect(attachment.isImage, isFalse);
        expect(attachment.isVideo, isFalse);
        expect(attachment.isDocument, isTrue);
      });
    });
  });

  group('Incident', () {
    final testDate = DateTime(2024, 1, 15, 10, 30);
    final testDateString = '2024-01-15T10:30:00.000';

    group('fromJson', () {
      test('should parse valid JSON with snake_case keys', () {
        final json = {
          'id': 'inc-123',
          'reported_by': 'user-123',
          'category': 'accident',
          'status': 'pending',
          'priority': 'high',
          'title': 'Test Incident',
          'description': 'Test description',
          'location_lat': '13.7563',
          'location_lng': '100.5018',
          'location_address': '123 Test Street',
          'incident_date': testDateString,
          'assigned_to': 'user-456',
          'assigned_at': testDateString,
          'reviewed_by': 'user-789',
          'reviewed_at': testDateString,
          'review_notes': 'Review notes',
          'resolved_by': null,
          'resolved_at': null,
          'resolution_notes': null,
          'is_anonymous': false,
          'view_count': 10,
          'created_at': testDateString,
          'updated_at': testDateString,
          'reporter_name': 'John Doe',
          'reporter_phone': '0811111111',
          'assignee_name': 'Officer Smith',
          'assignee_phone': '0822222222',
          'attachments': [],
        };

        final incident = Incident.fromJson(json);

        expect(incident.id, equals('inc-123'));
        expect(incident.reportedBy, equals('user-123'));
        expect(incident.category, equals(IncidentCategory.accident));
        expect(incident.status, equals(IncidentStatus.pending));
        expect(incident.priority, equals(IncidentPriority.high));
        expect(incident.title, equals('Test Incident'));
        expect(incident.description, equals('Test description'));
        expect(incident.location.latitude, equals(13.7563));
        expect(incident.location.longitude, equals(100.5018));
        expect(incident.isAnonymous, isFalse);
        expect(incident.viewCount, equals(10));
        expect(incident.reporterName, equals('John Doe'));
        expect(incident.assigneeName, equals('Officer Smith'));
      });

      test('should parse valid JSON with camelCase keys', () {
        final json = {
          'id': 'inc-123',
          'reportedBy': 'user-123',
          'category': 'intelligence',
          'status': 'reviewing',
          'priority': 'critical',
          'title': 'Test Incident',
          'description': 'Test description',
          'locationLat': '13.7563',
          'locationLng': '100.5018',
          'isAnonymous': true,
          'viewCount': 5,
          'createdAt': testDateString,
          'updatedAt': testDateString,
        };

        final incident = Incident.fromJson(json);

        expect(incident.reportedBy, equals('user-123'));
        expect(incident.category, equals(IncidentCategory.intelligence));
        expect(incident.status, equals(IncidentStatus.reviewing));
        expect(incident.priority, equals(IncidentPriority.critical));
        expect(incident.isAnonymous, isTrue);
        expect(incident.viewCount, equals(5));
      });

      test('should handle null optional values', () {
        final json = {
          'id': 'inc-123',
          'reported_by': 'user-123',
          'category': 'general',
          'status': 'pending',
          'priority': 'low',
          'title': 'Test',
          'description': 'Test',
          'created_at': testDateString,
          'updated_at': testDateString,
        };

        final incident = Incident.fromJson(json);

        expect(incident.assignedTo, isNull);
        expect(incident.reviewedBy, isNull);
        expect(incident.resolvedBy, isNull);
        expect(incident.incidentDate, isNull);
        expect(incident.reporterName, isNull);
      });

      test('should parse attachments', () {
        final json = {
          'id': 'inc-123',
          'reported_by': 'user-123',
          'category': 'accident',
          'status': 'pending',
          'priority': 'medium',
          'title': 'Test',
          'description': 'Test',
          'created_at': testDateString,
          'updated_at': testDateString,
          'attachments': [
            {
              'id': 'att-1',
              'incident_id': 'inc-123',
              'file_name': 'photo1.jpg',
              'file_url': 'https://example.com/photo1.jpg',
              'file_type': 'image',
              'created_at': testDateString,
            },
            {
              'id': 'att-2',
              'incident_id': 'inc-123',
              'file_name': 'photo2.jpg',
              'file_url': 'https://example.com/photo2.jpg',
              'file_type': 'image',
              'created_at': testDateString,
            },
          ],
        };

        final incident = Incident.fromJson(json);

        expect(incident.attachments.length, equals(2));
        expect(incident.attachments[0].id, equals('att-1'));
        expect(incident.attachments[1].id, equals('att-2'));
      });

      test('should default empty list for null attachments', () {
        final json = {
          'id': 'inc-123',
          'reported_by': 'user-123',
          'category': 'general',
          'status': 'pending',
          'priority': 'medium',
          'title': 'Test',
          'description': 'Test',
          'created_at': testDateString,
          'updated_at': testDateString,
          'attachments': null,
        };

        final incident = Incident.fromJson(json);

        expect(incident.attachments, isEmpty);
      });
    });

    group('toJson', () {
      test('should serialize correctly', () {
        final incident = Incident(
          id: 'inc-123',
          reportedBy: 'user-123',
          category: IncidentCategory.accident,
          status: IncidentStatus.pending,
          priority: IncidentPriority.high,
          title: 'Test Incident',
          description: 'Test description',
          location: const IncidentLocation(
            latitude: 13.7563,
            longitude: 100.5018,
            address: '123 Test Street',
          ),
          isAnonymous: false,
          viewCount: 10,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final json = incident.toJson();

        expect(json['id'], equals('inc-123'));
        expect(json['reportedBy'], equals('user-123'));
        expect(json['category'], equals('accident'));
        expect(json['status'], equals('pending'));
        expect(json['priority'], equals('high'));
        expect(json['title'], equals('Test Incident'));
        expect(json['description'], equals('Test description'));
        expect(json['locationLat'], equals(13.7563));
        expect(json['locationLng'], equals(100.5018));
        expect(json['isAnonymous'], isFalse);
        expect(json['viewCount'], equals(10));
      });

      test('should serialize attachments', () {
        final incident = Incident(
          id: 'inc-123',
          reportedBy: 'user-123',
          category: IncidentCategory.general,
          status: IncidentStatus.pending,
          priority: IncidentPriority.medium,
          title: 'Test',
          description: 'Test',
          location: const IncidentLocation(),
          createdAt: testDate,
          updatedAt: testDate,
          attachments: [
            IncidentAttachment(
              id: 'att-1',
              incidentId: 'inc-123',
              fileName: 'photo.jpg',
              fileUrl: 'https://example.com/photo.jpg',
              fileType: 'image',
              createdAt: testDate,
            ),
          ],
        );

        final json = incident.toJson();

        expect(json['attachments'], isA<List>());
        expect((json['attachments'] as List).length, equals(1));
      });
    });

    group('copyWith', () {
      test('should create copy with updated values', () {
        final incident = Incident(
          id: 'inc-123',
          reportedBy: 'user-123',
          category: IncidentCategory.general,
          status: IncidentStatus.pending,
          priority: IncidentPriority.medium,
          title: 'Test',
          description: 'Test',
          location: const IncidentLocation(),
          createdAt: testDate,
          updatedAt: testDate,
        );

        final updatedIncident = incident.copyWith(
          status: IncidentStatus.resolved,
          priority: IncidentPriority.high,
          title: 'Updated Title',
        );

        expect(updatedIncident.id, equals('inc-123'));
        expect(updatedIncident.status, equals(IncidentStatus.resolved));
        expect(updatedIncident.priority, equals(IncidentPriority.high));
        expect(updatedIncident.title, equals('Updated Title'));
        expect(updatedIncident.description, equals('Test'));
      });
    });

    group('status helpers', () {
      test('isOpen should return true for pending status', () {
        final incident = Incident(
          id: 'inc-123',
          reportedBy: 'user-123',
          category: IncidentCategory.general,
          status: IncidentStatus.pending,
          priority: IncidentPriority.medium,
          title: 'Test',
          description: 'Test',
          location: const IncidentLocation(),
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(incident.isOpen, isTrue);
        expect(incident.isClosed, isFalse);
      });

      test('isOpen should return true for reviewing status', () {
        final incident = Incident(
          id: 'inc-123',
          reportedBy: 'user-123',
          category: IncidentCategory.general,
          status: IncidentStatus.reviewing,
          priority: IncidentPriority.medium,
          title: 'Test',
          description: 'Test',
          location: const IncidentLocation(),
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(incident.isOpen, isTrue);
        expect(incident.isClosed, isFalse);
      });

      test('isClosed should return true for resolved status', () {
        final incident = Incident(
          id: 'inc-123',
          reportedBy: 'user-123',
          category: IncidentCategory.general,
          status: IncidentStatus.resolved,
          priority: IncidentPriority.medium,
          title: 'Test',
          description: 'Test',
          location: const IncidentLocation(),
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(incident.isOpen, isFalse);
        expect(incident.isClosed, isTrue);
      });

      test('isClosed should return true for rejected status', () {
        final incident = Incident(
          id: 'inc-123',
          reportedBy: 'user-123',
          category: IncidentCategory.general,
          status: IncidentStatus.rejected,
          priority: IncidentPriority.medium,
          title: 'Test',
          description: 'Test',
          location: const IncidentLocation(),
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(incident.isOpen, isFalse);
        expect(incident.isClosed, isTrue);
      });

      test('isAssigned should return true when assignedTo is set', () {
        final incident = Incident(
          id: 'inc-123',
          reportedBy: 'user-123',
          category: IncidentCategory.general,
          status: IncidentStatus.pending,
          priority: IncidentPriority.medium,
          title: 'Test',
          description: 'Test',
          location: const IncidentLocation(),
          assignedTo: 'user-456',
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(incident.isAssigned, isTrue);
      });

      test('isAssigned should return false when assignedTo is null', () {
        final incident = Incident(
          id: 'inc-123',
          reportedBy: 'user-123',
          category: IncidentCategory.general,
          status: IncidentStatus.pending,
          priority: IncidentPriority.medium,
          title: 'Test',
          description: 'Test',
          location: const IncidentLocation(),
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(incident.isAssigned, isFalse);
      });
    });

    group('displayReporterName', () {
      test('should return Anonymous when isAnonymous is true', () {
        final incident = Incident(
          id: 'inc-123',
          reportedBy: 'user-123',
          category: IncidentCategory.general,
          status: IncidentStatus.pending,
          priority: IncidentPriority.medium,
          title: 'Test',
          description: 'Test',
          location: const IncidentLocation(),
          isAnonymous: true,
          reporterName: 'John Doe',
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(incident.displayReporterName, equals('Anonymous'));
      });

      test('should return reporter name when not anonymous', () {
        final incident = Incident(
          id: 'inc-123',
          reportedBy: 'user-123',
          category: IncidentCategory.general,
          status: IncidentStatus.pending,
          priority: IncidentPriority.medium,
          title: 'Test',
          description: 'Test',
          location: const IncidentLocation(),
          isAnonymous: false,
          reporterName: 'John Doe',
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(incident.displayReporterName, equals('John Doe'));
      });

      test('should return Unknown when reporter name is null and not anonymous', () {
        final incident = Incident(
          id: 'inc-123',
          reportedBy: 'user-123',
          category: IncidentCategory.general,
          status: IncidentStatus.pending,
          priority: IncidentPriority.medium,
          title: 'Test',
          description: 'Test',
          location: const IncidentLocation(),
          isAnonymous: false,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(incident.displayReporterName, equals('Unknown'));
      });
    });

    group('equality', () {
      test('two incidents with same properties should be equal', () {
        final incident1 = Incident(
          id: 'inc-123',
          reportedBy: 'user-123',
          category: IncidentCategory.general,
          status: IncidentStatus.pending,
          priority: IncidentPriority.medium,
          title: 'Test',
          description: 'Test',
          location: const IncidentLocation(),
          createdAt: testDate,
          updatedAt: testDate,
        );

        final incident2 = Incident(
          id: 'inc-123',
          reportedBy: 'user-123',
          category: IncidentCategory.general,
          status: IncidentStatus.pending,
          priority: IncidentPriority.medium,
          title: 'Test',
          description: 'Test',
          location: const IncidentLocation(),
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(incident1, equals(incident2));
      });
    });
  });

  group('IncidentStats', () {
    group('fromJson', () {
      test('should parse valid JSON', () {
        final json = {
          'byCategory': {'accident': 5, 'intelligence': 3, 'general': 2},
          'byStatus': {'pending': 4, 'resolved': 6},
          'byPriority': {'high': 2, 'medium': 5, 'low': 3},
          'topProvinces': [
            {'province': 'Bangkok', 'count': 10},
            {'province': 'Chiang Mai', 'count': 5},
          ],
          'recentCount': {
            'last24h': 3,
            'last7d': 15,
            'last30d': 50,
            'total': 100,
          },
        };

        final stats = IncidentStats.fromJson(json);

        expect(stats.byCategory['accident'], equals(5));
        expect(stats.byStatus['pending'], equals(4));
        expect(stats.byPriority['high'], equals(2));
        expect(stats.topProvinces.length, equals(2));
        expect(stats.topProvinces[0].province, equals('Bangkok'));
        expect(stats.recentCount.last24h, equals(3));
        expect(stats.recentCount.total, equals(100));
      });

      test('should handle null values', () {
        final json = <String, dynamic>{};

        final stats = IncidentStats.fromJson(json);

        expect(stats.byCategory, isEmpty);
        expect(stats.byStatus, isEmpty);
        expect(stats.byPriority, isEmpty);
        expect(stats.topProvinces, isEmpty);
        expect(stats.recentCount.last24h, equals(0));
      });
    });
  });

  group('PaginatedIncidents', () {
    final testDate = DateTime(2024, 1, 15, 10, 30);
    final testDateString = '2024-01-15T10:30:00.000';

    group('fromJson', () {
      test('should parse valid JSON', () {
        final json = {
          'data': [
            {
              'id': 'inc-1',
              'reported_by': 'user-1',
              'category': 'accident',
              'status': 'pending',
              'priority': 'high',
              'title': 'Test 1',
              'description': 'Desc 1',
              'created_at': testDateString,
              'updated_at': testDateString,
            },
            {
              'id': 'inc-2',
              'reported_by': 'user-2',
              'category': 'general',
              'status': 'resolved',
              'priority': 'low',
              'title': 'Test 2',
              'description': 'Desc 2',
              'created_at': testDateString,
              'updated_at': testDateString,
            },
          ],
          'pagination': {
            'total': 50,
            'page': 1,
            'limit': 10,
            'totalPages': 5,
          },
        };

        final paginated = PaginatedIncidents.fromJson(json);

        expect(paginated.incidents.length, equals(2));
        expect(paginated.total, equals(50));
        expect(paginated.page, equals(1));
        expect(paginated.limit, equals(10));
        expect(paginated.totalPages, equals(5));
      });

      test('should handle empty data', () {
        final json = {
          'data': [],
          'pagination': {
            'total': 0,
            'page': 1,
            'limit': 10,
            'totalPages': 0,
          },
        };

        final paginated = PaginatedIncidents.fromJson(json);

        expect(paginated.incidents, isEmpty);
        expect(paginated.total, equals(0));
      });
    });

    group('pagination helpers', () {
      test('hasNextPage should return true when page < totalPages', () {
        const paginated = PaginatedIncidents(
          incidents: [],
          total: 50,
          page: 1,
          limit: 10,
          totalPages: 5,
        );

        expect(paginated.hasNextPage, isTrue);
      });

      test('hasNextPage should return false when page >= totalPages', () {
        const paginated = PaginatedIncidents(
          incidents: [],
          total: 50,
          page: 5,
          limit: 10,
          totalPages: 5,
        );

        expect(paginated.hasNextPage, isFalse);
      });

      test('hasPreviousPage should return true when page > 1', () {
        const paginated = PaginatedIncidents(
          incidents: [],
          total: 50,
          page: 2,
          limit: 10,
          totalPages: 5,
        );

        expect(paginated.hasPreviousPage, isTrue);
      });

      test('hasPreviousPage should return false when page <= 1', () {
        const paginated = PaginatedIncidents(
          incidents: [],
          total: 50,
          page: 1,
          limit: 10,
          totalPages: 5,
        );

        expect(paginated.hasPreviousPage, isFalse);
      });
    });
  });
}
