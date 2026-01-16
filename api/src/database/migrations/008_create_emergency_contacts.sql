-- Migration: 008_create_emergency_contacts
-- Description: Create emergency contacts table for emergency situations
-- Created at: 2025-12-26

-- Drop table if exists (for clean migration)
DROP TABLE IF EXISTS emergency_contacts;

-- Create emergency_contacts table
CREATE TABLE emergency_contacts (
    id CHAR(36) NOT NULL PRIMARY KEY COMMENT 'UUID primary key',

    -- Contact information
    name VARCHAR(255) NOT NULL COMMENT 'Contact name or organization',
    phone VARCHAR(20) NOT NULL COMMENT 'Phone number',
    phone_secondary VARCHAR(20) NULL COMMENT 'Secondary phone number',
    email VARCHAR(255) NULL COMMENT 'Email address',

    -- Classification
    category ENUM('police', 'hospital', 'fire', 'rescue', 'hotline', 'government', 'other') NOT NULL DEFAULT 'other' COMMENT 'Type of emergency contact',

    -- Description
    description TEXT NULL COMMENT 'Description of the contact/organization',

    -- Location information
    address TEXT NULL COMMENT 'Physical address',
    province VARCHAR(100) NULL COMMENT 'Province',
    district VARCHAR(100) NULL COMMENT 'District',
    location_lat DECIMAL(10, 8) NULL COMMENT 'Latitude coordinate',
    location_lng DECIMAL(11, 8) NULL COMMENT 'Longitude coordinate',

    -- Operating hours
    operating_hours VARCHAR(255) NULL COMMENT 'Operating hours (e.g., 24/7, Mon-Fri 8:00-17:00)',
    is_24_hours BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'Whether available 24/7',

    -- Status and visibility
    is_active BOOLEAN NOT NULL DEFAULT TRUE COMMENT 'Whether contact is active',
    is_nationwide BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'Whether available nationwide',
    priority INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Display priority (higher = more important)',

    -- Media
    icon_url VARCHAR(500) NULL COMMENT 'Icon or logo URL',

    -- Audit
    created_by CHAR(36) NULL COMMENT 'Admin who created the contact',
    updated_by CHAR(36) NULL COMMENT 'Admin who last updated',

    -- Timestamps
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Record creation timestamp',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Record update timestamp',

    -- Foreign key constraints
    CONSTRAINT fk_emergency_contacts_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_emergency_contacts_updated_by FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Emergency contact numbers and information';

-- Indexes for performance
CREATE INDEX idx_emergency_contacts_category ON emergency_contacts(category);
CREATE INDEX idx_emergency_contacts_province ON emergency_contacts(province);
CREATE INDEX idx_emergency_contacts_district ON emergency_contacts(district);
CREATE INDEX idx_emergency_contacts_is_active ON emergency_contacts(is_active);
CREATE INDEX idx_emergency_contacts_is_nationwide ON emergency_contacts(is_nationwide);
CREATE INDEX idx_emergency_contacts_priority ON emergency_contacts(priority);
CREATE INDEX idx_emergency_contacts_is_24_hours ON emergency_contacts(is_24_hours);
CREATE INDEX idx_emergency_contacts_location ON emergency_contacts(location_lat, location_lng);

-- Composite indexes for common queries
CREATE INDEX idx_emergency_contacts_active_category ON emergency_contacts(is_active, category, priority);
CREATE INDEX idx_emergency_contacts_active_province ON emergency_contacts(is_active, province, priority);
CREATE INDEX idx_emergency_contacts_nationwide_active ON emergency_contacts(is_nationwide, is_active, priority);

-- Insert default emergency contacts for Thailand
INSERT INTO emergency_contacts (id, name, phone, category, description, is_24_hours, is_nationwide, priority) VALUES
(UUID(), 'Police Emergency', '191', 'police', 'Thailand Police Emergency Hotline', TRUE, TRUE, 100),
(UUID(), 'Medical Emergency', '1669', 'hospital', 'National Institute for Emergency Medicine (NIEM)', TRUE, TRUE, 99),
(UUID(), 'Fire Department', '199', 'fire', 'Fire Emergency Hotline', TRUE, TRUE, 98),
(UUID(), 'Tourist Police', '1155', 'police', 'Tourist Police Hotline', TRUE, TRUE, 90),
(UUID(), 'Highway Police', '1193', 'police', 'Highway Police Hotline', TRUE, TRUE, 85),
(UUID(), 'Rescue Foundation', '1554', 'rescue', 'Ruamkatanyu Foundation Rescue', TRUE, TRUE, 80);
