import 'package:flutter_test/flutter_test.dart';
import 'package:riderapp/features/notifications/domain/entities/app_notification.dart';

void main() {
  group('NotificationType', () {
    group('displayName', () {
      test('should return correct display name for chat', () {
        expect(NotificationType.chat.displayName, equals('Chat'));
      });

      test('should return correct display name for incident', () {
        expect(NotificationType.incident.displayName, equals('Incident'));
      });

      test('should return correct display name for announcement', () {
        expect(NotificationType.announcement.displayName, equals('Announcement'));
      });

      test('should return correct display name for sos', () {
        expect(NotificationType.sos.displayName, equals('SOS'));
      });

      test('should return correct display name for approval', () {
        expect(NotificationType.approval.displayName, equals('Approval'));
      });

      test('should return correct display name for system', () {
        expect(NotificationType.system.displayName, equals('System'));
      });
    });

    group('fromString', () {
      test('should parse chat', () {
        expect(NotificationType.fromString('chat'), equals(NotificationType.chat));
      });

      test('should parse incident', () {
        expect(NotificationType.fromString('incident'), equals(NotificationType.incident));
      });

      test('should parse announcement', () {
        expect(NotificationType.fromString('announcement'), equals(NotificationType.announcement));
      });

      test('should parse sos', () {
        expect(NotificationType.fromString('sos'), equals(NotificationType.sos));
      });

      test('should parse approval', () {
        expect(NotificationType.fromString('approval'), equals(NotificationType.approval));
      });

      test('should parse system', () {
        expect(NotificationType.fromString('system'), equals(NotificationType.system));
      });

      test('should be case insensitive', () {
        expect(NotificationType.fromString('CHAT'), equals(NotificationType.chat));
        expect(NotificationType.fromString('Incident'), equals(NotificationType.incident));
        expect(NotificationType.fromString('SOS'), equals(NotificationType.sos));
      });

      test('should default to system for unknown values', () {
        expect(NotificationType.fromString('unknown'), equals(NotificationType.system));
        expect(NotificationType.fromString(''), equals(NotificationType.system));
      });
    });
  });

  group('AppNotification', () {
    final testDate = DateTime(2024, 1, 15, 10, 30);
    final testDateString = '2024-01-15T10:30:00.000';

    group('fromJson', () {
      test('should parse valid JSON with snake_case keys', () {
        final json = {
          'id': 'notif-123',
          'title': 'New Message',
          'body': 'You have a new message from John',
          'type': 'chat',
          'target_id': 'conv-123',
          'is_read': true,
          'created_at': testDateString,
          'read_at': testDateString,
        };

        final notification = AppNotification.fromJson(json);

        expect(notification.id, equals('notif-123'));
        expect(notification.title, equals('New Message'));
        expect(notification.body, equals('You have a new message from John'));
        expect(notification.type, equals(NotificationType.chat));
        expect(notification.targetId, equals('conv-123'));
        expect(notification.isRead, isTrue);
        expect(notification.createdAt, isNotNull);
        expect(notification.readAt, isNotNull);
      });

      test('should parse valid JSON with camelCase keys', () {
        final json = {
          'id': 'notif-123',
          'title': 'New Incident',
          'body': 'A new incident has been reported',
          'type': 'incident',
          'targetId': 'inc-456',
          'isRead': false,
          'createdAt': testDateString,
          'readAt': testDateString,
        };

        final notification = AppNotification.fromJson(json);

        expect(notification.targetId, equals('inc-456'));
        expect(notification.type, equals(NotificationType.incident));
        expect(notification.isRead, isFalse);
      });

      test('should handle message key as fallback for body', () {
        final json = {
          'id': 'notif-123',
          'title': 'Alert',
          'message': 'This is a message fallback',
          'type': 'system',
          'created_at': testDateString,
        };

        final notification = AppNotification.fromJson(json);

        expect(notification.body, equals('This is a message fallback'));
      });

      test('should handle null optional values', () {
        final json = {
          'id': 'notif-123',
          'title': 'System Update',
          'body': 'The system will be updated',
          'type': 'system',
          'created_at': testDateString,
        };

        final notification = AppNotification.fromJson(json);

        expect(notification.targetId, isNull);
        expect(notification.isRead, isFalse);
        expect(notification.readAt, isNull);
      });

      test('should default title and body to empty strings', () {
        final json = {
          'id': 'notif-123',
          'type': 'system',
          'created_at': testDateString,
        };

        final notification = AppNotification.fromJson(json);

        expect(notification.title, equals(''));
        expect(notification.body, equals(''));
      });

      test('should default type to system if not provided', () {
        final json = {
          'id': 'notif-123',
          'title': 'Test',
          'body': 'Test body',
          'created_at': testDateString,
        };

        final notification = AppNotification.fromJson(json);

        expect(notification.type, equals(NotificationType.system));
      });
    });

    group('toJson', () {
      test('should serialize correctly', () {
        final notification = AppNotification(
          id: 'notif-123',
          title: 'New Message',
          body: 'You have a new message',
          type: NotificationType.chat,
          targetId: 'conv-123',
          isRead: true,
          createdAt: testDate,
          readAt: testDate,
        );

        final json = notification.toJson();

        expect(json['id'], equals('notif-123'));
        expect(json['title'], equals('New Message'));
        expect(json['body'], equals('You have a new message'));
        expect(json['type'], equals('chat'));
        expect(json['targetId'], equals('conv-123'));
        expect(json['isRead'], isTrue);
        expect(json['createdAt'], isNotNull);
        expect(json['readAt'], isNotNull);
      });

      test('should serialize null values correctly', () {
        final notification = AppNotification(
          id: 'notif-123',
          title: 'System',
          body: 'Message',
          type: NotificationType.system,
          createdAt: testDate,
        );

        final json = notification.toJson();

        expect(json['targetId'], isNull);
        expect(json['readAt'], isNull);
      });
    });

    group('copyWith', () {
      test('should create copy with updated values', () {
        final notification = AppNotification(
          id: 'notif-123',
          title: 'Original Title',
          body: 'Original Body',
          type: NotificationType.chat,
          isRead: false,
          createdAt: testDate,
        );

        final updatedNotification = notification.copyWith(
          title: 'Updated Title',
          isRead: true,
          readAt: testDate,
        );

        expect(updatedNotification.id, equals('notif-123'));
        expect(updatedNotification.title, equals('Updated Title'));
        expect(updatedNotification.body, equals('Original Body'));
        expect(updatedNotification.type, equals(NotificationType.chat));
        expect(updatedNotification.isRead, isTrue);
        expect(updatedNotification.readAt, equals(testDate));
      });

      test('should keep original values when not provided', () {
        final notification = AppNotification(
          id: 'notif-123',
          title: 'Title',
          body: 'Body',
          type: NotificationType.incident,
          targetId: 'inc-456',
          createdAt: testDate,
        );

        final updatedNotification = notification.copyWith(isRead: true);

        expect(updatedNotification.id, equals('notif-123'));
        expect(updatedNotification.title, equals('Title'));
        expect(updatedNotification.body, equals('Body'));
        expect(updatedNotification.type, equals(NotificationType.incident));
        expect(updatedNotification.targetId, equals('inc-456'));
      });
    });

    group('hasTarget', () {
      test('should return true when targetId is present and not empty', () {
        final notification = AppNotification(
          id: 'notif-123',
          title: 'Title',
          body: 'Body',
          type: NotificationType.chat,
          targetId: 'conv-123',
          createdAt: testDate,
        );

        expect(notification.hasTarget, isTrue);
      });

      test('should return false when targetId is null', () {
        final notification = AppNotification(
          id: 'notif-123',
          title: 'Title',
          body: 'Body',
          type: NotificationType.system,
          createdAt: testDate,
        );

        expect(notification.hasTarget, isFalse);
      });

      test('should return false when targetId is empty', () {
        final notification = AppNotification(
          id: 'notif-123',
          title: 'Title',
          body: 'Body',
          type: NotificationType.system,
          targetId: '',
          createdAt: testDate,
        );

        expect(notification.hasTarget, isFalse);
      });
    });

    group('equality', () {
      test('two notifications with same properties should be equal', () {
        final notification1 = AppNotification(
          id: 'notif-123',
          title: 'Title',
          body: 'Body',
          type: NotificationType.chat,
          createdAt: testDate,
        );

        final notification2 = AppNotification(
          id: 'notif-123',
          title: 'Title',
          body: 'Body',
          type: NotificationType.chat,
          createdAt: testDate,
        );

        expect(notification1, equals(notification2));
      });

      test('two notifications with different properties should not be equal', () {
        final notification1 = AppNotification(
          id: 'notif-123',
          title: 'Title 1',
          body: 'Body 1',
          type: NotificationType.chat,
          createdAt: testDate,
        );

        final notification2 = AppNotification(
          id: 'notif-456',
          title: 'Title 2',
          body: 'Body 2',
          type: NotificationType.incident,
          createdAt: testDate,
        );

        expect(notification1, isNot(equals(notification2)));
      });
    });
  });

  group('PaginatedNotifications', () {
    final testDate = DateTime(2024, 1, 15, 10, 30);
    final testDateString = '2024-01-15T10:30:00.000';

    group('fromJson', () {
      test('should parse valid JSON', () {
        final json = {
          'data': [
            {
              'id': 'notif-1',
              'title': 'Notification 1',
              'body': 'Body 1',
              'type': 'chat',
              'created_at': testDateString,
            },
            {
              'id': 'notif-2',
              'title': 'Notification 2',
              'body': 'Body 2',
              'type': 'incident',
              'created_at': testDateString,
            },
          ],
          'pagination': {
            'total': 50,
            'page': 1,
            'limit': 20,
            'totalPages': 3,
          },
          'unreadCount': 5,
        };

        final paginated = PaginatedNotifications.fromJson(json);

        expect(paginated.notifications.length, equals(2));
        expect(paginated.notifications[0].id, equals('notif-1'));
        expect(paginated.notifications[1].id, equals('notif-2'));
        expect(paginated.total, equals(50));
        expect(paginated.page, equals(1));
        expect(paginated.limit, equals(20));
        expect(paginated.totalPages, equals(3));
        expect(paginated.unreadCount, equals(5));
      });

      test('should handle empty data', () {
        final json = {
          'data': [],
          'pagination': {
            'total': 0,
            'page': 1,
            'limit': 20,
            'totalPages': 0,
          },
          'unreadCount': 0,
        };

        final paginated = PaginatedNotifications.fromJson(json);

        expect(paginated.notifications, isEmpty);
        expect(paginated.total, equals(0));
        expect(paginated.unreadCount, equals(0));
      });

      test('should handle missing pagination with defaults', () {
        final json = <String, dynamic>{
          'data': <dynamic>[],
          'pagination': <String, dynamic>{},
        };

        final paginated = PaginatedNotifications.fromJson(json);

        expect(paginated.total, equals(0));
        expect(paginated.page, equals(1));
        expect(paginated.limit, equals(20));
        expect(paginated.totalPages, equals(1));
        expect(paginated.unreadCount, equals(0));
      });
    });

    group('hasNextPage', () {
      test('should return true when page < totalPages', () {
        const paginated = PaginatedNotifications(
          notifications: [],
          total: 50,
          page: 1,
          limit: 20,
          totalPages: 3,
        );

        expect(paginated.hasNextPage, isTrue);
      });

      test('should return false when page >= totalPages', () {
        const paginated = PaginatedNotifications(
          notifications: [],
          total: 50,
          page: 3,
          limit: 20,
          totalPages: 3,
        );

        expect(paginated.hasNextPage, isFalse);
      });
    });

    group('equality', () {
      test('two paginated results with same properties should be equal', () {
        const paginated1 = PaginatedNotifications(
          notifications: [],
          total: 50,
          page: 1,
          limit: 20,
          totalPages: 3,
          unreadCount: 5,
        );

        const paginated2 = PaginatedNotifications(
          notifications: [],
          total: 50,
          page: 1,
          limit: 20,
          totalPages: 3,
          unreadCount: 5,
        );

        expect(paginated1, equals(paginated2));
      });
    });
  });
}
