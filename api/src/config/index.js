'use strict';

require('dotenv').config();

/**
 * Parse comma-separated string to array
 * @param {string} value - Comma-separated string
 * @param {string[]} defaultValue - Default array value
 * @returns {string[]}
 */
const parseArrayEnv = (value, defaultValue = []) => {
  if (!value) return defaultValue;
  return value.split(',').map((item) => item.trim()).filter(Boolean);
};

/**
 * Parse boolean from string
 * @param {string} value - String value
 * @param {boolean} defaultValue - Default boolean value
 * @returns {boolean}
 */
const parseBoolEnv = (value, defaultValue = false) => {
  if (value === undefined || value === null || value === '') return defaultValue;
  return value.toLowerCase() === 'true' || value === '1';
};

/**
 * Parse integer from string
 * @param {string} value - String value
 * @param {number} defaultValue - Default number value
 * @returns {number}
 */
const parseIntEnv = (value, defaultValue = 0) => {
  const parsed = parseInt(value, 10);
  return isNaN(parsed) ? defaultValue : parsed;
};

// Configuration object
const config = {
  // Server configuration
  nodeEnv: process.env.NODE_ENV || 'development',
  port: parseIntEnv(process.env.PORT, 3000),
  apiVersion: process.env.API_VERSION || 'v1',
  isDevelopment: process.env.NODE_ENV !== 'production',
  isProduction: process.env.NODE_ENV === 'production',
  isTest: process.env.NODE_ENV === 'test',

  // Database configuration
  database: {
    host: process.env.DB_HOST || 'localhost',
    port: parseIntEnv(process.env.DB_PORT, 3306),
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    name: process.env.DB_NAME || 'riderapp',
    connectionLimit: parseIntEnv(process.env.DB_CONNECTION_LIMIT, 10),
  },

  // JWT configuration
  jwt: {
    secret: process.env.JWT_SECRET || 'default-jwt-secret-change-in-production',
    expiresIn: process.env.JWT_EXPIRES_IN || '7d',
    refreshSecret: process.env.JWT_REFRESH_SECRET || 'default-refresh-secret-change-in-production',
    refreshExpiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '30d',
  },

  // Bcrypt configuration
  bcrypt: {
    saltRounds: parseIntEnv(process.env.BCRYPT_SALT_ROUNDS, 12),
  },

  // CORS configuration
  cors: {
    origin: parseArrayEnv(process.env.CORS_ORIGIN, ['http://localhost:3000']),
  },

  // Rate limiting configuration
  rateLimit: {
    windowMs: parseIntEnv(process.env.RATE_LIMIT_WINDOW_MS, 900000), // 15 minutes
    maxRequests: parseIntEnv(process.env.RATE_LIMIT_MAX_REQUESTS, 100),
  },

  // File upload configuration
  upload: {
    maxFileSize: parseIntEnv(process.env.MAX_FILE_SIZE, 5 * 1024 * 1024), // 5MB
    uploadDir: process.env.UPLOAD_DIR || './uploads',
    allowedMimeTypes: [
      'image/jpeg',
      'image/png',
      'image/gif',
      'image/webp',
      'application/pdf',
      'video/mp4',
      'video/quicktime',
    ],
    allowedImageTypes: ['image/jpeg', 'image/png', 'image/gif', 'image/webp'],
  },

  // Logging configuration
  logging: {
    level: process.env.LOG_LEVEL || 'debug',
    dir: process.env.LOG_DIR || './logs',
  },

  // Socket.IO configuration
  socket: {
    corsOrigin: parseArrayEnv(process.env.SOCKET_CORS_ORIGIN, ['http://localhost:3000']),
  },

  // Pagination defaults
  pagination: {
    defaultPage: 1,
    defaultLimit: 10,
    maxLimit: 100,
  },

  // External APIs (if needed)
  externalApis: {
    googleMapsApiKey: process.env.GOOGLE_MAPS_API_KEY || '',
    firebaseApiKey: process.env.FIREBASE_API_KEY || '',
  },
};

// Validate required configuration
const validateConfig = () => {
  const requiredEnvVars = ['DB_HOST', 'DB_USER', 'DB_NAME'];
  const missingVars = requiredEnvVars.filter((envVar) => !process.env[envVar]);

  if (missingVars.length > 0 && config.isProduction) {
    console.warn(`Warning: Missing required environment variables: ${missingVars.join(', ')}`);
  }

  // Warn about default secrets in production
  if (config.isProduction) {
    if (config.jwt.secret === 'default-jwt-secret-change-in-production') {
      console.warn('Warning: Using default JWT secret in production!');
    }
    if (config.jwt.refreshSecret === 'default-refresh-secret-change-in-production') {
      console.warn('Warning: Using default refresh token secret in production!');
    }
  }
};

// Run validation
validateConfig();

module.exports = config;
