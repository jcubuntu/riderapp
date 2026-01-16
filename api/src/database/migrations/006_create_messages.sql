-- Migration: 006_create_messages
-- Description: Create messages table for chat functionality
-- Created at: 2025-12-26

-- Drop table if exists (for clean migration)
DROP TABLE IF EXISTS messages;

-- Create messages table
CREATE TABLE messages (
    id CHAR(36) NOT NULL PRIMARY KEY COMMENT 'UUID primary key',

    -- References
    conversation_id CHAR(36) NOT NULL COMMENT 'Reference to conversations table',
    sender_id CHAR(36) NOT NULL COMMENT 'User who sent the message',

    -- Message content
    content TEXT NOT NULL COMMENT 'Message content',
    message_type ENUM('text', 'image', 'video', 'audio', 'file', 'location', 'system') NOT NULL DEFAULT 'text' COMMENT 'Type of message',

    -- Reply reference
    reply_to_id CHAR(36) NULL COMMENT 'Reference to message being replied to',

    -- Media attachments (for non-text messages)
    media_url VARCHAR(500) NULL COMMENT 'URL for media content',
    media_thumbnail_url VARCHAR(500) NULL COMMENT 'Thumbnail URL for media',
    media_mime_type VARCHAR(100) NULL COMMENT 'MIME type of media',
    media_size BIGINT UNSIGNED NULL COMMENT 'Media file size in bytes',
    media_duration INT UNSIGNED NULL COMMENT 'Duration for audio/video in seconds',
    media_width INT UNSIGNED NULL COMMENT 'Width for images/videos',
    media_height INT UNSIGNED NULL COMMENT 'Height for images/videos',

    -- Location data (for location messages)
    location_lat DECIMAL(10, 8) NULL COMMENT 'Latitude for location messages',
    location_lng DECIMAL(11, 8) NULL COMMENT 'Longitude for location messages',
    location_address VARCHAR(500) NULL COMMENT 'Address for location messages',

    -- Message status
    status ENUM('sending', 'sent', 'delivered', 'read', 'failed') NOT NULL DEFAULT 'sent' COMMENT 'Message delivery status',

    -- Editing and deletion
    is_edited BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'Whether message was edited',
    edited_at DATETIME NULL COMMENT 'When message was edited',
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'Whether message was deleted',
    deleted_at DATETIME NULL COMMENT 'When message was deleted',
    deleted_for_all BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'Deleted for all participants',

    -- Metadata
    metadata JSON NULL COMMENT 'Additional metadata as JSON',

    -- Timestamps
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Record creation timestamp',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Record update timestamp',

    -- Foreign key constraints
    CONSTRAINT fk_messages_conversation FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_messages_sender FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_messages_reply_to FOREIGN KEY (reply_to_id) REFERENCES messages(id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Chat messages';

-- Indexes for performance
CREATE INDEX idx_messages_conversation_id ON messages(conversation_id);
CREATE INDEX idx_messages_sender_id ON messages(sender_id);
CREATE INDEX idx_messages_message_type ON messages(message_type);
CREATE INDEX idx_messages_status ON messages(status);
CREATE INDEX idx_messages_reply_to_id ON messages(reply_to_id);
CREATE INDEX idx_messages_created_at ON messages(created_at);
CREATE INDEX idx_messages_is_deleted ON messages(is_deleted);

-- Composite index for fetching conversation messages
CREATE INDEX idx_messages_conversation_created ON messages(conversation_id, created_at);
CREATE INDEX idx_messages_conversation_not_deleted ON messages(conversation_id, is_deleted, created_at);

-- Create message_reads table to track read receipts
DROP TABLE IF EXISTS message_reads;

CREATE TABLE message_reads (
    id CHAR(36) NOT NULL PRIMARY KEY COMMENT 'UUID primary key',

    -- References
    message_id CHAR(36) NOT NULL COMMENT 'Reference to messages table',
    user_id CHAR(36) NOT NULL COMMENT 'User who read the message',

    -- Read timestamp
    read_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'When message was read',

    -- Foreign key constraints
    CONSTRAINT fk_message_reads_message FOREIGN KEY (message_id) REFERENCES messages(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_message_reads_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,

    -- Unique constraint to prevent duplicate read receipts
    CONSTRAINT uk_message_user_read UNIQUE (message_id, user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Message read receipts';

-- Indexes for performance
CREATE INDEX idx_message_reads_message_id ON message_reads(message_id);
CREATE INDEX idx_message_reads_user_id ON message_reads(user_id);
CREATE INDEX idx_message_reads_read_at ON message_reads(read_at);
