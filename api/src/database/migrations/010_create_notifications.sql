-- Migration: 010_create_notifications
-- Description: Create notifications table for user notifications
-- Created at: 2025-12-26

-- Drop table if exists (for clean migration)
DROP TABLE IF EXISTS notifications;

-- Create notifications table
CREATE TABLE notifications (
    id CHAR(36) NOT NULL PRIMARY KEY COMMENT 'UUID primary key',

    -- Recipient
    user_id CHAR(36) NOT NULL COMMENT 'User who receives the notification',

    -- Notification content
    title VARCHAR(255) NOT NULL COMMENT 'Notification title',
    body TEXT NOT NULL COMMENT 'Notification body/content',
    summary VARCHAR(500) NULL COMMENT 'Short summary for preview',

    -- Notification type and category
    type ENUM('info', 'success', 'warning', 'error', 'action') NOT NULL DEFAULT 'info' COMMENT 'Visual type of notification',
    category ENUM('system', 'incident', 'chat', 'announcement', 'approval', 'alert', 'reminder') NOT NULL DEFAULT 'system' COMMENT 'Category of notification',

    -- Reference to related entity
    entity_type VARCHAR(100) NULL COMMENT 'Type of related entity (incident, conversation, etc.)',
    entity_id CHAR(36) NULL COMMENT 'ID of the related entity',

    -- Action URL for deep linking
    action_url VARCHAR(500) NULL COMMENT 'URL/route to navigate to when tapped',
    action_type VARCHAR(50) NULL COMMENT 'Type of action (view, approve, reply, etc.)',

    -- Media
    image_url VARCHAR(500) NULL COMMENT 'Image URL for rich notifications',
    icon VARCHAR(100) NULL COMMENT 'Icon name/code',

    -- Status
    is_read BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'Whether notification has been read',
    read_at DATETIME NULL COMMENT 'When notification was read',
    is_dismissed BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'Whether notification was dismissed',
    dismissed_at DATETIME NULL COMMENT 'When notification was dismissed',

    -- Push notification status
    is_push_sent BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'Whether push notification was sent',
    push_sent_at DATETIME NULL COMMENT 'When push was sent',
    push_error VARCHAR(500) NULL COMMENT 'Error if push failed',

    -- Scheduling
    scheduled_at DATETIME NULL COMMENT 'When to send notification (null = immediate)',
    expires_at DATETIME NULL COMMENT 'When notification expires',

    -- Priority
    priority ENUM('low', 'normal', 'high') NOT NULL DEFAULT 'normal' COMMENT 'Notification priority',

    -- Sender (for user-triggered notifications)
    sender_id CHAR(36) NULL COMMENT 'User who triggered the notification',

    -- Additional data
    data JSON NULL COMMENT 'Additional data as JSON for client',

    -- Timestamps
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Record creation timestamp',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Record update timestamp',

    -- Foreign key constraints
    CONSTRAINT fk_notifications_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_notifications_sender FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='User notifications';

-- Indexes for performance
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_type ON notifications(type);
CREATE INDEX idx_notifications_category ON notifications(category);
CREATE INDEX idx_notifications_entity_type ON notifications(entity_type);
CREATE INDEX idx_notifications_entity_id ON notifications(entity_id);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);
CREATE INDEX idx_notifications_is_dismissed ON notifications(is_dismissed);
CREATE INDEX idx_notifications_priority ON notifications(priority);
CREATE INDEX idx_notifications_sender_id ON notifications(sender_id);
CREATE INDEX idx_notifications_scheduled_at ON notifications(scheduled_at);
CREATE INDEX idx_notifications_expires_at ON notifications(expires_at);
CREATE INDEX idx_notifications_created_at ON notifications(created_at);

-- Composite indexes for common queries
CREATE INDEX idx_notifications_user_unread ON notifications(user_id, is_read, is_dismissed, created_at);
CREATE INDEX idx_notifications_user_category ON notifications(user_id, category, created_at);
CREATE INDEX idx_notifications_pending_push ON notifications(is_push_sent, scheduled_at);
CREATE INDEX idx_notifications_user_priority ON notifications(user_id, priority, is_read, created_at);

-- Create notification_settings table for user preferences
DROP TABLE IF EXISTS notification_settings;

CREATE TABLE notification_settings (
    id CHAR(36) NOT NULL PRIMARY KEY COMMENT 'UUID primary key',

    -- User reference
    user_id CHAR(36) NOT NULL COMMENT 'Reference to users table',

    -- Push notification settings
    push_enabled BOOLEAN NOT NULL DEFAULT TRUE COMMENT 'Master switch for push notifications',
    push_incidents BOOLEAN NOT NULL DEFAULT TRUE COMMENT 'Push for incident updates',
    push_chat BOOLEAN NOT NULL DEFAULT TRUE COMMENT 'Push for chat messages',
    push_announcements BOOLEAN NOT NULL DEFAULT TRUE COMMENT 'Push for announcements',
    push_approvals BOOLEAN NOT NULL DEFAULT TRUE COMMENT 'Push for approval-related',
    push_alerts BOOLEAN NOT NULL DEFAULT TRUE COMMENT 'Push for emergency alerts',

    -- Email notification settings
    email_enabled BOOLEAN NOT NULL DEFAULT TRUE COMMENT 'Master switch for email notifications',
    email_incidents BOOLEAN NOT NULL DEFAULT TRUE COMMENT 'Email for incident updates',
    email_announcements BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'Email for announcements',
    email_weekly_digest BOOLEAN NOT NULL DEFAULT TRUE COMMENT 'Weekly digest email',

    -- Quiet hours
    quiet_hours_enabled BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'Enable quiet hours',
    quiet_hours_start TIME NULL COMMENT 'Quiet hours start time',
    quiet_hours_end TIME NULL COMMENT 'Quiet hours end time',

    -- Sound and vibration
    sound_enabled BOOLEAN NOT NULL DEFAULT TRUE COMMENT 'Enable notification sound',
    vibration_enabled BOOLEAN NOT NULL DEFAULT TRUE COMMENT 'Enable vibration',

    -- Timestamps
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Record creation timestamp',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Record update timestamp',

    -- Foreign key constraint
    CONSTRAINT fk_notification_settings_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,

    -- Unique constraint - one settings record per user
    CONSTRAINT uk_notification_settings_user UNIQUE (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='User notification preferences';

-- Indexes for performance
CREATE INDEX idx_notification_settings_user_id ON notification_settings(user_id);
CREATE INDEX idx_notification_settings_push_enabled ON notification_settings(push_enabled);
CREATE INDEX idx_notification_settings_email_enabled ON notification_settings(email_enabled);
