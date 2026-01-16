-- Migration: 004_create_incident_attachments
-- Description: Create incident attachments table for media files
-- Created at: 2025-12-26

-- Drop table if exists (for clean migration)
DROP TABLE IF EXISTS incident_attachments;

-- Create incident_attachments table
CREATE TABLE incident_attachments (
    id CHAR(36) NOT NULL PRIMARY KEY COMMENT 'UUID primary key',

    -- Parent incident reference
    incident_id CHAR(36) NOT NULL COMMENT 'Reference to incidents table',

    -- File information
    file_name VARCHAR(255) NOT NULL COMMENT 'Original file name',
    file_path VARCHAR(500) NOT NULL COMMENT 'Storage path or URL',
    file_url VARCHAR(500) NOT NULL COMMENT 'Public accessible URL',
    file_type ENUM('image', 'video', 'audio', 'document') NOT NULL COMMENT 'Type of attachment',
    mime_type VARCHAR(100) NOT NULL COMMENT 'MIME type of the file',
    file_size BIGINT UNSIGNED NOT NULL COMMENT 'File size in bytes',

    -- Image/Video specific metadata
    width INT UNSIGNED NULL COMMENT 'Width in pixels (for images/videos)',
    height INT UNSIGNED NULL COMMENT 'Height in pixels (for images/videos)',
    duration INT UNSIGNED NULL COMMENT 'Duration in seconds (for videos/audio)',
    thumbnail_url VARCHAR(500) NULL COMMENT 'Thumbnail URL for videos/images',

    -- Additional metadata
    description TEXT NULL COMMENT 'Optional description of attachment',
    sort_order INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Display order',
    is_primary BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'Primary/featured attachment',

    -- Upload tracking
    uploaded_by CHAR(36) NOT NULL COMMENT 'User who uploaded the file',

    -- Timestamps
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Record creation timestamp',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Record update timestamp',

    -- Foreign key constraints
    CONSTRAINT fk_incident_attachments_incident FOREIGN KEY (incident_id) REFERENCES incidents(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_incident_attachments_uploaded_by FOREIGN KEY (uploaded_by) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Attachments for incident reports';

-- Indexes for performance
CREATE INDEX idx_incident_attachments_incident_id ON incident_attachments(incident_id);
CREATE INDEX idx_incident_attachments_file_type ON incident_attachments(file_type);
CREATE INDEX idx_incident_attachments_uploaded_by ON incident_attachments(uploaded_by);
CREATE INDEX idx_incident_attachments_created_at ON incident_attachments(created_at);
CREATE INDEX idx_incident_attachments_incident_order ON incident_attachments(incident_id, sort_order);
CREATE INDEX idx_incident_attachments_incident_primary ON incident_attachments(incident_id, is_primary);
