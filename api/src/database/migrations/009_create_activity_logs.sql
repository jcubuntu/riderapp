-- Migration: 009_create_activity_logs
-- Description: Create activity logs table for audit trail
-- Created at: 2025-12-26

-- Drop table if exists (for clean migration)
DROP TABLE IF EXISTS activity_logs;

-- Create activity_logs table
CREATE TABLE activity_logs (
    id CHAR(36) NOT NULL PRIMARY KEY COMMENT 'UUID primary key',

    -- Actor information
    user_id CHAR(36) NULL COMMENT 'User who performed the action (null for system actions)',
    user_role VARCHAR(50) NULL COMMENT 'Role of user at time of action',
    user_email VARCHAR(255) NULL COMMENT 'Email of user at time of action (for historical tracking)',

    -- Action details
    action VARCHAR(100) NOT NULL COMMENT 'Action performed (e.g., login, create_incident, approve_user)',
    action_type ENUM('auth', 'create', 'read', 'update', 'delete', 'admin', 'system') NOT NULL COMMENT 'Category of action',

    -- Target entity
    entity_type VARCHAR(100) NULL COMMENT 'Type of entity affected (e.g., user, incident, announcement)',
    entity_id CHAR(36) NULL COMMENT 'ID of the entity affected',
    entity_name VARCHAR(255) NULL COMMENT 'Name/title of entity for display purposes',

    -- Change details
    old_values JSON NULL COMMENT 'Previous values before change',
    new_values JSON NULL COMMENT 'New values after change',
    changes_summary TEXT NULL COMMENT 'Human-readable summary of changes',

    -- Request context
    ip_address VARCHAR(45) NULL COMMENT 'IP address of request',
    user_agent TEXT NULL COMMENT 'User agent string',
    request_method VARCHAR(10) NULL COMMENT 'HTTP method (GET, POST, etc.)',
    request_path VARCHAR(500) NULL COMMENT 'Request URL path',
    request_id CHAR(36) NULL COMMENT 'Unique request identifier for correlation',

    -- Status
    status ENUM('success', 'failure', 'error') NOT NULL DEFAULT 'success' COMMENT 'Outcome of the action',
    error_message TEXT NULL COMMENT 'Error message if action failed',

    -- Additional metadata
    metadata JSON NULL COMMENT 'Additional context as JSON',
    duration_ms INT UNSIGNED NULL COMMENT 'Duration of action in milliseconds',

    -- Timestamps
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'When the action occurred',

    -- Foreign key constraint (soft reference - user might be deleted)
    CONSTRAINT fk_activity_logs_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Audit trail for all system activities';

-- Indexes for performance
CREATE INDEX idx_activity_logs_user_id ON activity_logs(user_id);
CREATE INDEX idx_activity_logs_action ON activity_logs(action);
CREATE INDEX idx_activity_logs_action_type ON activity_logs(action_type);
CREATE INDEX idx_activity_logs_entity_type ON activity_logs(entity_type);
CREATE INDEX idx_activity_logs_entity_id ON activity_logs(entity_id);
CREATE INDEX idx_activity_logs_status ON activity_logs(status);
CREATE INDEX idx_activity_logs_ip_address ON activity_logs(ip_address);
CREATE INDEX idx_activity_logs_request_id ON activity_logs(request_id);
CREATE INDEX idx_activity_logs_created_at ON activity_logs(created_at);

-- Composite indexes for common queries
CREATE INDEX idx_activity_logs_user_created ON activity_logs(user_id, created_at);
CREATE INDEX idx_activity_logs_entity_created ON activity_logs(entity_type, entity_id, created_at);
CREATE INDEX idx_activity_logs_action_created ON activity_logs(action, created_at);
CREATE INDEX idx_activity_logs_type_status ON activity_logs(action_type, status, created_at);

-- Index for security audit queries
CREATE INDEX idx_activity_logs_auth_actions ON activity_logs(action_type, status, ip_address, created_at);

-- Partitioning hint: Consider partitioning by created_at for large datasets
-- ALTER TABLE activity_logs PARTITION BY RANGE (TO_DAYS(created_at)) (
--     PARTITION p_2024_q1 VALUES LESS THAN (TO_DAYS('2024-04-01')),
--     PARTITION p_2024_q2 VALUES LESS THAN (TO_DAYS('2024-07-01')),
--     PARTITION p_2024_q3 VALUES LESS THAN (TO_DAYS('2024-10-01')),
--     PARTITION p_2024_q4 VALUES LESS THAN (TO_DAYS('2025-01-01')),
--     PARTITION p_future VALUES LESS THAN MAXVALUE
-- );
