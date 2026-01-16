-- Migration: Make email column nullable
-- Email is no longer required for registration - users login with phone number

-- Remove NOT NULL constraint from email
ALTER TABLE users MODIFY COLUMN email VARCHAR(255) NULL;

-- Drop unique constraint on email (named uk_users_email in 001_create_users.sql)
ALTER TABLE users DROP INDEX uk_users_email;

-- Drop the idx_users_email index that was created in 001_create_users.sql
ALTER TABLE users DROP INDEX idx_users_email;

-- Add unique constraint to phone number (drop existing non-unique index first)
ALTER TABLE users DROP INDEX idx_users_phone;
ALTER TABLE users ADD UNIQUE INDEX uk_users_phone (phone);
