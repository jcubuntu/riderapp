-- Migration: 017_add_commander_role
-- Description: Add commander role to users table
-- Created at: 2026-01-16

-- Modify the role enum to include commander
-- Note: In MySQL/MariaDB, we need to alter the column to add new enum values

ALTER TABLE users
MODIFY COLUMN role ENUM('rider', 'volunteer', 'police', 'commander', 'admin', 'super_admin')
NOT NULL DEFAULT 'rider'
COMMENT 'User role: rider, volunteer, police, commander, admin, super_admin';
