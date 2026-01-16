-- Migration: 016_add_created_by_to_conversations
-- Description: Add created_by column to conversations table
-- Created at: 2026-01-16

-- Add created_by column to track who created the conversation
ALTER TABLE conversations
ADD COLUMN created_by CHAR(36) NULL COMMENT 'User who created the conversation'
AFTER title;

-- Add foreign key constraint
ALTER TABLE conversations
ADD CONSTRAINT fk_conversations_created_by
FOREIGN KEY (created_by) REFERENCES users(id)
ON DELETE SET NULL ON UPDATE CASCADE;

-- Add index for performance
CREATE INDEX idx_conversations_created_by ON conversations(created_by);
