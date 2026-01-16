'use strict';

const logger = require('../../utils/logger.utils');

/**
 * Notification Socket Handler
 * Handles real-time notification events: new notifications, read receipts, counts
 */

/**
 * Register notification event handlers on a socket
 * @param {Socket} socket - Socket.IO socket instance
 * @param {Server} io - Socket.IO server instance
 */
const register = (socket, io) => {
  const { user } = socket;

  // ============= Notification Events =============

  /**
   * Handle notification read event
   * Marks a single notification as read
   */
  socket.on('notification:read', (data) => {
    try {
      const { notificationId } = data;

      if (!notificationId) {
        socket.emit('error', { message: 'Notification ID required' });
        return;
      }

      logger.socket('notification:read', socket.id, { notificationId, userId: user.id });

      // Acknowledge to the sender (update local state)
      socket.emit('notification:read:ack', {
        notificationId,
        readAt: new Date().toISOString(),
      });
    } catch (error) {
      logger.error('Error handling notification:read', error);
    }
  });

  /**
   * Handle notifications read all event
   * Marks all notifications as read
   */
  socket.on('notifications:read:all', () => {
    try {
      logger.socket('notifications:read:all', socket.id, { userId: user.id });

      // Acknowledge to the sender
      socket.emit('notifications:read:all:ack', {
        readAt: new Date().toISOString(),
      });
    } catch (error) {
      logger.error('Error handling notifications:read:all', error);
    }
  });

  /**
   * Handle notification dismiss event
   * Dismisses a notification (soft delete)
   */
  socket.on('notification:dismiss', (data) => {
    try {
      const { notificationId } = data;

      if (!notificationId) {
        socket.emit('error', { message: 'Notification ID required' });
        return;
      }

      logger.socket('notification:dismiss', socket.id, { notificationId, userId: user.id });

      // Acknowledge dismissal
      socket.emit('notification:dismissed', {
        notificationId,
        dismissedAt: new Date().toISOString(),
      });
    } catch (error) {
      logger.error('Error handling notification:dismiss', error);
    }
  });

  /**
   * Handle get unread count event
   * Returns the current unread notification count
   * Note: This is a convenience method; the actual count should come from the service
   */
  socket.on('notifications:unread:count', () => {
    try {
      logger.socket('notifications:unread:count', socket.id, { userId: user.id });

      // This event triggers a request - the service layer should handle
      // and emit the response via emitNotificationCount
      // For now, acknowledge the request
      socket.emit('notifications:unread:count:pending', {
        timestamp: new Date().toISOString(),
      });
    } catch (error) {
      logger.error('Error handling notifications:unread:count', error);
    }
  });

  /**
   * Handle notification subscribe event
   * Subscribe to specific notification categories
   */
  socket.on('notifications:subscribe', (data) => {
    try {
      const { categories } = data;

      if (!categories || !Array.isArray(categories)) {
        socket.emit('error', { message: 'Categories array required' });
        return;
      }

      // Join category-specific rooms
      categories.forEach((category) => {
        const room = `notifications:${user.id}:${category}`;
        socket.join(room);
      });

      logger.socket('notifications:subscribe', socket.id, { categories, userId: user.id });

      socket.emit('notifications:subscribed', {
        categories,
        timestamp: new Date().toISOString(),
      });
    } catch (error) {
      logger.error('Error handling notifications:subscribe', error);
    }
  });

  /**
   * Handle notification unsubscribe event
   * Unsubscribe from specific notification categories
   */
  socket.on('notifications:unsubscribe', (data) => {
    try {
      const { categories } = data;

      if (!categories || !Array.isArray(categories)) {
        socket.emit('error', { message: 'Categories array required' });
        return;
      }

      // Leave category-specific rooms
      categories.forEach((category) => {
        const room = `notifications:${user.id}:${category}`;
        socket.leave(room);
      });

      logger.socket('notifications:unsubscribe', socket.id, { categories, userId: user.id });

      socket.emit('notifications:unsubscribed', {
        categories,
        timestamp: new Date().toISOString(),
      });
    } catch (error) {
      logger.error('Error handling notifications:unsubscribe', error);
    }
  });
};

// ============= Emit Helpers for External Use (Service Layer) =============

/**
 * Emit new notification to a user
 * @param {Server} io - Socket.IO server instance
 * @param {string} userId - User ID
 * @param {Object} notification - Notification data
 */
const emitNotification = (io, userId, notification) => {
  io.to(`user:${userId}`).emit('notification:new', {
    notification,
    timestamp: new Date().toISOString(),
  });

  logger.socket('notification:new', 'server', { userId, notificationId: notification.id });
};

/**
 * Emit notification to multiple users
 * @param {Server} io - Socket.IO server instance
 * @param {string[]} userIds - Array of user IDs
 * @param {Object} notification - Notification data
 */
const emitNotificationToUsers = (io, userIds, notification) => {
  userIds.forEach((userId) => {
    io.to(`user:${userId}`).emit('notification:new', {
      notification,
      timestamp: new Date().toISOString(),
    });
  });

  logger.socket('notification:new:batch', 'server', { userCount: userIds.length });
};

/**
 * Emit notification count update to a user
 * @param {Server} io - Socket.IO server instance
 * @param {string} userId - User ID
 * @param {number} count - Unread count
 */
const emitNotificationCount = (io, userId, count) => {
  io.to(`user:${userId}`).emit('notifications:count', {
    count,
    timestamp: new Date().toISOString(),
  });
};

/**
 * Emit notification count update with category breakdown
 * @param {Server} io - Socket.IO server instance
 * @param {string} userId - User ID
 * @param {Object} counts - Count by category { total, byCategory: { incident: 1, chat: 2, ... } }
 */
const emitNotificationCountDetailed = (io, userId, counts) => {
  io.to(`user:${userId}`).emit('notifications:count:detailed', {
    ...counts,
    timestamp: new Date().toISOString(),
  });
};

/**
 * Emit notification read update (e.g., when read via API)
 * @param {Server} io - Socket.IO server instance
 * @param {string} userId - User ID
 * @param {string} notificationId - Notification ID
 */
const emitNotificationRead = (io, userId, notificationId) => {
  io.to(`user:${userId}`).emit('notification:read', {
    notificationId,
    readAt: new Date().toISOString(),
  });
};

/**
 * Emit all notifications read update
 * @param {Server} io - Socket.IO server instance
 * @param {string} userId - User ID
 */
const emitAllNotificationsRead = (io, userId) => {
  io.to(`user:${userId}`).emit('notifications:all:read', {
    readAt: new Date().toISOString(),
  });
};

/**
 * Emit urgent/high-priority notification (also triggers push)
 * @param {Server} io - Socket.IO server instance
 * @param {string} userId - User ID
 * @param {Object} notification - Notification data
 */
const emitUrgentNotification = (io, userId, notification) => {
  io.to(`user:${userId}`).emit('notification:urgent', {
    notification,
    timestamp: new Date().toISOString(),
  });

  logger.socket('notification:urgent', 'server', { userId, notificationId: notification.id });
};

/**
 * Emit broadcast notification to all users with a role
 * @param {Server} io - Socket.IO server instance
 * @param {string} role - Role name
 * @param {Object} notification - Notification data
 */
const emitBroadcastToRole = (io, role, notification) => {
  io.to(`role:${role}`).emit('notification:broadcast', {
    notification,
    timestamp: new Date().toISOString(),
  });

  logger.socket('notification:broadcast', 'server', { role });
};

/**
 * Emit system-wide notification to all connected users
 * @param {Server} io - Socket.IO server instance
 * @param {Object} notification - Notification data
 */
const emitSystemNotification = (io, notification) => {
  io.emit('notification:system', {
    notification,
    timestamp: new Date().toISOString(),
  });

  logger.socket('notification:system', 'server', { type: notification.type });
};

module.exports = {
  register,

  // Emit helpers
  emitNotification,
  emitNotificationToUsers,
  emitNotificationCount,
  emitNotificationCountDetailed,
  emitNotificationRead,
  emitAllNotificationsRead,
  emitUrgentNotification,
  emitBroadcastToRole,
  emitSystemNotification,
};
