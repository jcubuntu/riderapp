'use strict';

const express = require('express');
const router = express.Router();
const authController = require('./auth.controller');
const { authenticate, optionalAuth } = require('../../middleware/auth.middleware');

/**
 * Auth Routes
 *
 * Public routes:
 *   POST /auth/register      - Register new user
 *   POST /auth/login         - Login user
 *   POST /auth/refresh       - Refresh access token
 *   POST /auth/logout        - Logout user
 *   GET  /auth/status        - Check approval status (by userId query param)
 *
 * Protected routes (require authentication):
 *   GET  /auth/me            - Get current user info
 *   GET  /auth/approval-status - Check authenticated user's approval status
 *   PATCH /auth/profile      - Update profile
 *   POST /auth/change-password - Change password
 *   POST /auth/logout-all    - Logout from all devices
 *   GET  /auth/sessions      - Get active sessions
 *   POST /auth/device-token  - Update device token
 */

// ============= Public Routes =============

/**
 * @route   POST /api/auth/register
 * @desc    Register a new user (rider)
 * @access  Public
 * @body    {email, password, phone, fullName, idCardNumber, affiliation, address}
 */
router.post('/register', authController.register);

/**
 * @route   POST /api/auth/login
 * @desc    Login user and get tokens
 * @access  Public
 * @body    {email, password, deviceName?, deviceType?}
 */
router.post('/login', authController.login);

/**
 * @route   POST /api/auth/refresh
 * @desc    Refresh access token using refresh token
 * @access  Public
 * @body    {refreshToken}
 */
router.post('/refresh', authController.refreshToken);

/**
 * @route   POST /api/auth/logout
 * @desc    Logout user (revoke refresh token)
 * @access  Public
 * @body    {refreshToken?}
 */
router.post('/logout', authController.logout);

/**
 * @route   GET /api/auth/status
 * @desc    Check user approval status (by userId)
 * @access  Public
 * @query   {userId}
 */
router.get('/status', authController.checkStatus);

// ============= Protected Routes =============

/**
 * @route   GET /api/auth/me
 * @desc    Get current authenticated user info
 * @access  Private
 */
router.get('/me', authenticate, authController.getCurrentUser);

/**
 * @route   GET /api/auth/approval-status
 * @desc    Check authenticated user's approval status
 * @access  Private
 */
router.get('/approval-status', authenticate, authController.checkApprovalStatus);

/**
 * @route   PATCH /api/auth/profile
 * @desc    Update user profile
 * @access  Private
 * @body    {phone?, fullName?, affiliation?, address?, profileImageUrl?}
 */
router.patch('/profile', authenticate, authController.updateProfile);

/**
 * @route   POST /api/auth/change-password
 * @desc    Change user password
 * @access  Private
 * @body    {currentPassword, newPassword}
 */
router.post('/change-password', authenticate, authController.changePassword);

/**
 * @route   POST /api/auth/logout-all
 * @desc    Logout from all devices
 * @access  Private
 */
router.post('/logout-all', authenticate, authController.logoutAll);

/**
 * @route   GET /api/auth/sessions
 * @desc    Get all active sessions
 * @access  Private
 */
router.get('/sessions', authenticate, authController.getSessions);

/**
 * @route   POST /api/auth/device-token
 * @desc    Update device token for push notifications
 * @access  Private
 * @body    {deviceToken}
 */
router.post('/device-token', authenticate, authController.updateDeviceToken);

module.exports = router;
