'use strict';

const { v4: uuidv4 } = require('uuid');
const crypto = require('crypto');
const db = require('../../config/database');
const jwtUtils = require('../../utils/jwt.utils');

/**
 * User Repository - Database operations for users
 */

/**
 * Find user by email
 * @param {string} email - User email
 * @returns {Promise<Object|null>} User object or null
 */
const findByEmail = async (email) => {
  const sql = `
    SELECT id, email, password_hash, phone, full_name, id_card_number,
           affiliation, address, role, status, profile_image_url,
           device_token, approved_by, approved_at, created_at, updated_at, last_login_at
    FROM users
    WHERE email = ?
  `;
  return db.queryOne(sql, [email]);
};

/**
 * Find user by ID
 * @param {string} id - User UUID
 * @returns {Promise<Object|null>} User object or null
 */
const findById = async (id) => {
  const sql = `
    SELECT id, email, phone, full_name, id_card_number,
           affiliation, address, role, status, profile_image_url,
           device_token, approved_by, approved_at, created_at, updated_at, last_login_at
    FROM users
    WHERE id = ?
  `;
  return db.queryOne(sql, [id]);
};

/**
 * Find user by ID card number
 * @param {string} idCardNumber - Thai ID card number
 * @returns {Promise<Object|null>} User object or null
 */
const findByIdCardNumber = async (idCardNumber) => {
  const sql = `
    SELECT id, email, phone, full_name, id_card_number,
           affiliation, address, role, status, profile_image_url,
           approved_by, approved_at, created_at, updated_at
    FROM users
    WHERE id_card_number = ?
  `;
  return db.queryOne(sql, [idCardNumber]);
};

/**
 * Find user by phone number
 * @param {string} phone - Phone number
 * @returns {Promise<Object|null>} User object or null
 */
const findByPhone = async (phone) => {
  const sql = `
    SELECT id, email, password_hash, phone, full_name, id_card_number,
           affiliation, address, role, status, profile_image_url,
           device_token, approved_by, approved_at, created_at, updated_at, last_login_at
    FROM users
    WHERE phone = ?
  `;
  return db.queryOne(sql, [phone]);
};

/**
 * Create a new user
 * @param {Object} userData - User data
 * @returns {Promise<Object>} Created user
 */
const create = async (userData) => {
  const id = uuidv4();
  const sql = `
    INSERT INTO users (id, email, password_hash, phone, full_name, id_card_number,
                       affiliation, address, role, status)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `;

  await db.insert(sql, [
    id,
    userData.email,
    userData.passwordHash,
    userData.phone,
    userData.fullName,
    userData.idCardNumber,
    userData.affiliation || null,
    userData.address || null,
    userData.role || 'rider',
    userData.status || 'pending',
  ]);

  return findById(id);
};

/**
 * Update user by ID
 * @param {string} id - User UUID
 * @param {Object} updates - Fields to update
 * @returns {Promise<Object>} Updated user
 */
const update = async (id, updates) => {
  const allowedFields = [
    'email', 'phone', 'full_name', 'id_card_number',
    'affiliation', 'address', 'status', 'profile_image_url',
    'device_token', 'approved_by', 'approved_at', 'last_login_at',
  ];

  const updatePairs = [];
  const values = [];

  for (const [key, value] of Object.entries(updates)) {
    const dbKey = key.replace(/([A-Z])/g, '_$1').toLowerCase();
    if (allowedFields.includes(dbKey)) {
      updatePairs.push(`${dbKey} = ?`);
      values.push(value);
    }
  }

  if (updatePairs.length === 0) {
    return findById(id);
  }

  values.push(id);

  const sql = `
    UPDATE users
    SET ${updatePairs.join(', ')}
    WHERE id = ?
  `;

  await db.update(sql, values);
  return findById(id);
};

/**
 * Update user's last login timestamp
 * @param {string} id - User UUID
 * @returns {Promise<void>}
 */
const updateLastLogin = async (id) => {
  const sql = `
    UPDATE users
    SET last_login_at = CURRENT_TIMESTAMP
    WHERE id = ?
  `;
  await db.update(sql, [id]);
};

/**
 * Update user password
 * @param {string} id - User UUID
 * @param {string} passwordHash - New hashed password
 * @returns {Promise<void>}
 */
const updatePassword = async (id, passwordHash) => {
  const sql = `
    UPDATE users
    SET password_hash = ?
    WHERE id = ?
  `;
  await db.update(sql, [passwordHash, id]);
};

/**
 * Refresh Token Repository - Database operations for refresh tokens
 */

/**
 * Create a refresh token
 * @param {Object} tokenData - Token data
 * @returns {Promise<Object>} Created token record
 */
const createRefreshToken = async (tokenData) => {
  const id = uuidv4();
  const tokenHash = crypto
    .createHash('sha256')
    .update(tokenData.token)
    .digest('hex');

  const expiresAt = jwtUtils.getRefreshTokenExpirationDate();

  const sql = `
    INSERT INTO refresh_tokens (id, user_id, token, token_hash, device_name,
                                device_type, ip_address, user_agent, expires_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
  `;

  await db.insert(sql, [
    id,
    tokenData.userId,
    tokenData.token,
    tokenHash,
    tokenData.deviceName || null,
    tokenData.deviceType || null,
    tokenData.ipAddress || null,
    tokenData.userAgent || null,
    expiresAt,
  ]);

  return { id, tokenHash, expiresAt };
};

/**
 * Find refresh token by hash
 * @param {string} token - Plain refresh token
 * @returns {Promise<Object|null>} Token record or null
 */
const findRefreshTokenByToken = async (token) => {
  const tokenHash = crypto
    .createHash('sha256')
    .update(token)
    .digest('hex');

  const sql = `
    SELECT rt.id, rt.user_id, rt.token_hash, rt.device_name, rt.device_type,
           rt.expires_at, rt.is_revoked, rt.created_at, rt.last_used_at,
           u.email, u.role, u.status, u.full_name
    FROM refresh_tokens rt
    JOIN users u ON u.id = rt.user_id
    WHERE rt.token_hash = ?
      AND rt.is_revoked = FALSE
      AND rt.expires_at > NOW()
  `;

  return db.queryOne(sql, [tokenHash]);
};

/**
 * Update refresh token last used timestamp
 * @param {string} id - Token UUID
 * @returns {Promise<void>}
 */
const updateRefreshTokenLastUsed = async (id) => {
  const sql = `
    UPDATE refresh_tokens
    SET last_used_at = CURRENT_TIMESTAMP
    WHERE id = ?
  `;
  await db.update(sql, [id]);
};

/**
 * Revoke a refresh token
 * @param {string} token - Plain refresh token
 * @param {string} reason - Reason for revocation
 * @returns {Promise<void>}
 */
const revokeRefreshToken = async (token, reason = 'logout') => {
  const tokenHash = crypto
    .createHash('sha256')
    .update(token)
    .digest('hex');

  const sql = `
    UPDATE refresh_tokens
    SET is_revoked = TRUE, revoked_at = CURRENT_TIMESTAMP, revoked_reason = ?
    WHERE token_hash = ?
  `;
  await db.update(sql, [reason, tokenHash]);
};

/**
 * Revoke all refresh tokens for a user
 * @param {string} userId - User UUID
 * @param {string} reason - Reason for revocation
 * @returns {Promise<{affectedRows: number}>}
 */
const revokeAllUserTokens = async (userId, reason = 'logout_all') => {
  const sql = `
    UPDATE refresh_tokens
    SET is_revoked = TRUE, revoked_at = CURRENT_TIMESTAMP, revoked_reason = ?
    WHERE user_id = ? AND is_revoked = FALSE
  `;
  return db.update(sql, [reason, userId]);
};

/**
 * Clean up expired tokens
 * @returns {Promise<{affectedRows: number}>}
 */
const cleanupExpiredTokens = async () => {
  const sql = `
    DELETE FROM refresh_tokens
    WHERE expires_at < NOW() OR is_revoked = TRUE
  `;
  return db.remove(sql);
};

/**
 * Get all active sessions for a user
 * @param {string} userId - User UUID
 * @returns {Promise<Array>}
 */
const getUserActiveSessions = async (userId) => {
  const sql = `
    SELECT id, device_name, device_type, ip_address, created_at, last_used_at
    FROM refresh_tokens
    WHERE user_id = ? AND is_revoked = FALSE AND expires_at > NOW()
    ORDER BY last_used_at DESC
  `;
  return db.query(sql, [userId]);
};

module.exports = {
  // User operations
  findByEmail,
  findById,
  findByIdCardNumber,
  findByPhone,
  create,
  update,
  updateLastLogin,
  updatePassword,
  // Refresh token operations
  createRefreshToken,
  findRefreshTokenByToken,
  updateRefreshTokenLastUsed,
  revokeRefreshToken,
  revokeAllUserTokens,
  cleanupExpiredTokens,
  getUserActiveSessions,
};
