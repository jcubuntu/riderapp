'use strict';

const notificationsRepository = require('./notifications.repository');
const socketManager = require('../../socket');
const logger = require('../../utils/logger.utils');
const pushUtil = require('../../utils/push.util');
const { isFirebaseConfigured } = require('../../config/firebase.config');

/**
 * Notifications Service - Business logic for notification management
 */

// ============= Socket Integration Helpers =============

/**
 * Get the Socket.IO instance
 * @returns {Server|null}
 */
const getIO = () => {
  return socketManager.getIO();
};

/**
 * Get all notifications for a user with pagination and filtering
 * @param {string} userId - User UUID
 * @param {Object} options - Query options
 * @returns {Promise<Object>}
 */
const getNotifications = async (userId, options = {}) => {
  const { notifications, total } = await notificationsRepository.findAllByUserId(userId, options);

  return {
    notifications: notifications.map(formatNotification),
    total,
    page: options.page || 1,
    limit: options.limit || 10,
  };
};

/**
 * Get notification by ID (with ownership check)
 * @param {string} id - Notification UUID
 * @param {string} userId - User UUID
 * @returns {Promise<Object|null>}
 */
const getNotificationById = async (id, userId) => {
  const notification = await notificationsRepository.findByIdAndUserId(id, userId);

  if (!notification) {
    return null;
  }

  return formatNotification(notification);
};

/**
 * Create a notification
 * This method is intended to be called by other modules (incidents, chat, etc.)
 * @param {Object} data - Notification data
 * @param {Object} options - Additional options
 * @param {boolean} options.emitSocket - Whether to emit socket event (default: true)
 * @param {boolean} options.sendPush - Whether to send push notification (default: true)
 * @param {string} options.deviceToken - Device token for push notification (optional, will be fetched if not provided)
 * @returns {Promise<Object>}
 */
const createNotification = async (data, options = {}) => {
  const { emitSocket = true, sendPush = true, deviceToken = null } = options;

  if (!data.userId) {
    throw new Error('USER_ID_REQUIRED');
  }

  if (!data.title) {
    throw new Error('TITLE_REQUIRED');
  }

  if (!data.body) {
    throw new Error('BODY_REQUIRED');
  }

  const notification = await notificationsRepository.create(data);
  const formattedNotification = formatNotification(notification);

  // Emit socket event for real-time notification
  if (emitSocket) {
    try {
      const io = getIO();
      if (io) {
        // Emit to the specific user
        socketManager.emitToUser(data.userId, 'notification:new', {
          notification: formattedNotification,
          timestamp: new Date().toISOString(),
        });

        // If high priority, also emit urgent notification
        if (data.priority === 'high' || data.priority === 'urgent') {
          socketManager.emitToUser(data.userId, 'notification:urgent', {
            notification: formattedNotification,
            timestamp: new Date().toISOString(),
          });
        }

        logger.debug('Socket notification emitted', { userId: data.userId, notificationId: notification.id });
      }
    } catch (error) {
      logger.error('Failed to emit socket notification', error);
      // Don't throw - notification was still created successfully
    }
  }

  // Send push notification
  if (sendPush && isFirebaseConfigured()) {
    try {
      await sendPushForNotification(notification.id, data, deviceToken);
    } catch (error) {
      logger.error('Failed to send push notification', error);
      // Don't throw - in-app notification was still created successfully
    }
  }

  return formattedNotification;
};

/**
 * Create notifications for multiple users
 * Useful for broadcasting (e.g., announcements, alerts)
 * @param {Array<string>} userIds - Array of user UUIDs
 * @param {Object} data - Notification data (without userId)
 * @param {Object} options - Additional options
 * @param {boolean} options.emitSocket - Whether to emit socket events (default: true)
 * @param {boolean} options.sendPush - Whether to send push notifications (default: true)
 * @returns {Promise<number>} Number of created notifications
 */
const createNotificationForUsers = async (userIds, data, options = {}) => {
  const { emitSocket = true, sendPush = true } = options;

  if (!userIds || userIds.length === 0) {
    return 0;
  }

  if (!data.title) {
    throw new Error('TITLE_REQUIRED');
  }

  if (!data.body) {
    throw new Error('BODY_REQUIRED');
  }

  const notifications = userIds.map(userId => ({
    ...data,
    userId,
  }));

  const count = await notificationsRepository.createMany(notifications);

  // Emit socket events for real-time notifications
  if (emitSocket && count > 0) {
    try {
      const io = getIO();
      if (io) {
        // Create a generic notification object for broadcasting
        const broadcastNotification = {
          title: data.title,
          body: data.body,
          type: data.type || 'info',
          category: data.category || 'system',
          priority: data.priority || 'normal',
          timestamp: new Date().toISOString(),
        };

        // Emit to each user
        userIds.forEach(userId => {
          socketManager.emitToUser(userId, 'notification:new', {
            notification: broadcastNotification,
            timestamp: new Date().toISOString(),
          });
        });

        logger.debug('Socket notifications emitted to multiple users', { userCount: userIds.length });
      }
    } catch (error) {
      logger.error('Failed to emit socket notifications', error);
      // Don't throw - notifications were still created successfully
    }
  }

  // Send push notifications to all users
  if (sendPush && count > 0 && isFirebaseConfigured()) {
    try {
      await sendBulkPushNotifications(userIds, data);
    } catch (error) {
      logger.error('Failed to send bulk push notifications', error);
      // Don't throw - in-app notifications were still created successfully
    }
  }

  return count;
};

/**
 * Mark notification as read
 * @param {string} id - Notification UUID
 * @param {string} userId - User UUID
 * @returns {Promise<Object>}
 */
const markAsRead = async (id, userId) => {
  // Check ownership
  const notification = await notificationsRepository.findByIdAndUserId(id, userId);
  if (!notification) {
    throw new Error('NOTIFICATION_NOT_FOUND');
  }

  // Already read
  if (notification.is_read) {
    return formatNotification(notification);
  }

  const updated = await notificationsRepository.markAsRead(id);
  return formatNotification(updated);
};

/**
 * Mark all notifications as read for a user
 * @param {string} userId - User UUID
 * @returns {Promise<{count: number}>}
 */
const markAllAsRead = async (userId) => {
  const count = await notificationsRepository.markAllAsRead(userId);
  return { count };
};

/**
 * Delete (dismiss) a notification
 * @param {string} id - Notification UUID
 * @param {string} userId - User UUID
 * @returns {Promise<Object>}
 */
const deleteNotification = async (id, userId) => {
  // Check ownership
  const notification = await notificationsRepository.findByIdAndUserId(id, userId);
  if (!notification) {
    throw new Error('NOTIFICATION_NOT_FOUND');
  }

  // Use dismiss for soft delete
  const dismissed = await notificationsRepository.dismiss(id);
  return formatNotification(dismissed);
};

/**
 * Get unread notification count for a user
 * @param {string} userId - User UUID
 * @returns {Promise<Object>}
 */
const getUnreadCount = async (userId) => {
  const count = await notificationsRepository.getUnreadCount(userId);
  return { count };
};

/**
 * Get unread notification count by category for a user
 * @param {string} userId - User UUID
 * @returns {Promise<Object>}
 */
const getUnreadCountByCategory = async (userId) => {
  return notificationsRepository.getUnreadCountByCategory(userId);
};

// ============= Helper functions for other modules =============

/**
 * Send incident notification
 * @param {Object} options - Notification options
 * @returns {Promise<Object>}
 */
const sendIncidentNotification = async ({
  userId,
  title,
  body,
  incidentId,
  actionType = 'view',
  priority = 'normal',
  senderId = null,
}) => {
  return createNotification({
    userId,
    title,
    body,
    type: 'info',
    category: 'incident',
    entityType: 'incident',
    entityId: incidentId,
    actionUrl: `/incidents/${incidentId}`,
    actionType,
    priority,
    senderId,
  });
};

/**
 * Send chat notification
 * @param {Object} options - Notification options
 * @returns {Promise<Object>}
 */
const sendChatNotification = async ({
  userId,
  title,
  body,
  conversationId,
  senderId,
  imageUrl = null,
}) => {
  return createNotification({
    userId,
    title,
    body,
    type: 'info',
    category: 'chat',
    entityType: 'conversation',
    entityId: conversationId,
    actionUrl: `/chat/${conversationId}`,
    actionType: 'reply',
    priority: 'normal',
    senderId,
    imageUrl,
  });
};

/**
 * Send approval notification
 * @param {Object} options - Notification options
 * @returns {Promise<Object>}
 */
const sendApprovalNotification = async ({
  userId,
  title,
  body,
  targetUserId = null,
  actionType = 'approve',
  senderId = null,
}) => {
  return createNotification({
    userId,
    title,
    body,
    type: actionType === 'approve' ? 'action' : 'info',
    category: 'approval',
    entityType: 'user',
    entityId: targetUserId,
    actionUrl: targetUserId ? `/users/${targetUserId}` : '/users/pending',
    actionType,
    priority: 'high',
    senderId,
  });
};

/**
 * Send announcement notification
 * @param {Object} options - Notification options
 * @returns {Promise<Object>}
 */
const sendAnnouncementNotification = async ({
  userId,
  title,
  body,
  announcementId,
  priority = 'normal',
  senderId = null,
}) => {
  return createNotification({
    userId,
    title,
    body,
    type: 'info',
    category: 'announcement',
    entityType: 'announcement',
    entityId: announcementId,
    actionUrl: `/announcements/${announcementId}`,
    actionType: 'view',
    priority,
    senderId,
  });
};

/**
 * Send alert notification (high priority)
 * @param {Object} options - Notification options
 * @returns {Promise<Object>}
 */
const sendAlertNotification = async ({
  userId,
  title,
  body,
  entityType = null,
  entityId = null,
  actionUrl = null,
  senderId = null,
}) => {
  return createNotification({
    userId,
    title,
    body,
    type: 'warning',
    category: 'alert',
    entityType,
    entityId,
    actionUrl,
    actionType: 'view',
    priority: 'high',
    senderId,
  });
};

/**
 * Send system notification
 * @param {Object} options - Notification options
 * @returns {Promise<Object>}
 */
const sendSystemNotification = async ({
  userId,
  title,
  body,
  type = 'info',
  priority = 'normal',
}) => {
  return createNotification({
    userId,
    title,
    body,
    type,
    category: 'system',
    priority,
  });
};

/**
 * Format notification object for response
 * @param {Object} notification - Notification from database
 * @returns {Object}
 */
const formatNotification = (notification) => {
  if (!notification) return null;

  // Parse JSON data if it's a string
  let parsedData = notification.data;
  if (typeof notification.data === 'string') {
    try {
      parsedData = JSON.parse(notification.data);
    } catch (e) {
      parsedData = null;
    }
  }

  return {
    id: notification.id,
    userId: notification.user_id,
    title: notification.title,
    body: notification.body,
    summary: notification.summary,
    type: notification.type,
    category: notification.category,
    entityType: notification.entity_type,
    entityId: notification.entity_id,
    actionUrl: notification.action_url,
    actionType: notification.action_type,
    imageUrl: notification.image_url,
    icon: notification.icon,
    isRead: Boolean(notification.is_read),
    readAt: notification.read_at,
    isDismissed: Boolean(notification.is_dismissed),
    dismissedAt: notification.dismissed_at,
    priority: notification.priority,
    senderId: notification.sender_id,
    data: parsedData,
    createdAt: notification.created_at,
    updatedAt: notification.updated_at,
  };
};

// ============= Socket Emit Helpers (for direct socket operations) =============

/**
 * Emit notification count update to a user via socket
 * @param {string} userId - User UUID
 */
const emitNotificationCountUpdate = async (userId) => {
  try {
    const io = getIO();
    if (!io) return;

    const { count } = await getUnreadCount(userId);
    socketManager.emitToUser(userId, 'notifications:count', {
      count,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    logger.error('Failed to emit notification count update', error);
  }
};

/**
 * Emit detailed notification count update to a user via socket
 * @param {string} userId - User UUID
 */
const emitDetailedNotificationCountUpdate = async (userId) => {
  try {
    const io = getIO();
    if (!io) return;

    const counts = await getUnreadCountByCategory(userId);
    socketManager.emitToUser(userId, 'notifications:count:detailed', {
      ...counts,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    logger.error('Failed to emit detailed notification count update', error);
  }
};

/**
 * Broadcast notification to all users with a specific role
 * @param {string} role - User role
 * @param {Object} notification - Notification data
 */
const broadcastToRole = (role, notification) => {
  try {
    const io = getIO();
    if (!io) return;

    socketManager.emitToRole(role, 'notification:broadcast', {
      notification,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    logger.error('Failed to broadcast notification to role', error);
  }
};

/**
 * Broadcast system notification to all connected users
 * @param {Object} notification - Notification data
 */
const broadcastSystemNotification = (notification) => {
  try {
    const io = getIO();
    if (!io) return;

    socketManager.emitToAll('notification:system', {
      notification,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    logger.error('Failed to broadcast system notification', error);
  }
};

// ============= Push Notification Helpers =============

/**
 * Send push notification for a single notification
 * @param {string} notificationId - Notification UUID
 * @param {Object} data - Notification data
 * @param {string} deviceToken - Optional device token
 * @returns {Promise<void>}
 */
const sendPushForNotification = async (notificationId, data, deviceToken = null) => {
  try {
    let token = deviceToken;

    // Fetch device token if not provided
    if (!token) {
      const db = require('../../config/database');
      const user = await db.queryOne(
        'SELECT device_token FROM users WHERE id = ? AND device_token IS NOT NULL AND device_token != ""',
        [data.userId]
      );

      if (!user || !user.device_token) {
        logger.debug('No device token found for user, skipping push', { userId: data.userId });
        return;
      }

      token = user.device_token;
    }

    // Map category to notification type
    const typeMap = {
      chat: pushUtil.NOTIFICATION_TYPES.CHAT,
      incident: pushUtil.NOTIFICATION_TYPES.INCIDENT,
      announcement: pushUtil.NOTIFICATION_TYPES.ANNOUNCEMENT,
      approval: pushUtil.NOTIFICATION_TYPES.APPROVAL,
      alert: pushUtil.NOTIFICATION_TYPES.ALERT,
      system: pushUtil.NOTIFICATION_TYPES.SYSTEM,
    };

    const result = await pushUtil.sendToDevice(token, {
      title: data.title,
      body: data.body,
      imageUrl: data.imageUrl,
      type: typeMap[data.category] || pushUtil.NOTIFICATION_TYPES.SYSTEM,
      targetId: data.entityId,
      action: data.actionType === 'view' ? 'open' : 'navigate',
      priority: data.priority === 'high' ? 'high' : 'normal',
      data: {
        notificationId,
        entityType: data.entityType,
        actionUrl: data.actionUrl,
      },
    });

    // Update push status in database
    await notificationsRepository.updatePushStatus(
      notificationId,
      result.success,
      result.success ? null : result.error
    );

    // Handle invalid token - could trigger token cleanup
    if (result.isInvalidToken) {
      logger.warn('Invalid device token detected, should be cleaned up', {
        userId: data.userId,
        tokenPrefix: token.substring(0, 20),
      });
      // Optionally: Clear the invalid token from the user record
      await clearInvalidDeviceToken(data.userId, token);
    }
  } catch (error) {
    logger.error('Error in sendPushForNotification', {
      notificationId,
      userId: data.userId,
      error: error.message,
    });
    // Update push status as failed
    await notificationsRepository.updatePushStatus(notificationId, false, error.message);
  }
};

/**
 * Send bulk push notifications to multiple users
 * @param {Array<string>} userIds - Array of user UUIDs
 * @param {Object} data - Notification data
 * @returns {Promise<Object>} Result summary
 */
const sendBulkPushNotifications = async (userIds, data) => {
  try {
    const db = require('../../config/database');

    // Fetch all device tokens for the users
    const placeholders = userIds.map(() => '?').join(',');
    const users = await db.query(
      `SELECT id, device_token FROM users WHERE id IN (${placeholders}) AND device_token IS NOT NULL AND device_token != ''`,
      userIds
    );

    if (!users || users.length === 0) {
      logger.debug('No device tokens found for users, skipping bulk push', { userCount: userIds.length });
      return { success: false, error: 'NO_TOKENS', sentCount: 0 };
    }

    const tokens = users.map((u) => u.device_token);

    // Map category to notification type
    const typeMap = {
      chat: pushUtil.NOTIFICATION_TYPES.CHAT,
      incident: pushUtil.NOTIFICATION_TYPES.INCIDENT,
      announcement: pushUtil.NOTIFICATION_TYPES.ANNOUNCEMENT,
      approval: pushUtil.NOTIFICATION_TYPES.APPROVAL,
      alert: pushUtil.NOTIFICATION_TYPES.ALERT,
      system: pushUtil.NOTIFICATION_TYPES.SYSTEM,
    };

    const result = await pushUtil.sendInBatches(tokens, {
      title: data.title,
      body: data.body,
      imageUrl: data.imageUrl,
      type: typeMap[data.category] || pushUtil.NOTIFICATION_TYPES.SYSTEM,
      targetId: data.entityId,
      action: data.actionType === 'view' ? 'open' : 'navigate',
      priority: data.priority === 'high' ? 'high' : 'normal',
      data: {
        entityType: data.entityType,
        actionUrl: data.actionUrl,
      },
    });

    logger.info('Bulk push notifications sent', {
      totalUsers: userIds.length,
      tokensFound: tokens.length,
      successCount: result.successCount,
      failureCount: result.failureCount,
    });

    // Clean up invalid tokens
    if (result.invalidTokens && result.invalidTokens.length > 0) {
      await cleanupInvalidTokens(result.invalidTokens, users);
    }

    return {
      success: result.successCount > 0,
      sentCount: result.successCount,
      failedCount: result.failureCount,
      invalidTokenCount: result.invalidTokens?.length || 0,
    };
  } catch (error) {
    logger.error('Error in sendBulkPushNotifications', {
      userCount: userIds.length,
      error: error.message,
    });
    return { success: false, error: error.message, sentCount: 0 };
  }
};

/**
 * Clear invalid device token for a user
 * @param {string} userId - User UUID
 * @param {string} token - Invalid token
 */
const clearInvalidDeviceToken = async (userId, token) => {
  try {
    const db = require('../../config/database');
    // Only clear if the token matches (in case it was updated)
    await db.update(
      'UPDATE users SET device_token = NULL WHERE id = ? AND device_token = ?',
      [userId, token]
    );
    logger.info('Cleared invalid device token for user', { userId });
  } catch (error) {
    logger.error('Failed to clear invalid device token', { userId, error: error.message });
  }
};

/**
 * Clean up multiple invalid tokens
 * @param {Array<string>} invalidTokens - Invalid tokens
 * @param {Array<Object>} users - User records with id and device_token
 */
const cleanupInvalidTokens = async (invalidTokens, users) => {
  try {
    const db = require('../../config/database');
    const tokenSet = new Set(invalidTokens);

    // Find users with invalid tokens
    const usersToClean = users.filter((u) => tokenSet.has(u.device_token));

    if (usersToClean.length === 0) return;

    // Clear tokens for these users
    const userIds = usersToClean.map((u) => u.id);
    const placeholders = userIds.map(() => '?').join(',');

    await db.update(
      `UPDATE users SET device_token = NULL WHERE id IN (${placeholders})`,
      userIds
    );

    logger.info('Cleaned up invalid device tokens', { userCount: usersToClean.length });
  } catch (error) {
    logger.error('Failed to cleanup invalid tokens', { error: error.message });
  }
};

/**
 * Send test push notification to a specific user
 * @param {string} userId - User UUID
 * @param {Object} options - Optional override options
 * @returns {Promise<Object>}
 */
const sendTestPushNotification = async (userId, options = {}) => {
  const db = require('../../config/database');

  const user = await db.queryOne(
    'SELECT id, full_name, device_token FROM users WHERE id = ?',
    [userId]
  );

  if (!user) {
    throw new Error('USER_NOT_FOUND');
  }

  if (!user.device_token) {
    throw new Error('NO_DEVICE_TOKEN');
  }

  const result = await pushUtil.sendToDevice(user.device_token, {
    title: options.title || 'Test Notification',
    body: options.body || `Hello ${user.full_name}! This is a test push notification.`,
    type: pushUtil.NOTIFICATION_TYPES.SYSTEM,
    action: 'open',
    data: {
      test: 'true',
      timestamp: new Date().toISOString(),
    },
  });

  return {
    success: result.success,
    messageId: result.messageId,
    error: result.error,
    isInvalidToken: result.isInvalidToken,
  };
};

/**
 * Send push notification to users by role
 * @param {string} role - User role
 * @param {Object} data - Notification data
 * @returns {Promise<Object>}
 */
const sendPushToRole = async (role, data) => {
  try {
    const db = require('../../config/database');

    // Get all users with the specified role who have device tokens
    const users = await db.query(
      `SELECT id, device_token FROM users
       WHERE role = ? AND status = 'approved'
       AND device_token IS NOT NULL AND device_token != ''`,
      [role]
    );

    if (!users || users.length === 0) {
      return { success: false, error: 'NO_USERS_WITH_TOKENS', sentCount: 0 };
    }

    const tokens = users.map((u) => u.device_token);

    const result = await pushUtil.sendInBatches(tokens, {
      title: data.title,
      body: data.body,
      imageUrl: data.imageUrl,
      type: data.type || pushUtil.NOTIFICATION_TYPES.SYSTEM,
      targetId: data.targetId,
      action: data.action || 'open',
      priority: data.priority || 'normal',
      data: data.data || {},
    });

    // Clean up invalid tokens
    if (result.invalidTokens && result.invalidTokens.length > 0) {
      await cleanupInvalidTokens(result.invalidTokens, users);
    }

    return {
      success: result.successCount > 0,
      sentCount: result.successCount,
      failedCount: result.failureCount,
      totalUsers: users.length,
    };
  } catch (error) {
    logger.error('Error in sendPushToRole', { role, error: error.message });
    return { success: false, error: error.message, sentCount: 0 };
  }
};

/**
 * Process pending push notifications (for batch/scheduled sending)
 * @param {number} limit - Maximum number to process
 * @returns {Promise<Object>}
 */
const processPendingPushNotifications = async (limit = 100) => {
  try {
    const pendingNotifications = await notificationsRepository.getPendingPushNotifications(limit);

    if (!pendingNotifications || pendingNotifications.length === 0) {
      return { processed: 0, success: 0, failed: 0 };
    }

    let successCount = 0;
    let failedCount = 0;

    for (const notification of pendingNotifications) {
      if (!notification.device_token) {
        await notificationsRepository.updatePushStatus(notification.id, false, 'NO_DEVICE_TOKEN');
        failedCount++;
        continue;
      }

      // Parse data if it's a string
      let parsedData = notification.data;
      if (typeof notification.data === 'string') {
        try {
          parsedData = JSON.parse(notification.data);
        } catch (e) {
          parsedData = {};
        }
      }

      const result = await pushUtil.sendToDevice(notification.device_token, {
        title: notification.title,
        body: notification.body,
        imageUrl: notification.image_url,
        type: notification.category || pushUtil.NOTIFICATION_TYPES.SYSTEM,
        targetId: notification.entity_id,
        action: notification.action_type === 'view' ? 'open' : 'navigate',
        priority: notification.priority === 'high' ? 'high' : 'normal',
        data: {
          notificationId: notification.id,
          entityType: notification.entity_type,
          actionUrl: notification.action_url,
          ...parsedData,
        },
      });

      await notificationsRepository.updatePushStatus(
        notification.id,
        result.success,
        result.success ? null : result.error
      );

      if (result.success) {
        successCount++;
      } else {
        failedCount++;

        // Clean up invalid token
        if (result.isInvalidToken) {
          await clearInvalidDeviceToken(notification.user_id, notification.device_token);
        }
      }
    }

    logger.info('Processed pending push notifications', {
      total: pendingNotifications.length,
      success: successCount,
      failed: failedCount,
    });

    return {
      processed: pendingNotifications.length,
      success: successCount,
      failed: failedCount,
    };
  } catch (error) {
    logger.error('Error processing pending push notifications', { error: error.message });
    throw error;
  }
};

/**
 * Get Firebase/push notification status
 * @returns {Object}
 */
const getPushNotificationStatus = () => {
  const { getFirebaseStatus } = require('../../config/firebase.config');
  return getFirebaseStatus();
};

module.exports = {
  // Main CRUD operations
  getNotifications,
  getNotificationById,
  createNotification,
  createNotificationForUsers,
  markAsRead,
  markAllAsRead,
  deleteNotification,
  getUnreadCount,
  getUnreadCountByCategory,

  // Helper functions for other modules
  sendIncidentNotification,
  sendChatNotification,
  sendApprovalNotification,
  sendAnnouncementNotification,
  sendAlertNotification,
  sendSystemNotification,

  // Socket emit helpers
  emitNotificationCountUpdate,
  emitDetailedNotificationCountUpdate,
  broadcastToRole,
  broadcastSystemNotification,

  // Push notification helpers
  sendTestPushNotification,
  sendPushToRole,
  processPendingPushNotifications,
  getPushNotificationStatus,
  sendBulkPushNotifications,
};
