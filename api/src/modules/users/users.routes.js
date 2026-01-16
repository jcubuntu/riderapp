'use strict';

const express = require('express');
const router = express.Router();
const usersController = require('./users.controller');
const { authenticate } = require('../../middleware/auth.middleware');
const {
  adminOnly,
  policeOrAdmin,
  selfOrAdmin,
  volunteerOrHigher,
} = require('../../middleware/role.middleware');
const {
  validate,
  listUsersSchema,
  listPendingSchema,
  userIdSchema,
  updateUserSchema,
  updateStatusSchema,
  updateRoleSchema,
  rejectUserSchema,
} = require('./users.validation');

/**
 * Users Routes
 *
 * All routes require authentication
 *
 * Admin routes:
 *   GET  /users          - List all users (admin+)
 *   GET  /users/stats    - Get user statistics (admin+)
 *   DELETE /users/:id    - Soft delete user (admin+)
 *   PATCH /users/:id/role - Update user role (admin+)
 *
 * Police+ routes:
 *   GET  /users/pending        - List pending approvals (police+)
 *   PATCH /users/:id/status    - Update user status (police+)
 *   POST /users/:id/approve    - Approve user (police+)
 *   POST /users/:id/reject     - Reject user (police+)
 *
 * Self or Admin routes:
 *   GET  /users/:id      - Get user by ID (self or admin)
 *   PUT  /users/:id      - Update user (self or admin)
 */

// ============= Admin Routes =============

/**
 * @route   GET /api/v1/users
 * @desc    List all users (paginated)
 * @access  Admin+
 * @query   {page, limit, search, role, status, affiliation, sortBy, sortOrder}
 */
router.get(
  '/',
  authenticate,
  adminOnly,
  validate(listUsersSchema, 'query'),
  usersController.getUsers
);

/**
 * @route   GET /api/v1/users/stats
 * @desc    Get user statistics
 * @access  Admin+
 */
router.get(
  '/stats',
  authenticate,
  adminOnly,
  usersController.getUserStats
);

/**
 * @route   GET /api/v1/users/pending
 * @desc    List users pending approval
 * @access  Police+
 * @query   {page, limit, search}
 */
router.get(
  '/pending',
  authenticate,
  policeOrAdmin,
  validate(listPendingSchema, 'query'),
  usersController.getPendingUsers
);

/**
 * @route   GET /api/v1/users/:id
 * @desc    Get user by ID
 * @access  Self or Admin
 * @params  {id} - User UUID
 * @query   {includeApprover} - Include approver details (optional)
 */
router.get(
  '/:id',
  authenticate,
  validate(userIdSchema, 'params'),
  selfOrAdmin('id'),
  usersController.getUserById
);

/**
 * @route   PUT /api/v1/users/:id
 * @desc    Update user
 * @access  Self or Admin
 * @params  {id} - User UUID
 * @body    {email?, phone?, fullName?, affiliation?, address?, profileImageUrl?}
 */
router.put(
  '/:id',
  authenticate,
  validate(userIdSchema, 'params'),
  validate(updateUserSchema, 'body'),
  selfOrAdmin('id'),
  usersController.updateUser
);

/**
 * @route   DELETE /api/v1/users/:id
 * @desc    Soft delete user
 * @access  Admin+
 * @params  {id} - User UUID
 */
router.delete(
  '/:id',
  authenticate,
  adminOnly,
  validate(userIdSchema, 'params'),
  usersController.deleteUser
);

/**
 * @route   PATCH /api/v1/users/:id/status
 * @desc    Update user status
 * @access  Police+
 * @params  {id} - User UUID
 * @body    {status: 'pending'|'approved'|'rejected'|'inactive'}
 */
router.patch(
  '/:id/status',
  authenticate,
  policeOrAdmin,
  validate(userIdSchema, 'params'),
  validate(updateStatusSchema, 'body'),
  usersController.updateUserStatus
);

/**
 * @route   PATCH /api/v1/users/:id/role
 * @desc    Update user role
 * @access  Admin+
 * @params  {id} - User UUID
 * @body    {role: 'rider'|'volunteer'|'police'|'admin'|'super_admin'}
 */
router.patch(
  '/:id/role',
  authenticate,
  adminOnly,
  validate(userIdSchema, 'params'),
  validate(updateRoleSchema, 'body'),
  usersController.updateUserRole
);

/**
 * @route   POST /api/v1/users/:id/approve
 * @desc    Approve pending user
 * @access  Police+
 * @params  {id} - User UUID
 */
router.post(
  '/:id/approve',
  authenticate,
  policeOrAdmin,
  validate(userIdSchema, 'params'),
  usersController.approveUser
);

/**
 * @route   POST /api/v1/users/:id/reject
 * @desc    Reject pending user
 * @access  Police+
 * @params  {id} - User UUID
 * @body    {reason?: string}
 */
router.post(
  '/:id/reject',
  authenticate,
  policeOrAdmin,
  validate(userIdSchema, 'params'),
  validate(rejectUserSchema, 'body'),
  usersController.rejectUser
);

module.exports = router;
