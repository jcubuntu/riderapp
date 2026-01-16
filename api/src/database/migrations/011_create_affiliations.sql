-- Migration: Create affiliations table
-- This table stores the list of affiliations/organizations that riders can belong to
-- Admin users can manage these affiliations (add/delete)

CREATE TABLE IF NOT EXISTS affiliations (
  id CHAR(36) NOT NULL PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE,
  description VARCHAR(255),
  is_active BOOLEAN DEFAULT TRUE,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  created_by CHAR(36) NULL,

  INDEX idx_affiliations_name (name),
  INDEX idx_affiliations_active (is_active),

  CONSTRAINT fk_affiliations_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Insert default affiliations
INSERT INTO affiliations (id, name, description) VALUES
  (UUID(), 'Grab', 'Grab delivery service'),
  (UUID(), 'Bolt', 'Bolt delivery service'),
  (UUID(), 'LINE MAN', 'LINE MAN delivery service'),
  (UUID(), 'Robinhood', 'Robinhood delivery service'),
  (UUID(), 'foodpanda', 'foodpanda delivery service'),
  (UUID(), 'ShopeeFood', 'ShopeeFood delivery service'),
  (UUID(), 'Lalamove', 'Lalamove delivery service'),
  (UUID(), 'อิสระ', 'Independent rider / ไรเดอร์อิสระ'),
  (UUID(), 'อื่นๆ', 'Other / อื่นๆ');
