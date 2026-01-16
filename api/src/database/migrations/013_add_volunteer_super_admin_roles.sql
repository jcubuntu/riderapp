-- Add volunteer and super_admin roles to users table
-- Volunteer: Police assistant with similar permissions to police (cannot approve users)
-- Super Admin: Full system control including admin management and system config

-- Modify role ENUM to include new roles
ALTER TABLE users
MODIFY COLUMN role ENUM('rider', 'police', 'admin', 'volunteer', 'super_admin') NOT NULL DEFAULT 'rider';

-- Add index for new roles (optional, for query optimization)
-- The existing index on role column will automatically include new values
