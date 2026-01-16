'use strict';

/**
 * Jest Test Setup File
 * This file runs before all tests and sets up the test environment
 */

// Mock environment variables
process.env.NODE_ENV = 'test';
process.env.JWT_SECRET = 'test-jwt-secret-key-for-testing';
process.env.JWT_REFRESH_SECRET = 'test-jwt-refresh-secret-key-for-testing';
process.env.JWT_EXPIRES_IN = '15m';
process.env.JWT_REFRESH_EXPIRES_IN = '7d';
process.env.BCRYPT_SALT_ROUNDS = '10';
process.env.DB_HOST = 'localhost';
process.env.DB_PORT = '3306';
process.env.DB_USER = 'test';
process.env.DB_PASSWORD = 'test';
process.env.DB_NAME = 'riderapp_test';

// Mock the database module
jest.mock('../src/config/database', () => ({
  query: jest.fn(),
  getPool: jest.fn(),
  pool: {
    getConnection: jest.fn(),
    query: jest.fn(),
  },
}));

// Mock the logger
jest.mock('../src/utils/logger.utils', () => ({
  info: jest.fn(),
  error: jest.fn(),
  warn: jest.fn(),
  debug: jest.fn(),
}));

// Mock the upload utility
jest.mock('../src/utils/upload.util', () => ({
  deleteFileByUrl: jest.fn().mockResolvedValue(true),
  uploadFile: jest.fn().mockResolvedValue({ url: 'https://example.com/file.jpg' }),
}));

// Increase timeout for async operations
jest.setTimeout(10000);

// Global test utilities
global.testUtils = {
  /**
   * Create a mock user object
   * @param {Object} overrides - Properties to override
   * @returns {Object} Mock user
   */
  createMockUser: (overrides = {}) => ({
    id: 'test-user-id-123',
    email: 'test@example.com',
    phone: '0811111111',
    full_name: 'Test User',
    id_card_number: '1234567890123',
    affiliation: 'Test Affiliation',
    address: '123 Test Street',
    role: 'rider',
    status: 'approved',
    password_hash: '$2a$10$test-hashed-password',
    profile_image_url: null,
    approved_at: new Date(),
    created_at: new Date(),
    updated_at: new Date(),
    last_login_at: null,
    ...overrides,
  }),

  /**
   * Create a mock incident object
   * @param {Object} overrides - Properties to override
   * @returns {Object} Mock incident
   */
  createMockIncident: (overrides = {}) => ({
    id: 'test-incident-id-123',
    reported_by: 'test-user-id-123',
    category: 'general',
    status: 'pending',
    priority: 'medium',
    title: 'Test Incident',
    description: 'This is a test incident description',
    location_lat: 13.7563,
    location_lng: 100.5018,
    location_address: '123 Test Street, Bangkok',
    location_province: 'Bangkok',
    location_district: 'Test District',
    incident_date: new Date(),
    assigned_to: null,
    assigned_at: null,
    reviewed_by: null,
    reviewed_at: null,
    review_notes: null,
    resolved_by: null,
    resolved_at: null,
    resolution_notes: null,
    is_anonymous: false,
    view_count: 0,
    created_at: new Date(),
    updated_at: new Date(),
    ...overrides,
  }),

  /**
   * Create a mock request object
   * @param {Object} options - Request options
   * @returns {Object} Mock request
   */
  createMockRequest: (options = {}) => ({
    headers: options.headers || {},
    body: options.body || {},
    params: options.params || {},
    query: options.query || {},
    user: options.user || null,
    ...options,
  }),

  /**
   * Create a mock response object
   * @returns {Object} Mock response with jest.fn() methods
   */
  createMockResponse: () => {
    const res = {};
    res.status = jest.fn().mockReturnValue(res);
    res.json = jest.fn().mockReturnValue(res);
    res.send = jest.fn().mockReturnValue(res);
    res.set = jest.fn().mockReturnValue(res);
    return res;
  },

  /**
   * Create a mock next function
   * @returns {jest.Mock} Mock next function
   */
  createMockNext: () => jest.fn(),

  /**
   * Generate a valid JWT token for testing
   * @param {Object} payload - Token payload
   * @returns {string} JWT token
   */
  generateTestToken: (payload = {}) => {
    const jwt = require('jsonwebtoken');
    return jwt.sign(
      {
        userId: payload.userId || 'test-user-id-123',
        email: payload.email || 'test@example.com',
        role: payload.role || 'rider',
        type: 'access',
        ...payload,
      },
      process.env.JWT_SECRET,
      { expiresIn: '15m' }
    );
  },

  /**
   * Generate a valid refresh token for testing
   * @param {Object} payload - Token payload
   * @returns {string} JWT refresh token
   */
  generateTestRefreshToken: (payload = {}) => {
    const jwt = require('jsonwebtoken');
    return jwt.sign(
      {
        userId: payload.userId || 'test-user-id-123',
        type: 'refresh',
        ...payload,
      },
      process.env.JWT_REFRESH_SECRET,
      { expiresIn: '7d' }
    );
  },
};

// Clear all mocks after each test
afterEach(() => {
  jest.clearAllMocks();
});

// Clean up after all tests
afterAll(() => {
  jest.resetModules();
});
