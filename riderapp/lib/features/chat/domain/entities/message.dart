import 'package:equatable/equatable.dart';

/// Message type enum
enum MessageType {
  text,
  image,
  file,
  system;

  static MessageType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'image':
        return MessageType.image;
      case 'file':
        return MessageType.file;
      case 'system':
        return MessageType.system;
      default:
        return MessageType.text;
    }
  }
}

/// Sender information
class MessageSender extends Equatable {
  final String id;
  final String? name;
  final String? phone;
  final String? avatarUrl;

  const MessageSender({
    required this.id,
    this.name,
    this.phone,
    this.avatarUrl,
  });

  factory MessageSender.fromJson(Map<String, dynamic> json) {
    return MessageSender(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? json['fullName'] as String?,
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String? ?? json['avatarUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'avatarUrl': avatarUrl,
      };

  @override
  List<Object?> get props => [id, name, phone, avatarUrl];
}

/// Chat message model
class Message extends Equatable {
  final String id;
  final String conversationId;
  final MessageSender sender;
  final String content;
  final MessageType type;
  final String? attachmentUrl;
  final String? attachmentName;
  final String? thumbnailUrl;
  final int? attachmentSize;
  final bool isRead;
  final DateTime sentAt;
  final DateTime? readAt;

  const Message({
    required this.id,
    required this.conversationId,
    required this.sender,
    required this.content,
    this.type = MessageType.text,
    this.attachmentUrl,
    this.attachmentName,
    this.thumbnailUrl,
    this.attachmentSize,
    this.isRead = false,
    required this.sentAt,
    this.readAt,
  });

  bool get hasAttachment => attachmentUrl != null && attachmentUrl!.isNotEmpty;

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String? ??
          json['conversationId'] as String? ??
          '',
      sender: json['sender'] != null
          ? MessageSender.fromJson(json['sender'] as Map<String, dynamic>)
          : MessageSender(id: json['sender_id'] as String? ?? ''),
      content: json['content'] as String? ?? '',
      type: MessageType.fromString(json['type'] as String? ?? 'text'),
      attachmentUrl:
          json['attachment_url'] as String? ?? json['attachmentUrl'] as String?,
      attachmentName: json['attachment_name'] as String? ??
          json['attachmentName'] as String?,
      thumbnailUrl:
          json['thumbnail_url'] as String? ?? json['thumbnailUrl'] as String?,
      attachmentSize:
          json['attachment_size'] as int? ?? json['attachmentSize'] as int?,
      isRead: json['is_read'] as bool? ?? json['isRead'] as bool? ?? false,
      sentAt: json['sent_at'] != null
          ? DateTime.parse(json['sent_at'] as String)
          : json['sentAt'] != null
              ? DateTime.parse(json['sentAt'] as String)
              : json['created_at'] != null
                  ? DateTime.parse(json['created_at'] as String)
                  : DateTime.now(),
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : json['readAt'] != null
              ? DateTime.parse(json['readAt'] as String)
              : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'conversationId': conversationId,
        'sender': sender.toJson(),
        'content': content,
        'type': type.name,
        'attachmentUrl': attachmentUrl,
        'attachmentName': attachmentName,
        'thumbnailUrl': thumbnailUrl,
        'attachmentSize': attachmentSize,
        'isRead': isRead,
        'sentAt': sentAt.toIso8601String(),
        'readAt': readAt?.toIso8601String(),
      };

  Message copyWith({
    String? id,
    String? conversationId,
    MessageSender? sender,
    String? content,
    MessageType? type,
    String? attachmentUrl,
    String? attachmentName,
    String? thumbnailUrl,
    int? attachmentSize,
    bool? isRead,
    DateTime? sentAt,
    DateTime? readAt,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      sender: sender ?? this.sender,
      content: content ?? this.content,
      type: type ?? this.type,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      attachmentName: attachmentName ?? this.attachmentName,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      attachmentSize: attachmentSize ?? this.attachmentSize,
      isRead: isRead ?? this.isRead,
      sentAt: sentAt ?? this.sentAt,
      readAt: readAt ?? this.readAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        conversationId,
        sender,
        content,
        type,
        attachmentUrl,
        attachmentName,
        thumbnailUrl,
        attachmentSize,
        isRead,
        sentAt,
        readAt,
      ];
}

/// Paginated messages result
class PaginatedMessages extends Equatable {
  final List<Message> messages;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  const PaginatedMessages({
    required this.messages,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  bool get hasNextPage => page < totalPages;

  factory PaginatedMessages.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as List<dynamic>? ?? [];
    final pagination = json['pagination'] as Map<String, dynamic>? ?? {};

    return PaginatedMessages(
      messages:
          data.map((e) => Message.fromJson(e as Map<String, dynamic>)).toList(),
      total: pagination['total'] as int? ?? 0,
      page: pagination['page'] as int? ?? 1,
      limit: pagination['limit'] as int? ?? 20,
      totalPages: pagination['totalPages'] as int? ?? 1,
    );
  }

  @override
  List<Object?> get props => [messages, total, page, limit, totalPages];
}
