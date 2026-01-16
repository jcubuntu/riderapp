'use strict';

const { getMessaging, isFirebaseConfigured } = require('../config/firebase.config');
const logger = require('./logger.utils');

/**
 * Push Notification Utility
 * Provides functions to send push notifications via Firebase Cloud Messaging (FCM)
 */

// Notification types for the application
const NOTIFICATION_TYPES = {
  CHAT: 'chat',
  INCIDENT: 'incident',
  ANNOUNCEMENT: 'announcement',
  SOS: 'sos',
  APPROVAL: 'approval',
  ALERT: 'alert',
  SYSTEM: 'system',
};

// Maximum tokens per batch (FCM limit is 500)
const MAX_BATCH_SIZE = 500;

/**
 * Build notification payload for FCM
 * @param {Object} options - Notification options
 * @param {string} options.title - Notification title
 * @param {string} options.body - Notification body
 * @param {string} [options.imageUrl] - Optional image URL
 * @param {Object} [options.data] - Custom data payload
 * @param {string} [options.type] - Notification type (chat, incident, etc.)
 * @param {string} [options.targetId] - ID of related entity
 * @param {string} [options.action] - Action to perform (open, navigate)
 * @param {string} [options.priority] - Priority level (normal, high)
 * @param {string} [options.sound] - Notification sound
 * @param {string} [options.channelId] - Android notification channel ID
 * @returns {Object} FCM message payload
 */
const buildNotificationPayload = (options) => {
  const {
    title,
    body,
    imageUrl,
    data = {},
    type = NOTIFICATION_TYPES.SYSTEM,
    targetId,
    action = 'open',
    priority = 'normal',
    sound = 'default',
    channelId = 'default',
  } = options;

  // Base notification object
  const notification = {
    title,
    body,
  };

  // Add image if provided
  if (imageUrl) {
    notification.imageUrl = imageUrl;
  }

  // Build custom data payload
  const customData = {
    ...data,
    type,
    action,
    timestamp: new Date().toISOString(),
  };

  if (targetId) {
    customData.targetId = targetId;
  }

  // Convert all data values to strings (FCM requirement)
  const stringifiedData = {};
  Object.keys(customData).forEach((key) => {
    const value = customData[key];
    stringifiedData[key] = typeof value === 'object' ? JSON.stringify(value) : String(value);
  });

  // Build the message payload
  const message = {
    notification,
    data: stringifiedData,
    android: {
      priority: priority === 'high' ? 'high' : 'normal',
      notification: {
        sound,
        channelId,
        clickAction: 'FLUTTER_NOTIFICATION_CLICK',
      },
    },
    apns: {
      headers: {
        'apns-priority': priority === 'high' ? '10' : '5',
      },
      payload: {
        aps: {
          sound,
          badge: 1,
          contentAvailable: true,
        },
      },
    },
  };

  return message;
};

/**
 * Send push notification to a single device
 * @param {string} token - FCM device token
 * @param {Object} options - Notification options
 * @returns {Promise<Object>} Result object with success status
 */
const sendToDevice = async (token, options) => {
  if (!isFirebaseConfigured()) {
    logger.warn('Firebase not configured, skipping push notification');
    return { success: false, error: 'FIREBASE_NOT_CONFIGURED' };
  }

  if (!token) {
    logger.warn('No device token provided for push notification');
    return { success: false, error: 'NO_TOKEN' };
  }

  try {
    const messaging = getMessaging();
    if (!messaging) {
      return { success: false, error: 'MESSAGING_NOT_AVAILABLE' };
    }

    const payload = buildNotificationPayload(options);
    payload.token = token;

    const response = await messaging.send(payload);

    logger.debug('Push notification sent successfully', {
      messageId: response,
      token: token.substring(0, 20) + '...',
    });

    return {
      success: true,
      messageId: response,
    };
  } catch (error) {
    logger.error('Failed to send push notification', {
      error: error.message,
      code: error.code,
      token: token.substring(0, 20) + '...',
    });

    return {
      success: false,
      error: error.code || error.message,
      isInvalidToken: isInvalidTokenError(error),
    };
  }
};

/**
 * Send push notification to multiple devices
 * @param {string[]} tokens - Array of FCM device tokens
 * @param {Object} options - Notification options
 * @returns {Promise<Object>} Result object with success/failure counts
 */
const sendToDevices = async (tokens, options) => {
  if (!isFirebaseConfigured()) {
    logger.warn('Firebase not configured, skipping push notifications');
    return { success: false, error: 'FIREBASE_NOT_CONFIGURED', successCount: 0, failureCount: tokens.length };
  }

  if (!tokens || tokens.length === 0) {
    logger.warn('No device tokens provided for push notifications');
    return { success: false, error: 'NO_TOKENS', successCount: 0, failureCount: 0 };
  }

  // Filter out empty/null tokens
  const validTokens = tokens.filter((token) => token && typeof token === 'string' && token.trim() !== '');

  if (validTokens.length === 0) {
    return { success: false, error: 'NO_VALID_TOKENS', successCount: 0, failureCount: 0 };
  }

  try {
    const messaging = getMessaging();
    if (!messaging) {
      return { success: false, error: 'MESSAGING_NOT_AVAILABLE', successCount: 0, failureCount: validTokens.length };
    }

    const payload = buildNotificationPayload(options);

    // If only one token, use send() instead of sendEachForMulticast()
    if (validTokens.length === 1) {
      const result = await sendToDevice(validTokens[0], options);
      return {
        success: result.success,
        successCount: result.success ? 1 : 0,
        failureCount: result.success ? 0 : 1,
        invalidTokens: result.isInvalidToken ? [validTokens[0]] : [],
        responses: [result],
      };
    }

    // Use sendEachForMulticast for multiple tokens
    const message = {
      ...payload,
      tokens: validTokens,
    };

    const response = await messaging.sendEachForMulticast(message);

    // Collect invalid tokens for cleanup
    const invalidTokens = [];
    const responses = [];

    response.responses.forEach((resp, index) => {
      if (!resp.success) {
        if (isInvalidTokenError(resp.error)) {
          invalidTokens.push(validTokens[index]);
        }
        responses.push({
          success: false,
          error: resp.error?.code || resp.error?.message,
          token: validTokens[index],
        });
      } else {
        responses.push({
          success: true,
          messageId: resp.messageId,
          token: validTokens[index],
        });
      }
    });

    logger.info('Multicast push notification completed', {
      successCount: response.successCount,
      failureCount: response.failureCount,
      invalidTokenCount: invalidTokens.length,
    });

    return {
      success: response.successCount > 0,
      successCount: response.successCount,
      failureCount: response.failureCount,
      invalidTokens,
      responses,
    };
  } catch (error) {
    logger.error('Failed to send multicast push notification', {
      error: error.message,
      tokenCount: validTokens.length,
    });

    return {
      success: false,
      error: error.code || error.message,
      successCount: 0,
      failureCount: validTokens.length,
      invalidTokens: [],
    };
  }
};

/**
 * Send push notification in batches (for large recipient lists)
 * @param {string[]} tokens - Array of FCM device tokens
 * @param {Object} options - Notification options
 * @param {number} [batchSize=500] - Maximum tokens per batch
 * @returns {Promise<Object>} Aggregated result object
 */
const sendInBatches = async (tokens, options, batchSize = MAX_BATCH_SIZE) => {
  if (!tokens || tokens.length === 0) {
    return { success: false, error: 'NO_TOKENS', successCount: 0, failureCount: 0, invalidTokens: [] };
  }

  // Filter valid tokens
  const validTokens = tokens.filter((token) => token && typeof token === 'string' && token.trim() !== '');

  if (validTokens.length === 0) {
    return { success: false, error: 'NO_VALID_TOKENS', successCount: 0, failureCount: 0, invalidTokens: [] };
  }

  // If within single batch size, use sendToDevices directly
  if (validTokens.length <= batchSize) {
    return sendToDevices(validTokens, options);
  }

  logger.info('Sending push notifications in batches', {
    totalTokens: validTokens.length,
    batchSize,
    batchCount: Math.ceil(validTokens.length / batchSize),
  });

  let totalSuccess = 0;
  let totalFailure = 0;
  const allInvalidTokens = [];
  const allResponses = [];

  // Process in batches
  for (let i = 0; i < validTokens.length; i += batchSize) {
    const batch = validTokens.slice(i, i + batchSize);
    const batchNumber = Math.floor(i / batchSize) + 1;

    logger.debug(`Processing batch ${batchNumber}`, { batchSize: batch.length });

    const result = await sendToDevices(batch, options);

    totalSuccess += result.successCount || 0;
    totalFailure += result.failureCount || 0;

    if (result.invalidTokens && result.invalidTokens.length > 0) {
      allInvalidTokens.push(...result.invalidTokens);
    }

    if (result.responses) {
      allResponses.push(...result.responses);
    }

    // Small delay between batches to avoid rate limiting
    if (i + batchSize < validTokens.length) {
      await new Promise((resolve) => setTimeout(resolve, 100));
    }
  }

  return {
    success: totalSuccess > 0,
    successCount: totalSuccess,
    failureCount: totalFailure,
    invalidTokens: allInvalidTokens,
    responses: allResponses,
  };
};

/**
 * Send push notification to a topic
 * @param {string} topic - Topic name (without /topics/ prefix)
 * @param {Object} options - Notification options
 * @returns {Promise<Object>} Result object
 */
const sendToTopic = async (topic, options) => {
  if (!isFirebaseConfigured()) {
    logger.warn('Firebase not configured, skipping topic notification');
    return { success: false, error: 'FIREBASE_NOT_CONFIGURED' };
  }

  if (!topic) {
    return { success: false, error: 'NO_TOPIC' };
  }

  try {
    const messaging = getMessaging();
    if (!messaging) {
      return { success: false, error: 'MESSAGING_NOT_AVAILABLE' };
    }

    const payload = buildNotificationPayload(options);
    payload.topic = topic;

    const response = await messaging.send(payload);

    logger.info('Topic push notification sent successfully', {
      messageId: response,
      topic,
    });

    return {
      success: true,
      messageId: response,
    };
  } catch (error) {
    logger.error('Failed to send topic push notification', {
      error: error.message,
      topic,
    });

    return {
      success: false,
      error: error.code || error.message,
    };
  }
};

/**
 * Subscribe tokens to a topic
 * @param {string[]} tokens - Device tokens to subscribe
 * @param {string} topic - Topic name
 * @returns {Promise<Object>} Result object
 */
const subscribeToTopic = async (tokens, topic) => {
  if (!isFirebaseConfigured()) {
    return { success: false, error: 'FIREBASE_NOT_CONFIGURED' };
  }

  if (!tokens || tokens.length === 0 || !topic) {
    return { success: false, error: 'INVALID_PARAMS' };
  }

  try {
    const messaging = getMessaging();
    if (!messaging) {
      return { success: false, error: 'MESSAGING_NOT_AVAILABLE' };
    }

    const response = await messaging.subscribeToTopic(tokens, topic);

    logger.info('Subscribed tokens to topic', {
      topic,
      successCount: response.successCount,
      failureCount: response.failureCount,
    });

    return {
      success: response.successCount > 0,
      successCount: response.successCount,
      failureCount: response.failureCount,
    };
  } catch (error) {
    logger.error('Failed to subscribe to topic', {
      error: error.message,
      topic,
    });

    return { success: false, error: error.message };
  }
};

/**
 * Unsubscribe tokens from a topic
 * @param {string[]} tokens - Device tokens to unsubscribe
 * @param {string} topic - Topic name
 * @returns {Promise<Object>} Result object
 */
const unsubscribeFromTopic = async (tokens, topic) => {
  if (!isFirebaseConfigured()) {
    return { success: false, error: 'FIREBASE_NOT_CONFIGURED' };
  }

  if (!tokens || tokens.length === 0 || !topic) {
    return { success: false, error: 'INVALID_PARAMS' };
  }

  try {
    const messaging = getMessaging();
    if (!messaging) {
      return { success: false, error: 'MESSAGING_NOT_AVAILABLE' };
    }

    const response = await messaging.unsubscribeFromTopic(tokens, topic);

    logger.info('Unsubscribed tokens from topic', {
      topic,
      successCount: response.successCount,
      failureCount: response.failureCount,
    });

    return {
      success: response.successCount > 0,
      successCount: response.successCount,
      failureCount: response.failureCount,
    };
  } catch (error) {
    logger.error('Failed to unsubscribe from topic', {
      error: error.message,
      topic,
    });

    return { success: false, error: error.message };
  }
};

/**
 * Check if error indicates an invalid token
 * @param {Error} error - Firebase error
 * @returns {boolean}
 */
const isInvalidTokenError = (error) => {
  if (!error) return false;

  const invalidTokenCodes = [
    'messaging/invalid-registration-token',
    'messaging/registration-token-not-registered',
    'messaging/invalid-argument',
  ];

  return invalidTokenCodes.includes(error.code);
};

// ============= Convenience functions for specific notification types =============

/**
 * Send chat notification
 * @param {string} token - Device token
 * @param {Object} options - Chat notification options
 * @returns {Promise<Object>}
 */
const sendChatNotification = async (token, { senderName, message, conversationId, imageUrl }) => {
  return sendToDevice(token, {
    title: senderName,
    body: message,
    imageUrl,
    type: NOTIFICATION_TYPES.CHAT,
    targetId: conversationId,
    action: 'navigate',
    data: {
      screen: '/chat',
      conversationId,
    },
  });
};

/**
 * Send incident notification
 * @param {string} token - Device token
 * @param {Object} options - Incident notification options
 * @returns {Promise<Object>}
 */
const sendIncidentNotification = async (token, { title, body, incidentId, incidentType, priority = 'normal' }) => {
  return sendToDevice(token, {
    title,
    body,
    type: NOTIFICATION_TYPES.INCIDENT,
    targetId: incidentId,
    action: 'navigate',
    priority,
    data: {
      screen: '/incidents',
      incidentId,
      incidentType,
    },
  });
};

/**
 * Send announcement notification
 * @param {string[]} tokens - Device tokens
 * @param {Object} options - Announcement options
 * @returns {Promise<Object>}
 */
const sendAnnouncementNotification = async (tokens, { title, body, announcementId, imageUrl }) => {
  return sendToDevices(tokens, {
    title,
    body,
    imageUrl,
    type: NOTIFICATION_TYPES.ANNOUNCEMENT,
    targetId: announcementId,
    action: 'navigate',
    data: {
      screen: '/announcements',
      announcementId,
    },
  });
};

/**
 * Send SOS emergency notification
 * @param {string[]} tokens - Device tokens
 * @param {Object} options - SOS options
 * @returns {Promise<Object>}
 */
const sendSOSNotification = async (tokens, { riderName, location, sosId }) => {
  return sendToDevices(tokens, {
    title: 'SOS Emergency Alert',
    body: `${riderName} has triggered an emergency SOS alert!`,
    type: NOTIFICATION_TYPES.SOS,
    targetId: sosId,
    action: 'navigate',
    priority: 'high',
    sound: 'alarm',
    data: {
      screen: '/sos',
      sosId,
      location: JSON.stringify(location),
      urgent: 'true',
    },
  });
};

/**
 * Send approval notification
 * @param {string} token - Device token
 * @param {Object} options - Approval options
 * @returns {Promise<Object>}
 */
const sendApprovalNotification = async (token, { title, body, userId, status }) => {
  return sendToDevice(token, {
    title,
    body,
    type: NOTIFICATION_TYPES.APPROVAL,
    targetId: userId,
    action: 'open',
    data: {
      status,
    },
  });
};

/**
 * Send alert notification
 * @param {string[]} tokens - Device tokens
 * @param {Object} options - Alert options
 * @returns {Promise<Object>}
 */
const sendAlertNotification = async (tokens, { title, body, alertType, targetId, priority = 'high' }) => {
  return sendToDevices(tokens, {
    title,
    body,
    type: NOTIFICATION_TYPES.ALERT,
    targetId,
    action: 'open',
    priority,
    data: {
      alertType,
    },
  });
};

module.exports = {
  // Core functions
  sendToDevice,
  sendToDevices,
  sendInBatches,
  sendToTopic,
  subscribeToTopic,
  unsubscribeFromTopic,
  buildNotificationPayload,
  isInvalidTokenError,

  // Convenience functions
  sendChatNotification,
  sendIncidentNotification,
  sendAnnouncementNotification,
  sendSOSNotification,
  sendApprovalNotification,
  sendAlertNotification,

  // Constants
  NOTIFICATION_TYPES,
  MAX_BATCH_SIZE,
};
