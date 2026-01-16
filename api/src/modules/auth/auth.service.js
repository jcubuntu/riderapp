'use strict';

const authRepository = require('./auth.repository');
const passwordUtils = require('../../utils/password.utils');
const jwtUtils = require('../../utils/jwt.utils');
const { ApiError } = require('../../middleware/error.middleware');
const uploadUtil = require('../../utils/upload.util');

/**
 * Register a new user
 * @param {Object} userData - Registration data
 * @returns {Promise<Object>} Created user and tokens
 */
const register = async (userData) => {
  // Check if phone number already exists (required, unique)
  const existingPhone = await authRepository.findByPhone(userData.phone);
  if (existingPhone) {
    throw new ApiError(409, 'Phone number already registered');
  }

  // Check if ID card number already exists
  if (userData.idCardNumber) {
    const existingIdCard = await authRepository.findByIdCardNumber(userData.idCardNumber);
    if (existingIdCard) {
      throw new ApiError(409, 'ID card number already registered');
    }
  }

  // Hash password
  const passwordHash = await passwordUtils.hashPassword(userData.password);

  // Create user with pending status (requires approval)
  const user = await authRepository.create({
    email: null, // Email is no longer used
    passwordHash,
    phone: userData.phone,
    fullName: userData.fullName,
    idCardNumber: userData.idCardNumber,
    affiliation: userData.affiliation,
    address: userData.address,
    role: 'rider', // Default role for new registrations
    status: 'pending', // Requires admin/police approval
  });

  // Return user without generating tokens (user needs approval first)
  return {
    user: formatUserResponse(user),
    requiresApproval: true,
  };
};

/**
 * Login a user
 * @param {string} phone - User phone number
 * @param {string} password - User password
 * @param {Object} deviceInfo - Device information
 * @returns {Promise<Object>} User and tokens
 */
const login = async (phone, password, deviceInfo = {}) => {
  // Find user by phone
  const user = await authRepository.findByPhone(phone);
  if (!user) {
    throw new ApiError(401, 'Invalid phone number or password');
  }

  // Check password
  const isValidPassword = await passwordUtils.comparePassword(password, user.password_hash);
  if (!isValidPassword) {
    throw new ApiError(401, 'Invalid phone number or password');
  }

  // Check user status
  if (user.status === 'pending') {
    throw new ApiError(403, 'Account pending approval', { status: 'pending' });
  }

  if (user.status === 'rejected') {
    throw new ApiError(403, 'Account registration was rejected', { status: 'rejected' });
  }

  if (user.status === 'suspended') {
    throw new ApiError(403, 'Account has been suspended', { status: 'suspended' });
  }

  // Generate tokens
  const tokens = jwtUtils.generateTokenPair(user);

  // Store refresh token in database
  await authRepository.createRefreshToken({
    userId: user.id,
    token: tokens.refreshToken,
    deviceName: deviceInfo.deviceName,
    deviceType: deviceInfo.deviceType,
    ipAddress: deviceInfo.ipAddress,
    userAgent: deviceInfo.userAgent,
  });

  // Update last login timestamp
  await authRepository.updateLastLogin(user.id);

  return {
    user: formatUserResponse(user),
    tokens,
  };
};

/**
 * Refresh access token using refresh token
 * @param {string} refreshToken - Refresh token
 * @returns {Promise<Object>} New tokens
 */
const refreshTokens = async (refreshToken) => {
  // Verify refresh token JWT
  let decoded;
  try {
    decoded = jwtUtils.verifyRefreshToken(refreshToken);
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      throw new ApiError(401, 'Refresh token expired');
    }
    throw new ApiError(401, 'Invalid refresh token');
  }

  if (!decoded) {
    throw new ApiError(401, 'Invalid refresh token');
  }

  // Find token in database
  const tokenRecord = await authRepository.findRefreshTokenByToken(refreshToken);
  if (!tokenRecord) {
    throw new ApiError(401, 'Refresh token not found or revoked');
  }

  // Check user status
  if (tokenRecord.status !== 'approved') {
    throw new ApiError(403, 'Account is not active', { status: tokenRecord.status });
  }

  // Update last used timestamp
  await authRepository.updateRefreshTokenLastUsed(tokenRecord.id);

  // Generate new token pair
  const tokens = jwtUtils.generateTokenPair({
    id: tokenRecord.user_id,
    email: tokenRecord.email,
    role: tokenRecord.role,
  });

  // Store new refresh token
  await authRepository.createRefreshToken({
    userId: tokenRecord.user_id,
    token: tokens.refreshToken,
    deviceName: tokenRecord.device_name,
    deviceType: tokenRecord.device_type,
  });

  // Revoke old refresh token
  await authRepository.revokeRefreshToken(refreshToken, 'token_refresh');

  return {
    tokens,
    user: {
      id: tokenRecord.user_id,
      email: tokenRecord.email,
      role: tokenRecord.role,
      fullName: tokenRecord.full_name,
      status: tokenRecord.status,
    },
  };
};

/**
 * Logout user (revoke refresh token)
 * @param {string} refreshToken - Refresh token to revoke
 * @returns {Promise<void>}
 */
const logout = async (refreshToken) => {
  if (refreshToken) {
    await authRepository.revokeRefreshToken(refreshToken, 'logout');
  }
};

/**
 * Logout from all devices
 * @param {string} userId - User UUID
 * @returns {Promise<{revokedSessions: number}>}
 */
const logoutAllDevices = async (userId) => {
  const result = await authRepository.revokeAllUserTokens(userId, 'logout_all_devices');
  return { revokedSessions: result.affectedRows };
};

/**
 * Get user by ID
 * @param {string} userId - User UUID
 * @returns {Promise<Object>} User object
 */
const getUserById = async (userId) => {
  const user = await authRepository.findById(userId);
  if (!user) {
    throw new ApiError(404, 'User not found');
  }
  return formatUserResponse(user);
};

/**
 * Check user approval status
 * @param {string} userId - User UUID
 * @returns {Promise<Object>} Status information
 */
const checkApprovalStatus = async (userId) => {
  const user = await authRepository.findById(userId);
  if (!user) {
    throw new ApiError(404, 'User not found');
  }

  return {
    status: user.status,
    approvedAt: user.approved_at,
    user: formatUserResponse(user),
  };
};

/**
 * Get user profile
 * @param {string} userId - User UUID
 * @returns {Promise<Object>} User profile
 */
const getProfile = async (userId) => {
  const user = await authRepository.findById(userId);
  if (!user) {
    throw new ApiError(404, 'User not found');
  }
  return formatUserResponse(user);
};

/**
 * Update user profile
 * @param {string} userId - User UUID
 * @param {Object} updates - Profile updates
 * @returns {Promise<Object>} Updated user
 */
const updateProfile = async (userId, updates) => {
  const user = await authRepository.findById(userId);
  if (!user) {
    throw new ApiError(404, 'User not found');
  }

  // Prevent updating sensitive fields
  const allowedUpdates = ['phone', 'fullName', 'affiliation', 'address', 'profileImageUrl'];
  const filteredUpdates = {};

  for (const key of allowedUpdates) {
    if (updates[key] !== undefined) {
      filteredUpdates[key] = updates[key];
    }
  }

  // Check if phone is being updated and is unique
  if (filteredUpdates.phone && filteredUpdates.phone !== user.phone) {
    const existingPhone = await authRepository.findByPhone(filteredUpdates.phone);
    if (existingPhone && existingPhone.id !== userId) {
      throw new ApiError(409, 'Phone number already in use');
    }
  }

  // If profile image is being updated, delete the old one
  if (filteredUpdates.profileImageUrl && user.profile_image_url) {
    // Only delete if the new URL is different from the old one
    if (filteredUpdates.profileImageUrl !== user.profile_image_url) {
      try {
        await uploadUtil.deleteFileByUrl(user.profile_image_url);
      } catch (error) {
        // Log error but don't fail the update
        console.warn('Failed to delete old profile image:', error.message);
      }
    }
  }

  const updatedUser = await authRepository.update(userId, filteredUpdates);
  return formatUserResponse(updatedUser);
};

/**
 * Change user password
 * @param {string} userId - User UUID
 * @param {string} currentPassword - Current password
 * @param {string} newPassword - New password
 * @returns {Promise<void>}
 */
const changePassword = async (userId, currentPassword, newPassword) => {
  const user = await authRepository.findByEmail(
    (await authRepository.findById(userId)).email
  );

  if (!user) {
    throw new ApiError(404, 'User not found');
  }

  // Verify current password
  const isValidPassword = await passwordUtils.comparePassword(currentPassword, user.password_hash);
  if (!isValidPassword) {
    throw new ApiError(401, 'Current password is incorrect');
  }

  // Hash new password
  const passwordHash = await passwordUtils.hashPassword(newPassword);

  // Update password
  await authRepository.updatePassword(userId, passwordHash);

  // Revoke all refresh tokens (security measure)
  await authRepository.revokeAllUserTokens(userId, 'password_change');
};

/**
 * Get active sessions for user
 * @param {string} userId - User UUID
 * @returns {Promise<Array>} List of active sessions
 */
const getActiveSessions = async (userId) => {
  return authRepository.getUserActiveSessions(userId);
};

/**
 * Update device token for push notifications
 * @param {string} userId - User UUID
 * @param {string} deviceToken - FCM device token
 * @returns {Promise<void>}
 */
const updateDeviceToken = async (userId, deviceToken) => {
  await authRepository.update(userId, { deviceToken });
};

/**
 * Format user object for response (remove sensitive data)
 * @param {Object} user - Raw user object from database
 * @returns {Object} Formatted user object
 */
const formatUserResponse = (user) => {
  if (!user) return null;

  return {
    id: user.id,
    email: user.email,
    phone: user.phone,
    fullName: user.full_name,
    idCardNumber: user.id_card_number,
    affiliation: user.affiliation,
    address: user.address,
    role: user.role,
    status: user.status,
    profileImageUrl: user.profile_image_url,
    approvedAt: user.approved_at,
    createdAt: user.created_at,
    updatedAt: user.updated_at,
    lastLoginAt: user.last_login_at,
  };
};

module.exports = {
  register,
  login,
  refreshTokens,
  logout,
  logoutAllDevices,
  getUserById,
  checkApprovalStatus,
  getProfile,
  updateProfile,
  changePassword,
  getActiveSessions,
  updateDeviceToken,
};
