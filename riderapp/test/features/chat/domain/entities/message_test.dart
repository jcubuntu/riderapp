import 'package:flutter_test/flutter_test.dart';
import 'package:riderapp/features/chat/domain/entities/message.dart';

void main() {
  group('MessageType', () {
    group('fromString', () {
      test('should parse text', () {
        expect(MessageType.fromString('text'), equals(MessageType.text));
      });

      test('should parse image', () {
        expect(MessageType.fromString('image'), equals(MessageType.image));
      });

      test('should parse file', () {
        expect(MessageType.fromString('file'), equals(MessageType.file));
      });

      test('should parse system', () {
        expect(MessageType.fromString('system'), equals(MessageType.system));
      });

      test('should be case insensitive', () {
        expect(MessageType.fromString('TEXT'), equals(MessageType.text));
        expect(MessageType.fromString('Image'), equals(MessageType.image));
        expect(MessageType.fromString('FILE'), equals(MessageType.file));
      });

      test('should default to text for unknown values', () {
        expect(MessageType.fromString('unknown'), equals(MessageType.text));
        expect(MessageType.fromString(''), equals(MessageType.text));
      });
    });
  });

  group('MessageSender', () {
    group('fromJson', () {
      test('should parse valid JSON', () {
        final json = {
          'id': 'user-123',
          'name': 'John Doe',
          'phone': '0811111111',
          'avatar_url': 'https://example.com/avatar.jpg',
        };

        final sender = MessageSender.fromJson(json);

        expect(sender.id, equals('user-123'));
        expect(sender.name, equals('John Doe'));
        expect(sender.phone, equals('0811111111'));
        expect(sender.avatarUrl, equals('https://example.com/avatar.jpg'));
      });

      test('should handle fullName key', () {
        final json = {
          'id': 'user-123',
          'fullName': 'John Doe',
        };

        final sender = MessageSender.fromJson(json);

        expect(sender.name, equals('John Doe'));
      });

      test('should handle camelCase avatarUrl', () {
        final json = {
          'id': 'user-123',
          'avatarUrl': 'https://example.com/avatar.jpg',
        };

        final sender = MessageSender.fromJson(json);

        expect(sender.avatarUrl, equals('https://example.com/avatar.jpg'));
      });

      test('should handle null values', () {
        final json = <String, dynamic>{
          'id': 'user-123',
        };

        final sender = MessageSender.fromJson(json);

        expect(sender.id, equals('user-123'));
        expect(sender.name, isNull);
        expect(sender.phone, isNull);
        expect(sender.avatarUrl, isNull);
      });

      test('should default id to empty string if null', () {
        final json = <String, dynamic>{};

        final sender = MessageSender.fromJson(json);

        expect(sender.id, equals(''));
      });
    });

    group('toJson', () {
      test('should serialize correctly', () {
        const sender = MessageSender(
          id: 'user-123',
          name: 'John Doe',
          phone: '0811111111',
          avatarUrl: 'https://example.com/avatar.jpg',
        );

        final json = sender.toJson();

        expect(json['id'], equals('user-123'));
        expect(json['name'], equals('John Doe'));
        expect(json['phone'], equals('0811111111'));
        expect(json['avatarUrl'], equals('https://example.com/avatar.jpg'));
      });

      test('should serialize null values', () {
        const sender = MessageSender(id: 'user-123');

        final json = sender.toJson();

        expect(json['id'], equals('user-123'));
        expect(json['name'], isNull);
        expect(json['phone'], isNull);
        expect(json['avatarUrl'], isNull);
      });
    });

    group('equality', () {
      test('two senders with same properties should be equal', () {
        const sender1 = MessageSender(
          id: 'user-123',
          name: 'John Doe',
        );

        const sender2 = MessageSender(
          id: 'user-123',
          name: 'John Doe',
        );

        expect(sender1, equals(sender2));
      });

      test('two senders with different properties should not be equal', () {
        const sender1 = MessageSender(
          id: 'user-123',
          name: 'John Doe',
        );

        const sender2 = MessageSender(
          id: 'user-456',
          name: 'Jane Doe',
        );

        expect(sender1, isNot(equals(sender2)));
      });
    });
  });

  group('Message', () {
    final testDate = DateTime(2024, 1, 15, 10, 30);
    final testDateString = '2024-01-15T10:30:00.000';

    const testSender = MessageSender(
      id: 'user-123',
      name: 'John Doe',
    );

    group('fromJson', () {
      test('should parse valid JSON with snake_case keys', () {
        final json = {
          'id': 'msg-123',
          'conversation_id': 'conv-123',
          'sender': {
            'id': 'user-123',
            'name': 'John Doe',
          },
          'content': 'Hello, world!',
          'type': 'text',
          'attachment_url': 'https://example.com/file.pdf',
          'attachment_name': 'file.pdf',
          'thumbnail_url': 'https://example.com/thumb.jpg',
          'attachment_size': 1024,
          'is_read': true,
          'sent_at': testDateString,
          'read_at': testDateString,
        };

        final message = Message.fromJson(json);

        expect(message.id, equals('msg-123'));
        expect(message.conversationId, equals('conv-123'));
        expect(message.sender.id, equals('user-123'));
        expect(message.sender.name, equals('John Doe'));
        expect(message.content, equals('Hello, world!'));
        expect(message.type, equals(MessageType.text));
        expect(message.attachmentUrl, equals('https://example.com/file.pdf'));
        expect(message.attachmentName, equals('file.pdf'));
        expect(message.thumbnailUrl, equals('https://example.com/thumb.jpg'));
        expect(message.attachmentSize, equals(1024));
        expect(message.isRead, isTrue);
        expect(message.sentAt, isNotNull);
        expect(message.readAt, isNotNull);
      });

      test('should parse valid JSON with camelCase keys', () {
        final json = {
          'id': 'msg-123',
          'conversationId': 'conv-123',
          'sender': {
            'id': 'user-123',
            'name': 'John Doe',
          },
          'content': 'Hello, world!',
          'type': 'image',
          'attachmentUrl': 'https://example.com/image.jpg',
          'attachmentName': 'image.jpg',
          'thumbnailUrl': 'https://example.com/thumb.jpg',
          'attachmentSize': 2048,
          'isRead': false,
          'sentAt': testDateString,
          'readAt': testDateString,
        };

        final message = Message.fromJson(json);

        expect(message.conversationId, equals('conv-123'));
        expect(message.type, equals(MessageType.image));
        expect(message.attachmentUrl, equals('https://example.com/image.jpg'));
        expect(message.isRead, isFalse);
      });

      test('should handle sender_id fallback when sender object is missing', () {
        final json = {
          'id': 'msg-123',
          'conversation_id': 'conv-123',
          'sender_id': 'user-456',
          'content': 'Hello!',
          'type': 'text',
          'sent_at': testDateString,
        };

        final message = Message.fromJson(json);

        expect(message.sender.id, equals('user-456'));
        expect(message.sender.name, isNull);
      });

      test('should handle null optional values', () {
        final json = {
          'id': 'msg-123',
          'conversation_id': 'conv-123',
          'sender': {
            'id': 'user-123',
          },
          'content': 'Hello!',
          'sent_at': testDateString,
        };

        final message = Message.fromJson(json);

        expect(message.type, equals(MessageType.text));
        expect(message.attachmentUrl, isNull);
        expect(message.attachmentName, isNull);
        expect(message.thumbnailUrl, isNull);
        expect(message.attachmentSize, isNull);
        expect(message.isRead, isFalse);
        expect(message.readAt, isNull);
      });

      test('should default content to empty string', () {
        final json = {
          'id': 'msg-123',
          'conversation_id': 'conv-123',
          'sender': {
            'id': 'user-123',
          },
          'sent_at': testDateString,
        };

        final message = Message.fromJson(json);

        expect(message.content, equals(''));
      });

      test('should use created_at fallback for sentAt', () {
        final json = {
          'id': 'msg-123',
          'conversation_id': 'conv-123',
          'sender': {
            'id': 'user-123',
          },
          'content': 'Hello!',
          'created_at': testDateString,
        };

        final message = Message.fromJson(json);

        expect(message.sentAt, isNotNull);
      });
    });

    group('toJson', () {
      test('should serialize correctly', () {
        final message = Message(
          id: 'msg-123',
          conversationId: 'conv-123',
          sender: testSender,
          content: 'Hello, world!',
          type: MessageType.text,
          attachmentUrl: 'https://example.com/file.pdf',
          attachmentName: 'file.pdf',
          thumbnailUrl: 'https://example.com/thumb.jpg',
          attachmentSize: 1024,
          isRead: true,
          sentAt: testDate,
          readAt: testDate,
        );

        final json = message.toJson();

        expect(json['id'], equals('msg-123'));
        expect(json['conversationId'], equals('conv-123'));
        expect(json['sender'], isA<Map>());
        expect(json['sender']['id'], equals('user-123'));
        expect(json['content'], equals('Hello, world!'));
        expect(json['type'], equals('text'));
        expect(json['attachmentUrl'], equals('https://example.com/file.pdf'));
        expect(json['attachmentName'], equals('file.pdf'));
        expect(json['thumbnailUrl'], equals('https://example.com/thumb.jpg'));
        expect(json['attachmentSize'], equals(1024));
        expect(json['isRead'], isTrue);
        expect(json['sentAt'], isNotNull);
        expect(json['readAt'], isNotNull);
      });

      test('should serialize null values', () {
        final message = Message(
          id: 'msg-123',
          conversationId: 'conv-123',
          sender: testSender,
          content: 'Hello!',
          sentAt: testDate,
        );

        final json = message.toJson();

        expect(json['attachmentUrl'], isNull);
        expect(json['attachmentName'], isNull);
        expect(json['thumbnailUrl'], isNull);
        expect(json['attachmentSize'], isNull);
        expect(json['readAt'], isNull);
      });
    });

    group('copyWith', () {
      test('should create copy with updated values', () {
        final message = Message(
          id: 'msg-123',
          conversationId: 'conv-123',
          sender: testSender,
          content: 'Hello!',
          type: MessageType.text,
          isRead: false,
          sentAt: testDate,
        );

        final updatedMessage = message.copyWith(
          content: 'Updated content',
          isRead: true,
        );

        expect(updatedMessage.id, equals('msg-123'));
        expect(updatedMessage.conversationId, equals('conv-123'));
        expect(updatedMessage.content, equals('Updated content'));
        expect(updatedMessage.isRead, isTrue);
        expect(updatedMessage.type, equals(MessageType.text));
      });

      test('should keep original values when not provided', () {
        final message = Message(
          id: 'msg-123',
          conversationId: 'conv-123',
          sender: testSender,
          content: 'Hello!',
          type: MessageType.image,
          attachmentUrl: 'https://example.com/image.jpg',
          sentAt: testDate,
        );

        final updatedMessage = message.copyWith(content: 'Updated');

        expect(updatedMessage.type, equals(MessageType.image));
        expect(updatedMessage.attachmentUrl, equals('https://example.com/image.jpg'));
        expect(updatedMessage.sender, equals(testSender));
      });
    });

    group('hasAttachment', () {
      test('should return true when attachmentUrl is present and not empty', () {
        final message = Message(
          id: 'msg-123',
          conversationId: 'conv-123',
          sender: testSender,
          content: 'File attached',
          attachmentUrl: 'https://example.com/file.pdf',
          sentAt: testDate,
        );

        expect(message.hasAttachment, isTrue);
      });

      test('should return false when attachmentUrl is null', () {
        final message = Message(
          id: 'msg-123',
          conversationId: 'conv-123',
          sender: testSender,
          content: 'No attachment',
          sentAt: testDate,
        );

        expect(message.hasAttachment, isFalse);
      });

      test('should return false when attachmentUrl is empty', () {
        final message = Message(
          id: 'msg-123',
          conversationId: 'conv-123',
          sender: testSender,
          content: 'Empty attachment',
          attachmentUrl: '',
          sentAt: testDate,
        );

        expect(message.hasAttachment, isFalse);
      });
    });

    group('equality', () {
      test('two messages with same properties should be equal', () {
        final message1 = Message(
          id: 'msg-123',
          conversationId: 'conv-123',
          sender: testSender,
          content: 'Hello!',
          sentAt: testDate,
        );

        final message2 = Message(
          id: 'msg-123',
          conversationId: 'conv-123',
          sender: testSender,
          content: 'Hello!',
          sentAt: testDate,
        );

        expect(message1, equals(message2));
      });

      test('two messages with different properties should not be equal', () {
        final message1 = Message(
          id: 'msg-123',
          conversationId: 'conv-123',
          sender: testSender,
          content: 'Hello!',
          sentAt: testDate,
        );

        final message2 = Message(
          id: 'msg-456',
          conversationId: 'conv-456',
          sender: testSender,
          content: 'Different!',
          sentAt: testDate,
        );

        expect(message1, isNot(equals(message2)));
      });
    });
  });

  group('PaginatedMessages', () {
    final testDate = DateTime(2024, 1, 15, 10, 30);
    final testDateString = '2024-01-15T10:30:00.000';

    group('fromJson', () {
      test('should parse valid JSON', () {
        final json = {
          'data': [
            {
              'id': 'msg-1',
              'conversation_id': 'conv-123',
              'sender': {'id': 'user-1', 'name': 'User 1'},
              'content': 'Message 1',
              'sent_at': testDateString,
            },
            {
              'id': 'msg-2',
              'conversation_id': 'conv-123',
              'sender': {'id': 'user-2', 'name': 'User 2'},
              'content': 'Message 2',
              'sent_at': testDateString,
            },
          ],
          'pagination': {
            'total': 100,
            'page': 2,
            'limit': 20,
            'totalPages': 5,
          },
        };

        final paginated = PaginatedMessages.fromJson(json);

        expect(paginated.messages.length, equals(2));
        expect(paginated.messages[0].id, equals('msg-1'));
        expect(paginated.messages[1].id, equals('msg-2'));
        expect(paginated.total, equals(100));
        expect(paginated.page, equals(2));
        expect(paginated.limit, equals(20));
        expect(paginated.totalPages, equals(5));
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
        };

        final paginated = PaginatedMessages.fromJson(json);

        expect(paginated.messages, isEmpty);
        expect(paginated.total, equals(0));
      });

      test('should handle missing pagination with defaults', () {
        final json = <String, dynamic>{
          'data': <dynamic>[],
          'pagination': <String, dynamic>{},
        };

        final paginated = PaginatedMessages.fromJson(json);

        expect(paginated.total, equals(0));
        expect(paginated.page, equals(1));
        expect(paginated.limit, equals(20));
        expect(paginated.totalPages, equals(1));
      });
    });

    group('hasNextPage', () {
      test('should return true when page < totalPages', () {
        const paginated = PaginatedMessages(
          messages: [],
          total: 100,
          page: 2,
          limit: 20,
          totalPages: 5,
        );

        expect(paginated.hasNextPage, isTrue);
      });

      test('should return false when page >= totalPages', () {
        const paginated = PaginatedMessages(
          messages: [],
          total: 100,
          page: 5,
          limit: 20,
          totalPages: 5,
        );

        expect(paginated.hasNextPage, isFalse);
      });

      test('should return false when on last page', () {
        const paginated = PaginatedMessages(
          messages: [],
          total: 40,
          page: 2,
          limit: 20,
          totalPages: 2,
        );

        expect(paginated.hasNextPage, isFalse);
      });
    });

    group('equality', () {
      test('two paginated results with same properties should be equal', () {
        const paginated1 = PaginatedMessages(
          messages: [],
          total: 100,
          page: 1,
          limit: 20,
          totalPages: 5,
        );

        const paginated2 = PaginatedMessages(
          messages: [],
          total: 100,
          page: 1,
          limit: 20,
          totalPages: 5,
        );

        expect(paginated1, equals(paginated2));
      });
    });
  });
}
