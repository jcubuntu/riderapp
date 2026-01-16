'use strict';

const authService = require('./auth.service');
const {
  successResponse,
  createdResponse,
  badRequestResponse,
  noContentResponse,
} = require('../../utils/response.utils');

/**
 * Register a new user
 * POST /api/auth/register
 */
const register = async (req, res, next) => {
  try {
    const { password, phone, fullName, idCardNumber, affiliation, address } = req.body;

    // Validation
    const errors = [];
    if (!password) errors.push({ field: 'password', message: 'Password is required' });
    if (!fullName) errors.push({ field: 'fullName', message: 'Full name is required' });
    if (!phone) errors.push({ field: 'phone', message: 'Phone number is required' });
    if (!idCardNumber) errors.push({ field: 'idCardNumber', message: 'ID card number is required' });

    // Validate password length
    if (password && password.length < 8) {
      errors.push({ field: 'password', message: 'Password must be at least 8 characters' });
    }

    // Validate phone format (Thai phone: 10 digits)
    if (phone && !/^[0-9]{9,10}$/.test(phone)) {
      errors.push({ field: 'phone', message: 'Invalid phone number format' });
    }

    // Validate ID card number (Thai: 13 digits)
    if (idCardNumber && !/^[0-9]{13}$/.test(idCardNumber)) {
      errors.push({ field: 'idCardNumber', message: 'ID card number must be 13 digits' });
    }

    if (errors.length > 0) {
      return badRequestResponse(res, 'Validation failed', errors);
    }

    const result = await authService.register({
      password,
      phone,
      fullName,
      idCardNumber,
      affiliation,
      address,
    });

    return createdResponse(res, result, 'Registration successful. Please wait for approval.');
  } catch (error) {
    next(error);
  }
};

/**
 * Login user
 * POST /api/auth/login
 */
const login = async (req, res, next) => {
  try {
    const { phone, password, deviceName, deviceType } = req.body;

    // Validation
    if (!phone || !password) {
      return badRequestResponse(res, 'Phone number and password are required');
    }

    // Get device info from request
    const deviceInfo = {
      deviceName: deviceName || null,
      deviceType: deviceType || null,
      ipAddress: req.ip || req.connection?.remoteAddress,
      userAgent: req.get('User-Agent'),
    };

    const result = await authService.login(phone, password, deviceInfo);

    return successResponse(res, result, 'Login successful');
  } catch (error) {
    next(error);
  }
};

/**
 * Refresh access token
 * POST /api/auth/refresh
 */
const refreshToken = async (req, res, next) => {
  try {
    const { refreshToken } = req.body;

    if (!refreshToken) {
      return badRequestResponse(res, 'Refresh token is required');
    }

    const result = await authService.refreshTokens(refreshToken);

    return successResponse(res, result, 'Token refreshed successfully');
  } catch (error) {
    next(error);
  }
};

/**
 * Logout user
 * POST /api/auth/logout
 */
const logout = async (req, res, next) => {
  try {
    const { refreshToken } = req.body;

    await authService.logout(refreshToken);

    return noContentResponse(res);
  } catch (error) {
    next(error);
  }
};

/**
 * Logout from all devices
 * POST /api/auth/logout-all
 */
const logoutAll = async (req, res, next) => {
  try {
    const userId = req.user.userId;

    const result = await authService.logoutAllDevices(userId);

    return successResponse(res, result, 'Logged out from all devices');
  } catch (error) {
    next(error);
  }
};

/**
 * Get current user info
 * GET /api/auth/me
 */
const getCurrentUser = async (req, res, next) => {
  try {
    const userId = req.user.userId;

    const user = await authService.getUserById(userId);

    return successResponse(res, { user }, 'User retrieved successfully');
  } catch (error) {
    next(error);
  }
};

/**
 * Check approval status
 * GET /api/auth/status
 */
const checkStatus = async (req, res, next) => {
  try {
    // This endpoint can be accessed with a special status token or by user ID
    const { userId } = req.query;

    if (!userId) {
      return badRequestResponse(res, 'User ID is required');
    }

    const result = await authService.checkApprovalStatus(userId);

    return successResponse(res, result, 'Status retrieved successfully');
  } catch (error) {
    next(error);
  }
};

/**
 * Check authenticated user's approval status
 * GET /api/auth/approval-status
 */
const checkApprovalStatus = async (req, res, next) => {
  try {
    const userId = req.user.userId;

    const result = await authService.checkApprovalStatus(userId);

    return successResponse(res, result, 'Status retrieved successfully');
  } catch (error) {
    next(error);
  }
};

/**
 * Update profile
 * PATCH /api/auth/profile
 */
const updateProfile = async (req, res, next) => {
  try {
    const userId = req.user.userId;
    const { phone, fullName, affiliation, address, profileImageUrl } = req.body;

    const user = await authService.updateProfile(userId, {
      phone,
      fullName,
      affiliation,
      address,
      profileImageUrl,
    });

    return successResponse(res, { user }, 'Profile updated successfully');
  } catch (error) {
    next(error);
  }
};

/**
 * Change password
 * POST /api/auth/change-password
 */
const changePassword = async (req, res, next) => {
  try {
    const userId = req.user.userId;
    const { currentPassword, newPassword } = req.body;

    // Validation
    if (!currentPassword || !newPassword) {
      return badRequestResponse(res, 'Current password and new password are required');
    }

    if (newPassword.length < 8) {
      return badRequestResponse(res, 'New password must be at least 8 characters');
    }

    await authService.changePassword(userId, currentPassword, newPassword);

    return successResponse(res, null, 'Password changed successfully. Please login again.');
  } catch (error) {
    next(error);
  }
};

/**
 * Get active sessions
 * GET /api/auth/sessions
 */
const getSessions = async (req, res, next) => {
  try {
    const userId = req.user.userId;

    const sessions = await authService.getActiveSessions(userId);

    return successResponse(res, { sessions }, 'Sessions retrieved successfully');
  } catch (error) {
    next(error);
  }
};

/**
 * Update device token for push notifications
 * POST /api/auth/device-token
 */
const updateDeviceToken = async (req, res, next) => {
  try {
    const userId = req.user.userId;
    const { deviceToken } = req.body;

    if (!deviceToken) {
      return badRequestResponse(res, 'Device token is required');
    }

    await authService.updateDeviceToken(userId, deviceToken);

    return successResponse(res, null, 'Device token updated successfully');
  } catch (error) {
    next(error);
  }
};

module.exports = {
  register,
  login,
  refreshToken,
  logout,
  logoutAll,
  getCurrentUser,
  checkStatus,
  checkApprovalStatus,
  updateProfile,
  changePassword,
  getSessions,
  updateDeviceToken,
};
