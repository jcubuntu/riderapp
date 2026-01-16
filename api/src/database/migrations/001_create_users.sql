-- Migration: 001_create_users
-- Description: Create users table for RiderApp
-- Created at: 2025-12-26

-- Drop table if exists (for clean migration)
DROP TABLE IF EXISTS users;

-- Create users table
CREATE TABLE users (
    id CHAR(36) NOT NULL PRIMARY KEY COMMENT 'UUID primary key',

    -- Authentication fields
    email VARCHAR(255) NOT NULL COMMENT 'User email address',
    password_hash VARCHAR(255) NOT NULL COMMENT 'Bcrypt hashed password',

    -- Personal information
    phone VARCHAR(20) NULL COMMENT 'Phone number',
    full_name VARCHAR(255) NOT NULL COMMENT 'Full name of user',
    id_card_number VARCHAR(20) NULL COMMENT 'Thai national ID card number',

    -- Additional information
    affiliation VARCHAR(255) NULL COMMENT 'Organization or affiliation',
    address TEXT NULL COMMENT 'User address',

    -- Role and status
    role ENUM('rider', 'police', 'admin') NOT NULL DEFAULT 'rider' COMMENT 'User role in the system',
    status ENUM('pending', 'approved', 'rejected', 'suspended') NOT NULL DEFAULT 'pending' COMMENT 'Account approval status',

    -- Profile and device
    profile_image_url VARCHAR(500) NULL COMMENT 'URL to profile image',
    device_token VARCHAR(500) NULL COMMENT 'FCM device token for push notifications',

    -- Approval tracking
    approved_by CHAR(36) NULL COMMENT 'UUID of admin who approved this user',
    approved_at DATETIME NULL COMMENT 'Timestamp when user was approved',

    -- Timestamps
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Record creation timestamp',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Record update timestamp',
    last_login_at DATETIME NULL COMMENT 'Last login timestamp',

    -- Constraints
    CONSTRAINT uk_users_email UNIQUE (email),
    CONSTRAINT uk_users_id_card_number UNIQUE (id_card_number),

    -- Foreign key for self-reference (approved_by)
    CONSTRAINT fk_users_approved_by FOREIGN KEY (approved_by) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Users table for RiderApp authentication and profile';

-- Indexes for performance
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_status ON users(status);
CREATE INDEX idx_users_role_status ON users(role, status);
CREATE INDEX idx_users_created_at ON users(created_at);
CREATE INDEX idx_users_approved_by ON users(approved_by);
CREATE INDEX idx_users_device_token ON users(device_token(255));
