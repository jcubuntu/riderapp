-- Migration: 003_create_incidents
-- Description: Create incidents table for reporting incidents
-- Created at: 2025-12-26

-- Drop table if exists (for clean migration)
DROP TABLE IF EXISTS incidents;

-- Create incidents table
CREATE TABLE incidents (
    id CHAR(36) NOT NULL PRIMARY KEY COMMENT 'UUID primary key',

    -- Reporter information
    reported_by CHAR(36) NOT NULL COMMENT 'User who reported the incident',

    -- Incident classification
    category ENUM('intelligence', 'accident', 'general') NOT NULL DEFAULT 'general' COMMENT 'Type of incident',
    status ENUM('pending', 'reviewing', 'verified', 'resolved', 'rejected') NOT NULL DEFAULT 'pending' COMMENT 'Current status of incident',
    priority ENUM('low', 'medium', 'high', 'critical') NOT NULL DEFAULT 'medium' COMMENT 'Priority level',

    -- Incident details
    title VARCHAR(255) NOT NULL COMMENT 'Brief title of the incident',
    description TEXT NOT NULL COMMENT 'Detailed description of the incident',

    -- Location information
    location_lat DECIMAL(10, 8) NULL COMMENT 'Latitude coordinate',
    location_lng DECIMAL(11, 8) NULL COMMENT 'Longitude coordinate',
    location_address TEXT NULL COMMENT 'Human-readable address',
    location_province VARCHAR(100) NULL COMMENT 'Province/State',
    location_district VARCHAR(100) NULL COMMENT 'District/County',

    -- Incident timing
    incident_date DATETIME NULL COMMENT 'When the incident occurred',

    -- Assignment and handling
    assigned_to CHAR(36) NULL COMMENT 'Police officer assigned to handle',
    assigned_at DATETIME NULL COMMENT 'When the incident was assigned',

    -- Review information
    reviewed_by CHAR(36) NULL COMMENT 'Who reviewed the incident',
    reviewed_at DATETIME NULL COMMENT 'When the incident was reviewed',
    review_notes TEXT NULL COMMENT 'Notes from the reviewer',

    -- Resolution information
    resolved_by CHAR(36) NULL COMMENT 'Who resolved the incident',
    resolved_at DATETIME NULL COMMENT 'When the incident was resolved',
    resolution_notes TEXT NULL COMMENT 'Notes about the resolution',

    -- Additional metadata
    is_anonymous BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'Whether the report is anonymous',
    view_count INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Number of times viewed',

    -- Timestamps
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Record creation timestamp',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Record update timestamp',

    -- Foreign key constraints
    CONSTRAINT fk_incidents_reported_by FOREIGN KEY (reported_by) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_incidents_assigned_to FOREIGN KEY (assigned_to) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_incidents_reviewed_by FOREIGN KEY (reviewed_by) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_incidents_resolved_by FOREIGN KEY (resolved_by) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Incidents reported by riders';

-- Indexes for performance
CREATE INDEX idx_incidents_reported_by ON incidents(reported_by);
CREATE INDEX idx_incidents_category ON incidents(category);
CREATE INDEX idx_incidents_status ON incidents(status);
CREATE INDEX idx_incidents_priority ON incidents(priority);
CREATE INDEX idx_incidents_category_status ON incidents(category, status);
CREATE INDEX idx_incidents_status_priority ON incidents(status, priority);
CREATE INDEX idx_incidents_assigned_to ON incidents(assigned_to);
CREATE INDEX idx_incidents_reviewed_by ON incidents(reviewed_by);
CREATE INDEX idx_incidents_resolved_by ON incidents(resolved_by);
CREATE INDEX idx_incidents_location ON incidents(location_lat, location_lng);
CREATE INDEX idx_incidents_province ON incidents(location_province);
CREATE INDEX idx_incidents_incident_date ON incidents(incident_date);
CREATE INDEX idx_incidents_created_at ON incidents(created_at);
CREATE INDEX idx_incidents_updated_at ON incidents(updated_at);

-- Spatial index for location-based queries (if needed)
-- Note: For full spatial support, consider using POINT geometry type
