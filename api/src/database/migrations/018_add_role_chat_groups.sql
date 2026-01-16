-- Migration: 018_add_role_chat_groups
-- Description: Add role-based chat groups and minimum_role column
-- Created at: 2026-01-16

-- Add minimum_role column to conversations for role-based access control
-- Note: Column may already exist from partial migration
-- ALTER TABLE conversations
-- ADD COLUMN minimum_role ENUM('rider', 'volunteer', 'police', 'commander', 'admin', 'super_admin') NULL
-- COMMENT 'Minimum role required to access this conversation (for role-based groups)'
-- AFTER type;

-- Add index for minimum_role (ignore if exists)
-- CREATE INDEX idx_conversations_minimum_role ON conversations(minimum_role);

-- Create system chat groups based on role hierarchy
-- These are predefined groups that users can join based on their role

-- 1. General Group (all users - minimum role: rider)
INSERT INTO conversations (id, type, title, minimum_role, status, created_at, updated_at)
VALUES (
    '00000000-0000-0000-0000-000000000001',
    'group',
    'General',
    'rider',
    'active',
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
);

-- 2. Volunteer Group (volunteer and above)
INSERT INTO conversations (id, type, title, minimum_role, status, created_at, updated_at)
VALUES (
    '00000000-0000-0000-0000-000000000002',
    'group',
    'อส. (Volunteer)',
    'volunteer',
    'active',
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
);

-- 3. Police Group (police and above)
INSERT INTO conversations (id, type, title, minimum_role, status, created_at, updated_at)
VALUES (
    '00000000-0000-0000-0000-000000000003',
    'group',
    'Police',
    'police',
    'active',
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
);

-- 4. Commander Group (commander and above)
INSERT INTO conversations (id, type, title, minimum_role, status, created_at, updated_at)
VALUES (
    '00000000-0000-0000-0000-000000000004',
    'group',
    'Commander',
    'commander',
    'active',
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
);

-- 5. Admin Group (admin and above)
INSERT INTO conversations (id, type, title, minimum_role, status, created_at, updated_at)
VALUES (
    '00000000-0000-0000-0000-000000000005',
    'group',
    'Admin',
    'admin',
    'active',
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
);
