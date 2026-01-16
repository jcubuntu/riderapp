-- Create locations table for tracking rider positions
CREATE TABLE IF NOT EXISTS locations (
  id VARCHAR(36) PRIMARY KEY,
  user_id VARCHAR(36) NOT NULL,
  latitude DECIMAL(10, 8) NOT NULL,
  longitude DECIMAL(11, 8) NOT NULL,
  accuracy DECIMAL(8, 2),
  altitude DECIMAL(10, 2),
  speed DECIMAL(8, 2),
  heading DECIMAL(5, 2),
  address VARCHAR(500),
  province VARCHAR(100),
  district VARCHAR(100),
  is_sharing BOOLEAN DEFAULT FALSE,
  battery_level INT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_user_sharing (user_id, is_sharing),
  INDEX idx_created_at (created_at),
  INDEX idx_location (latitude, longitude)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Create location_sharing_settings table
CREATE TABLE IF NOT EXISTS location_sharing_settings (
  id VARCHAR(36) PRIMARY KEY,
  user_id VARCHAR(36) NOT NULL UNIQUE,
  is_enabled BOOLEAN DEFAULT FALSE,
  share_with_police BOOLEAN DEFAULT TRUE,
  share_with_volunteers BOOLEAN DEFAULT TRUE,
  share_in_emergency BOOLEAN DEFAULT TRUE,
  auto_share_on_incident BOOLEAN DEFAULT TRUE,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
