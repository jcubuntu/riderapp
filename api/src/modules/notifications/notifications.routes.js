'use strict';

const express = require('express');
const router = express.Router();
const notificationsController = require('./notifications.controller');
const { authenticate } = require('../../middleware/auth.middleware');
const { adminOnly } = require('../../middleware/role.middleware');
const {
  validate,
  listNotificationsSchema,
  notificationIdSchema,
  unreadCountSchema,
  testPushSchema,
  sendPushSchema,
  processPendingSchema,
} = require('./notifications.validation');

/**
 * Notifications Routes
 *
 * All routes require authentication.
 * Users can only access their own notifications.
 *
 * Routes:
 *   GET    /notifications              - List user's notifications (paginated)
 *   GET    /notifications/unread-count - Get unread notification count
 *   PATCH  /notifications/read-all     - Mark all notifications as read
 *   GET    /notifications/:id          - Get notification by ID
 *   PATCH  /notifications/:id/read     - Mark notification as read
 *   DELETE /notifications/:id          - Delete notification
 *
 * Push Notification Routes:
 *   POST   /notifications/test-push      - Test push to current user
 *   POST   /notifications/send-push      - Send push to users (Admin only)
 *   GET    /notifications/push-status    - Get push notification status (Admin only)
 *   POST   /notifications/process-pending - Process pending push notifications (Admin only)
 */

// ============= List and Count Routes =============

/**
 * @route   GET /api/v1/notifications
 * @desc    List user's notifications (paginated)
 * @access  Authenticated
 * @query   {page, limit, category, type, isRead, sortBy, sortOrder}
 */
router.get(
  '/',
  authenticate,
  validate(listNotificationsSchema, 'query'),
  notificationsController.getNotifications
);

/**
 * @route   GET /api/v1/notifications/unread-count
 * @desc    Get unread notification count
 * @access  Authenticated
 * @query   {detailed} - If 'true', returns count by category
 */
router.get(
  '/unread-count',
  authenticate,
  validate(unreadCountSchema, 'query'),
  notificationsController.getUnreadCount
);

/**
 * @route   PATCH /api/v1/notifications/read-all
 * @desc    Mark all notifications as read
 * @access  Authenticated
 */
router.patch(
  '/read-all',
  authenticate,
  notificationsController.markAllAsRead
);

// ============= Single Notification Routes =============

/**
 * @route   GET /api/v1/notifications/:id
 * @desc    Get notification by ID
 * @access  Authenticated (owner only)
 * @params  {id} - Notification UUID
 */
router.get(
  '/:id',
  authenticate,
  validate(notificationIdSchema, 'params'),
  notificationsController.getNotificationById
);

/**
 * @route   PATCH /api/v1/notifications/:id/read
 * @desc    Mark notification as read
 * @access  Authenticated (owner only)
 * @params  {id} - Notification UUID
 */
router.patch(
  '/:id/read',
  authenticate,
  validate(notificationIdSchema, 'params'),
  notificationsController.markAsRead
);

/**
 * @route   DELETE /api/v1/notifications/:id
 * @desc    Delete notification
 * @access  Authenticated (owner only)
 * @params  {id} - Notification UUID
 */
router.delete(
  '/:id',
  authenticate,
  validate(notificationIdSchema, 'params'),
  notificationsController.deleteNotification
);

// ============= Push Notification Routes =============

/**
 * @route   POST /api/v1/notifications/test-push
 * @desc    Send test push notification to current user
 * @access  Authenticated
 * @body    {title?, body?} - Optional custom title and body
 */
router.post(
  '/test-push',
  authenticate,
  validate(testPushSchema, 'body'),
  notificationsController.testPush
);

/**
 * @route   POST /api/v1/notifications/send-push
 * @desc    Send push notification to specific users or role
 * @access  Admin only
 * @body    {userIds?, role?, title, body, type?, targetId?, data?, priority?, imageUrl?}
 */
router.post(
  '/send-push',
  authenticate,
  adminOnly,
  validate(sendPushSchema, 'body'),
  notificationsController.sendPush
);

/**
 * @route   GET /api/v1/notifications/push-status
 * @desc    Get push notification service status
 * @access  Admin only
 */
router.get(
  '/push-status',
  authenticate,
  adminOnly,
  notificationsController.getPushStatus
);

/**
 * @route   POST /api/v1/notifications/process-pending
 * @desc    Process pending push notifications
 * @access  Admin only
 * @body    {limit?} - Maximum number to process (default: 100)
 */
router.post(
  '/process-pending',
  authenticate,
  adminOnly,
  validate(processPendingSchema, 'body'),
  notificationsController.processPending
);

module.exports = router;
