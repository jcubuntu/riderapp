'use strict';

/**
 * Socket Module Index
 * Exports all socket-related functionality
 */

const socketManager = require('./socket.manager');
const chatHandler = require('./handlers/chat.handler');
const notificationHandler = require('./handlers/notification.handler');
const locationHandler = require('./handlers/location.handler');

module.exports = {
  // Socket Manager
  initialize: socketManager.initialize,
  getIO: socketManager.getIO,

  // Connection management
  isUserOnline: socketManager.isUserOnline,
  getUserSocketIds: socketManager.getUserSocketIds,
  getOnlineUsersCount: socketManager.getOnlineUsersCount,
  getOnlineUsersByRole: socketManager.getOnlineUsersByRole,

  // General emit helpers
  emitToUser: socketManager.emitToUser,
  emitToRole: socketManager.emitToRole,
  emitToMinimumRole: socketManager.emitToMinimumRole,
  emitToRoom: socketManager.emitToRoom,
  emitToAll: socketManager.emitToAll,

  // Chat emit helpers
  emitNewMessage: chatHandler.emitNewMessage,
  emitConversationUpdate: chatHandler.emitConversationUpdate,

  // Notification emit helpers
  emitNotification: notificationHandler.emitNotification,
  emitNotificationToUsers: notificationHandler.emitNotificationToUsers,
  emitNotificationCount: notificationHandler.emitNotificationCount,
  emitNotificationCountDetailed: notificationHandler.emitNotificationCountDetailed,
  emitNotificationRead: notificationHandler.emitNotificationRead,
  emitAllNotificationsRead: notificationHandler.emitAllNotificationsRead,
  emitUrgentNotification: notificationHandler.emitUrgentNotification,
  emitBroadcastToRole: notificationHandler.emitBroadcastToRole,
  emitSystemNotification: notificationHandler.emitSystemNotification,

  // Location emit helpers
  emitLocationUpdate: locationHandler.emitLocationUpdate,
  emitEmergencyAlert: locationHandler.emitEmergencyAlert,
  emitSharingStatusChange: locationHandler.emitSharingStatusChange,
  getTrackingStats: locationHandler.getTrackingStats,
};
