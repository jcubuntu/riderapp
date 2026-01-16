'use strict';

const jwt = require('jsonwebtoken');
const config = require('../config');

/**
 * Generate access token
 * @param {Object} payload - Token payload
 * @param {string|number} payload.userId - User ID
 * @param {string} payload.email - User email
 * @param {string} payload.role - User role
 * @returns {string} JWT access token
 */
const generateAccessToken = (payload) => {
  const tokenPayload = {
    userId: payload.userId,
    email: payload.email,
    role: payload.role,
    type: 'access',
  };

  return jwt.sign(tokenPayload, config.jwt.secret, {
    expiresIn: config.jwt.expiresIn,
    issuer: 'riderapp-api',
    audience: 'riderapp-client',
  });
};

/**
 * Generate refresh token
 * @param {Object} payload - Token payload
 * @param {string|number} payload.userId - User ID
 * @returns {string} JWT refresh token
 */
const generateRefreshToken = (payload) => {
  const tokenPayload = {
    userId: payload.userId,
    type: 'refresh',
  };

  return jwt.sign(tokenPayload, config.jwt.refreshSecret, {
    expiresIn: config.jwt.refreshExpiresIn,
    issuer: 'riderapp-api',
    audience: 'riderapp-client',
  });
};

/**
 * Generate both access and refresh tokens
 * @param {Object} user - User object
 * @param {string|number} user.id - User ID
 * @param {string} user.email - User email
 * @param {string} user.role - User role
 * @returns {Object} Object containing accessToken and refreshToken
 */
const generateTokenPair = (user) => {
  const accessToken = generateAccessToken({
    userId: user.id,
    email: user.email,
    role: user.role,
  });

  const refreshToken = generateRefreshToken({
    userId: user.id,
  });

  return {
    accessToken,
    refreshToken,
    tokenType: 'Bearer',
    expiresIn: config.jwt.expiresIn,
  };
};

/**
 * Verify access token
 * @param {string} token - JWT access token
 * @returns {Object|null} Decoded token payload or null if invalid
 */
const verifyAccessToken = (token) => {
  try {
    const decoded = jwt.verify(token, config.jwt.secret, {
      issuer: 'riderapp-api',
      audience: 'riderapp-client',
    });

    // Ensure it's an access token
    if (decoded.type !== 'access') {
      return null;
    }

    return decoded;
  } catch (error) {
    // Re-throw for specific error handling
    if (error.name === 'TokenExpiredError' || error.name === 'JsonWebTokenError') {
      throw error;
    }
    return null;
  }
};

/**
 * Verify refresh token
 * @param {string} token - JWT refresh token
 * @returns {Object|null} Decoded token payload or null if invalid
 */
const verifyRefreshToken = (token) => {
  try {
    const decoded = jwt.verify(token, config.jwt.refreshSecret, {
      issuer: 'riderapp-api',
      audience: 'riderapp-client',
    });

    // Ensure it's a refresh token
    if (decoded.type !== 'refresh') {
      return null;
    }

    return decoded;
  } catch (error) {
    if (error.name === 'TokenExpiredError' || error.name === 'JsonWebTokenError') {
      throw error;
    }
    return null;
  }
};

/**
 * Decode token without verification (for debugging/logging)
 * @param {string} token - JWT token
 * @returns {Object|null} Decoded token payload or null if invalid format
 */
const decodeToken = (token) => {
  try {
    return jwt.decode(token);
  } catch (error) {
    return null;
  }
};

/**
 * Get token expiration time
 * @param {string} token - JWT token
 * @returns {Date|null} Expiration date or null if invalid
 */
const getTokenExpiration = (token) => {
  const decoded = decodeToken(token);
  if (!decoded || !decoded.exp) {
    return null;
  }
  return new Date(decoded.exp * 1000);
};

/**
 * Check if token is expired
 * @param {string} token - JWT token
 * @returns {boolean} True if expired, false otherwise
 */
const isTokenExpired = (token) => {
  const expiration = getTokenExpiration(token);
  if (!expiration) {
    return true;
  }
  return expiration < new Date();
};

/**
 * Get remaining time until token expires (in seconds)
 * @param {string} token - JWT token
 * @returns {number} Remaining seconds or 0 if expired
 */
const getTokenRemainingTime = (token) => {
  const expiration = getTokenExpiration(token);
  if (!expiration) {
    return 0;
  }
  const remaining = Math.floor((expiration.getTime() - Date.now()) / 1000);
  return Math.max(0, remaining);
};

/**
 * Calculate refresh token expiration date
 * @returns {Date} Expiration date for refresh token
 */
const getRefreshTokenExpirationDate = () => {
  const expiresIn = config.jwt.refreshExpiresIn;
  const now = new Date();

  // Parse expiration string (e.g., "30d", "7d", "24h")
  const match = expiresIn.match(/^(\d+)([dhms])$/);
  if (!match) {
    // Default to 30 days
    return new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000);
  }

  const value = parseInt(match[1], 10);
  const unit = match[2];

  let milliseconds;
  switch (unit) {
    case 'd':
      milliseconds = value * 24 * 60 * 60 * 1000;
      break;
    case 'h':
      milliseconds = value * 60 * 60 * 1000;
      break;
    case 'm':
      milliseconds = value * 60 * 1000;
      break;
    case 's':
      milliseconds = value * 1000;
      break;
    default:
      milliseconds = 30 * 24 * 60 * 60 * 1000;
  }

  return new Date(now.getTime() + milliseconds);
};

module.exports = {
  generateAccessToken,
  generateRefreshToken,
  generateTokenPair,
  verifyAccessToken,
  verifyRefreshToken,
  decodeToken,
  getTokenExpiration,
  isTokenExpired,
  getTokenRemainingTime,
  getRefreshTokenExpirationDate,
};
