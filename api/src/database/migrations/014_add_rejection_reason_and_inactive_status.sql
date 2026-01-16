-- Migration: 014_add_rejection_reason_and_inactive_status
-- Description: Add rejection_reason column and inactive status to users table
-- Created at: 2026-01-15

-- Add rejection_reason column for tracking why a user was rejected
ALTER TABLE users
ADD COLUMN rejection_reason VARCHAR(500) NULL COMMENT 'Reason for rejection if user was rejected'
AFTER approved_at;

-- Modify status ENUM to include 'inactive' status for soft delete functionality
ALTER TABLE users
MODIFY COLUMN status ENUM('pending', 'approved', 'rejected', 'suspended', 'inactive') NOT NULL DEFAULT 'pending'
COMMENT 'Account approval status: pending (awaiting approval), approved (active), rejected (denied), suspended (temporarily disabled), inactive (soft deleted)';
