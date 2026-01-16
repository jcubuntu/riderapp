-- Migration: 002_create_refresh_tokens
-- Description: Create refresh tokens table for JWT token management
-- Created at: 2025-12-26

-- Drop table if exists (for clean migration)
DROP TABLE IF EXISTS refresh_tokens;

-- Create refresh_tokens table
CREATE TABLE refresh_tokens (
    id CHAR(36) NOT NULL PRIMARY KEY COMMENT 'UUID primary key',

    -- Token data
    user_id CHAR(36) NOT NULL COMMENT 'Reference to users table',
    token VARCHAR(500) NOT NULL COMMENT 'Refresh token value',
    token_hash VARCHAR(255) NOT NULL COMMENT 'Hashed refresh token for secure lookup',

    -- Device information
    device_name VARCHAR(255) NULL COMMENT 'Name of the device',
    device_type VARCHAR(50) NULL COMMENT 'Type of device (ios, android, web)',
    ip_address VARCHAR(45) NULL COMMENT 'IP address when token was issued',
    user_agent TEXT NULL COMMENT 'User agent string',

    -- Token validity
    expires_at DATETIME NOT NULL COMMENT 'Token expiration timestamp',
    is_revoked BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'Whether token has been revoked',
    revoked_at DATETIME NULL COMMENT 'When token was revoked',
    revoked_reason VARCHAR(255) NULL COMMENT 'Reason for revocation',

    -- Timestamps
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Record creation timestamp',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Record update timestamp',
    last_used_at DATETIME NULL COMMENT 'Last time token was used',

    -- Foreign key constraint
    CONSTRAINT fk_refresh_tokens_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Refresh tokens for JWT authentication';

-- Indexes for performance
CREATE INDEX idx_refresh_tokens_user_id ON refresh_tokens(user_id);
CREATE INDEX idx_refresh_tokens_token_hash ON refresh_tokens(token_hash);
CREATE INDEX idx_refresh_tokens_expires_at ON refresh_tokens(expires_at);
CREATE INDEX idx_refresh_tokens_is_revoked ON refresh_tokens(is_revoked);
CREATE INDEX idx_refresh_tokens_user_active ON refresh_tokens(user_id, is_revoked, expires_at);
CREATE INDEX idx_refresh_tokens_created_at ON refresh_tokens(created_at);
