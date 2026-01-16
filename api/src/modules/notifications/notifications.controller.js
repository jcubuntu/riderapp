'use strict';

const notificationsService = require('./notifications.service');
const {
  successResponse,
  paginatedResponse,
  notFoundResponse,
  badRequestResponse,
  forbiddenResponse,
  calculatePagination,
  parsePaginationQuery,
} = require('../../utils/response.utils');

/**
 * Notifications Controller - Handle HTTP requests for notification management
 */

/**
 * Get all notifications for the authenticated user (paginated)
 * GET /notifications
 */
const getNotifications = async (req, res) => {
  try {
    const userId = req.user.id;
    const { page, limit } = parsePaginationQuery(req.query);
    const { category, type, isRead, sortBy, sortOrder } = req.query;

    const result = await notificationsService.getNotifications(userId, {
      page,
      limit,
      category,
      type,
      isRead,
      sortBy,
      sortOrder,
    });

    const pagination = calculatePagination(page, limit, result.total);

    return paginatedResponse(res, result.notifications, pagination, 'Notifications retrieved successfully');
  } catch (error) {
    console.error('Get notifications error:', error);
    return badRequestResponse(res, 'Failed to retrieve notifications');
  }
};

/**
 * Get notification by ID
 * GET /notifications/:id
 */
const getNotificationById = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    const notification = await notificationsService.getNotificationById(id, userId);

    if (!notification) {
      return notFoundResponse(res, 'Notification not found');
    }

    return successResponse(res, notification, 'Notification retrieved successfully');
  } catch (error) {
    console.error('Get notification by ID error:', error);
    return badRequestResponse(res, 'Failed to retrieve notification');
  }
};

/**
 * Mark notification as read
 * PATCH /notifications/:id/read
 */
const markAsRead = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    const notification = await notificationsService.markAsRead(id, userId);

    return successResponse(res, notification, 'Notification marked as read');
  } catch (error) {
    console.error('Mark as read error:', error);

    switch (error.message) {
      case 'NOTIFICATION_NOT_FOUND':
        return notFoundResponse(res, 'Notification not found');
      default:
        return badRequestResponse(res, 'Failed to mark notification as read');
    }
  }
};

/**
 * Mark all notifications as read
 * PATCH /notifications/read-all
 */
const markAllAsRead = async (req, res) => {
  try {
    const userId = req.user.id;

    const result = await notificationsService.markAllAsRead(userId);

    return successResponse(res, result, `${result.count} notification(s) marked as read`);
  } catch (error) {
    console.error('Mark all as read error:', error);
    return badRequestResponse(res, 'Failed to mark notifications as read');
  }
};

/**
 * Delete notification
 * DELETE /notifications/:id
 */
const deleteNotification = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    const notification = await notificationsService.deleteNotification(id, userId);

    return successResponse(res, notification, 'Notification deleted successfully');
  } catch (error) {
    console.error('Delete notification error:', error);

    switch (error.message) {
      case 'NOTIFICATION_NOT_FOUND':
        return notFoundResponse(res, 'Notification not found');
      default:
        return badRequestResponse(res, 'Failed to delete notification');
    }
  }
};

/**
 * Get unread notification count
 * GET /notifications/unread-count
 */
const getUnreadCount = async (req, res) => {
  try {
    const userId = req.user.id;
    const { detailed } = req.query;

    let result;
    if (detailed === 'true') {
      result = await notificationsService.getUnreadCountByCategory(userId);
    } else {
      result = await notificationsService.getUnreadCount(userId);
    }

    return successResponse(res, result, 'Unread count retrieved successfully');
  } catch (error) {
    console.error('Get unread count error:', error);
    return badRequestResponse(res, 'Failed to retrieve unread count');
  }
};

// ============= Push Notification Endpoints =============

/**
 * Test push notification to current user
 * POST /notifications/test-push
 */
const testPush = async (req, res) => {
  try {
    const userId = req.user.id;
    const { title, body } = req.body;

    const result = await notificationsService.sendTestPushNotification(userId, { title, body });

    if (result.success) {
      return successResponse(res, result, 'Test push notification sent successfully');
    } else {
      return badRequestResponse(res, `Failed to send test push: ${result.error}`);
    }
  } catch (error) {
    console.error('Test push error:', error);

    switch (error.message) {
      case 'USER_NOT_FOUND':
        return notFoundResponse(res, 'User not found');
      case 'NO_DEVICE_TOKEN':
        return badRequestResponse(res, 'No device token registered for this user. Please update your device token first.');
      default:
        return badRequestResponse(res, 'Failed to send test push notification');
    }
  }
};

/**
 * Send push notification to specific users (Admin only)
 * POST /notifications/send-push
 */
const sendPush = async (req, res) => {
  try {
    const { userIds, role, title, body, type, targetId, data, priority, imageUrl } = req.body;

    // Validate that either userIds or role is provided
    if ((!userIds || userIds.length === 0) && !role) {
      return badRequestResponse(res, 'Either userIds or role must be provided');
    }

    if (!title || !body) {
      return badRequestResponse(res, 'Title and body are required');
    }

    let result;

    if (role) {
      // Send to all users with the specified role
      result = await notificationsService.sendPushToRole(role, {
        title,
        body,
        type,
        targetId,
        data,
        priority,
        imageUrl,
      });
    } else {
      // Send to specific users
      result = await notificationsService.sendBulkPushNotifications(userIds, {
        title,
        body,
        type,
        entityId: targetId,
        priority,
        imageUrl,
        data,
      });
    }

    if (result.success) {
      return successResponse(res, result, `Push notification sent to ${result.sentCount} device(s)`);
    } else {
      return badRequestResponse(res, `Failed to send push notification: ${result.error}`);
    }
  } catch (error) {
    console.error('Send push error:', error);
    return badRequestResponse(res, 'Failed to send push notification');
  }
};

/**
 * Get push notification status (Admin only)
 * GET /notifications/push-status
 */
const getPushStatus = async (req, res) => {
  try {
    const status = notificationsService.getPushNotificationStatus();
    return successResponse(res, status, 'Push notification status retrieved');
  } catch (error) {
    console.error('Get push status error:', error);
    return badRequestResponse(res, 'Failed to get push notification status');
  }
};

/**
 * Process pending push notifications (Admin only)
 * POST /notifications/process-pending
 */
const processPending = async (req, res) => {
  try {
    const { limit = 100 } = req.body;

    const result = await notificationsService.processPendingPushNotifications(limit);

    return successResponse(res, result, `Processed ${result.processed} pending notifications`);
  } catch (error) {
    console.error('Process pending error:', error);
    return badRequestResponse(res, 'Failed to process pending notifications');
  }
};

module.exports = {
  getNotifications,
  getNotificationById,
  markAsRead,
  markAllAsRead,
  deleteNotification,
  getUnreadCount,
  // Push notification endpoints
  testPush,
  sendPush,
  getPushStatus,
  processPending,
};
