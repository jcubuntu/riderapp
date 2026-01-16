-- Migration: 019_add_commander_test_user
-- Description: Add test user with commander role
-- Created at: 2026-01-16

-- Insert commander test user (phone: 0866666666, password: Test1234)
INSERT INTO users (
    id,
    phone,
    password_hash,
    full_name,
    role,
    status,
    created_at,
    updated_at
) VALUES (
    UUID(),
    '0866666666',
    '$2a$10$8RcVmJRatkMddauZ9G37ruN5wtUoYAjVe7x6Ks57RwMtm5/gOu77m',
    'Test Commander',
    'commander',
    'approved',
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
);
