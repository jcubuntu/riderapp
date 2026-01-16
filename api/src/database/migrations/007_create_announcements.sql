-- Migration: 007_create_announcements
-- Description: Create announcements table for system-wide announcements
-- Created at: 2025-12-26

-- Drop table if exists (for clean migration)
DROP TABLE IF EXISTS announcements;

-- Create announcements table
CREATE TABLE announcements (
    id CHAR(36) NOT NULL PRIMARY KEY COMMENT 'UUID primary key',

    -- Author
    created_by CHAR(36) NOT NULL COMMENT 'Admin who created the announcement',

    -- Announcement content
    title VARCHAR(255) NOT NULL COMMENT 'Announcement title',
    content TEXT NOT NULL COMMENT 'Announcement content',
    summary VARCHAR(500) NULL COMMENT 'Brief summary for preview',

    -- Media
    image_url VARCHAR(500) NULL COMMENT 'Featured image URL',
    attachment_url VARCHAR(500) NULL COMMENT 'Attachment file URL',
    attachment_name VARCHAR(255) NULL COMMENT 'Original attachment filename',

    -- Classification
    category ENUM('general', 'safety', 'event', 'alert', 'update', 'maintenance') NOT NULL DEFAULT 'general' COMMENT 'Announcement category',
    priority ENUM('low', 'normal', 'high', 'urgent') NOT NULL DEFAULT 'normal' COMMENT 'Priority level',

    -- Target audience
    target_audience ENUM('all', 'riders', 'police', 'admin') NOT NULL DEFAULT 'all' COMMENT 'Target user group',
    target_province VARCHAR(100) NULL COMMENT 'Target specific province (null for all)',

    -- Status and scheduling
    status ENUM('draft', 'scheduled', 'published', 'archived') NOT NULL DEFAULT 'draft' COMMENT 'Publication status',
    publish_at DATETIME NULL COMMENT 'Scheduled publication time',
    expires_at DATETIME NULL COMMENT 'When announcement expires',

    -- Engagement tracking
    view_count INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Number of views',
    is_pinned BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'Whether announcement is pinned',

    -- Publishing info
    published_by CHAR(36) NULL COMMENT 'Who published the announcement',
    published_at DATETIME NULL COMMENT 'When announcement was published',

    -- Timestamps
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Record creation timestamp',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Record update timestamp',

    -- Foreign key constraints
    CONSTRAINT fk_announcements_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_announcements_published_by FOREIGN KEY (published_by) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='System announcements';

-- Indexes for performance
CREATE INDEX idx_announcements_created_by ON announcements(created_by);
CREATE INDEX idx_announcements_category ON announcements(category);
CREATE INDEX idx_announcements_priority ON announcements(priority);
CREATE INDEX idx_announcements_target_audience ON announcements(target_audience);
CREATE INDEX idx_announcements_target_province ON announcements(target_province);
CREATE INDEX idx_announcements_status ON announcements(status);
CREATE INDEX idx_announcements_publish_at ON announcements(publish_at);
CREATE INDEX idx_announcements_expires_at ON announcements(expires_at);
CREATE INDEX idx_announcements_is_pinned ON announcements(is_pinned);
CREATE INDEX idx_announcements_created_at ON announcements(created_at);

-- Composite index for fetching active announcements
CREATE INDEX idx_announcements_active ON announcements(status, publish_at, expires_at);
CREATE INDEX idx_announcements_audience_active ON announcements(target_audience, status, publish_at);
CREATE INDEX idx_announcements_pinned_active ON announcements(is_pinned, status, publish_at);

-- Create announcement_reads table to track who has read announcements
DROP TABLE IF EXISTS announcement_reads;

CREATE TABLE announcement_reads (
    id CHAR(36) NOT NULL PRIMARY KEY COMMENT 'UUID primary key',

    -- References
    announcement_id CHAR(36) NOT NULL COMMENT 'Reference to announcements table',
    user_id CHAR(36) NOT NULL COMMENT 'User who read the announcement',

    -- Read timestamp
    read_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'When announcement was read',

    -- Foreign key constraints
    CONSTRAINT fk_announcement_reads_announcement FOREIGN KEY (announcement_id) REFERENCES announcements(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_announcement_reads_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,

    -- Unique constraint to prevent duplicate reads
    CONSTRAINT uk_announcement_user_read UNIQUE (announcement_id, user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Announcement read tracking';

-- Indexes for performance
CREATE INDEX idx_announcement_reads_announcement_id ON announcement_reads(announcement_id);
CREATE INDEX idx_announcement_reads_user_id ON announcement_reads(user_id);
CREATE INDEX idx_announcement_reads_read_at ON announcement_reads(read_at);
