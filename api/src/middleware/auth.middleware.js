'use strict';

const { verifyAccessToken } = require('../utils/jwt.utils');
const { errorResponse } = require('../utils/response.utils');
const { query } = require('../config/database');

/**
 * Authentication middleware - Verifies JWT token
 * Attaches user object to request if token is valid
 */
const authenticate = async (req, res, next) => {
  try {
    // Get token from header
    const authHeader = req.headers.authorization;

    if (!authHeader) {
      return errorResponse(res, 'Access denied. No token provided.', 401);
    }

    // Check for Bearer token format
    if (!authHeader.startsWith('Bearer ')) {
      return errorResponse(res, 'Invalid token format. Use Bearer token.', 401);
    }

    // Extract token
    const token = authHeader.split(' ')[1];

    if (!token) {
      return errorResponse(res, 'Access denied. No token provided.', 401);
    }

    // Verify token
    const decoded = verifyAccessToken(token);

    if (!decoded) {
      return errorResponse(res, 'Invalid or expired token.', 401);
    }

    // Get user from database to ensure they still exist and are approved
    const user = await query(
      `SELECT id, email, phone, full_name, role, status, profile_image_url, created_at, updated_at
       FROM users
       WHERE id = ? AND status = 'approved'`,
      [decoded.userId]
    );

    if (!user || user.length === 0) {
      return errorResponse(res, 'User not found or not approved.', 401);
    }

    // Attach user to request object
    req.user = {
      userId: user[0].id,
      id: user[0].id,
      email: user[0].email,
      phone: user[0].phone,
      fullName: user[0].full_name,
      role: user[0].role,
      status: user[0].status,
      profileImageUrl: user[0].profile_image_url,
      createdAt: user[0].created_at,
      updatedAt: user[0].updated_at,
    };

    // Attach token info
    req.tokenInfo = {
      iat: decoded.iat,
      exp: decoded.exp,
    };

    next();
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      return errorResponse(res, 'Token has expired.', 401);
    }
    if (error.name === 'JsonWebTokenError') {
      return errorResponse(res, 'Invalid token.', 401);
    }
    console.error('Authentication error:', error);
    return errorResponse(res, 'Authentication failed.', 500);
  }
};

/**
 * Optional authentication middleware
 * Does not require token but attaches user if valid token is provided
 */
const optionalAuth = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      // No token provided, continue without user
      req.user = null;
      return next();
    }

    const token = authHeader.split(' ')[1];

    if (!token) {
      req.user = null;
      return next();
    }

    const decoded = verifyAccessToken(token);

    if (!decoded) {
      req.user = null;
      return next();
    }

    // Get user from database
    const user = await query(
      `SELECT id, email, phone, full_name, role, status, profile_image_url, created_at, updated_at
       FROM users
       WHERE id = ? AND status = 'approved'`,
      [decoded.userId]
    );

    if (user && user.length > 0) {
      req.user = {
        userId: user[0].id,
        id: user[0].id,
        email: user[0].email,
        phone: user[0].phone,
        fullName: user[0].full_name,
        role: user[0].role,
        status: user[0].status,
        profileImageUrl: user[0].profile_image_url,
        createdAt: user[0].created_at,
        updatedAt: user[0].updated_at,
      };
    } else {
      req.user = null;
    }

    next();
  } catch (error) {
    // On any error, just continue without user
    req.user = null;
    next();
  }
};

/**
 * Refresh token verification middleware
 */
const verifyRefreshToken = async (req, res, next) => {
  try {
    const { refreshToken } = req.body;

    if (!refreshToken) {
      return errorResponse(res, 'Refresh token is required.', 400);
    }

    // Import here to avoid circular dependency
    const jwtUtils = require('../utils/jwt.utils');
    const decoded = jwtUtils.verifyRefreshToken(refreshToken);

    if (!decoded) {
      return errorResponse(res, 'Invalid or expired refresh token.', 401);
    }

    // Check if refresh token exists in database and is valid
    const tokenRecord = await query(
      `SELECT id, user_id, expires_at
       FROM refresh_tokens
       WHERE token = ? AND is_revoked = FALSE AND expires_at > NOW()`,
      [refreshToken]
    );

    if (!tokenRecord || tokenRecord.length === 0) {
      return errorResponse(res, 'Refresh token not found or has been revoked.', 401);
    }

    // Get user
    const user = await query(
      `SELECT id, email, phone, full_name, role, status
       FROM users
       WHERE id = ? AND status = 'approved'`,
      [decoded.userId]
    );

    if (!user || user.length === 0) {
      return errorResponse(res, 'User not found or inactive.', 401);
    }

    req.user = {
      id: user[0].id,
      email: user[0].email,
      phone: user[0].phone,
      fullName: user[0].full_name,
      role: user[0].role,
      status: user[0].status,
    };
    req.refreshTokenRecord = tokenRecord[0];
    req.refreshToken = refreshToken;

    next();
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      return errorResponse(res, 'Refresh token has expired.', 401);
    }
    console.error('Refresh token verification error:', error);
    return errorResponse(res, 'Token verification failed.', 500);
  }
};

module.exports = {
  authenticate,
  optionalAuth,
  verifyRefreshToken,
};
