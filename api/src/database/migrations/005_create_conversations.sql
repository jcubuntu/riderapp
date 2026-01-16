-- Migration: 005_create_conversations
-- Description: Create conversations table for chat functionality
-- Created at: 2025-12-26

-- Drop table if exists (for clean migration)
DROP TABLE IF EXISTS conversations;

-- Create conversations table
CREATE TABLE conversations (
    id CHAR(36) NOT NULL PRIMARY KEY COMMENT 'UUID primary key',

    -- Conversation type
    type ENUM('direct', 'incident', 'group', 'support') NOT NULL DEFAULT 'direct' COMMENT 'Type of conversation',

    -- Reference to incident (if incident-related)
    incident_id CHAR(36) NULL COMMENT 'Related incident for incident conversations',

    -- Conversation metadata
    title VARCHAR(255) NULL COMMENT 'Optional title for group/support conversations',

    -- Participants (for direct messages, store both user IDs)
    participant_one CHAR(36) NULL COMMENT 'First participant (for direct messages)',
    participant_two CHAR(36) NULL COMMENT 'Second participant (for direct messages)',

    -- Status
    status ENUM('active', 'archived', 'closed') NOT NULL DEFAULT 'active' COMMENT 'Conversation status',
    is_muted BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'Whether notifications are muted',

    -- Message tracking
    last_message_id CHAR(36) NULL COMMENT 'Reference to last message',
    last_message_at DATETIME NULL COMMENT 'Timestamp of last message',
    last_message_preview VARCHAR(255) NULL COMMENT 'Preview of last message',

    -- Timestamps
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Record creation timestamp',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Record update timestamp',

    -- Foreign key constraints
    CONSTRAINT fk_conversations_incident FOREIGN KEY (incident_id) REFERENCES incidents(id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_conversations_participant_one FOREIGN KEY (participant_one) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_conversations_participant_two FOREIGN KEY (participant_two) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Chat conversations';

-- Indexes for performance
CREATE INDEX idx_conversations_type ON conversations(type);
CREATE INDEX idx_conversations_incident_id ON conversations(incident_id);
CREATE INDEX idx_conversations_participant_one ON conversations(participant_one);
CREATE INDEX idx_conversations_participant_two ON conversations(participant_two);
CREATE INDEX idx_conversations_status ON conversations(status);
CREATE INDEX idx_conversations_last_message_at ON conversations(last_message_at);
CREATE INDEX idx_conversations_created_at ON conversations(created_at);

-- Composite index for finding direct conversations between two users
CREATE INDEX idx_conversations_direct_participants ON conversations(participant_one, participant_two, type);

-- Create conversation_participants table for group conversations
DROP TABLE IF EXISTS conversation_participants;

CREATE TABLE conversation_participants (
    id CHAR(36) NOT NULL PRIMARY KEY COMMENT 'UUID primary key',

    -- References
    conversation_id CHAR(36) NOT NULL COMMENT 'Reference to conversations table',
    user_id CHAR(36) NOT NULL COMMENT 'Reference to users table',

    -- Participant role
    role ENUM('member', 'admin', 'moderator') NOT NULL DEFAULT 'member' COMMENT 'Role in conversation',

    -- Read tracking
    last_read_at DATETIME NULL COMMENT 'When user last read the conversation',
    last_read_message_id CHAR(36) NULL COMMENT 'Last message user has read',
    unread_count INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Number of unread messages',

    -- Notification preferences
    is_muted BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'User-specific mute setting',
    notification_enabled BOOLEAN NOT NULL DEFAULT TRUE COMMENT 'Enable notifications for this conversation',

    -- Status
    is_active BOOLEAN NOT NULL DEFAULT TRUE COMMENT 'Whether user is active in conversation',
    left_at DATETIME NULL COMMENT 'When user left the conversation',

    -- Timestamps
    joined_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'When user joined',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Record creation timestamp',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Record update timestamp',

    -- Foreign key constraints
    CONSTRAINT fk_conv_participants_conversation FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_conv_participants_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,

    -- Unique constraint to prevent duplicate participants
    CONSTRAINT uk_conversation_participant UNIQUE (conversation_id, user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Participants in conversations';

-- Indexes for performance
CREATE INDEX idx_conv_participants_conversation_id ON conversation_participants(conversation_id);
CREATE INDEX idx_conv_participants_user_id ON conversation_participants(user_id);
CREATE INDEX idx_conv_participants_user_active ON conversation_participants(user_id, is_active);
CREATE INDEX idx_conv_participants_unread ON conversation_participants(user_id, unread_count);
