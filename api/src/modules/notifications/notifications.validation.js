'use strict';

const Joi = require('joi');

/**
 * Notifications Validation Schemas
 */

/**
 * Valid notification types
 */
const NOTIFICATION_TYPES = ['info', 'success', 'warning', 'error', 'action'];

/**
 * Valid notification categories
 */
const NOTIFICATION_CATEGORIES = ['system', 'incident', 'chat', 'announcement', 'approval', 'alert', 'reminder'];

/**
 * Valid notification priorities
 */
const NOTIFICATION_PRIORITIES = ['low', 'normal', 'high'];

/**
 * Query params for listing notifications
 */
const listNotificationsSchema = Joi.object({
  page: Joi.number().integer().min(1).default(1),
  limit: Joi.number().integer().min(1).max(100).default(10),
  category: Joi.string().valid(...NOTIFICATION_CATEGORIES).allow(''),
  type: Joi.string().valid(...NOTIFICATION_TYPES).allow(''),
  isRead: Joi.alternatives().try(
    Joi.boolean(),
    Joi.string().valid('true', 'false')
  ).allow(''),
  sortBy: Joi.string().valid('created_at', 'priority', 'type', 'category', 'is_read').default('created_at'),
  sortOrder: Joi.string().valid('ASC', 'DESC', 'asc', 'desc').default('DESC'),
});

/**
 * Path params for notification ID
 */
const notificationIdSchema = Joi.object({
  id: Joi.string().uuid().required(),
});

/**
 * Query params for unread count
 */
const unreadCountSchema = Joi.object({
  detailed: Joi.string().valid('true', 'false').default('false'),
});

/**
 * Schema for creating a notification (internal use)
 */
const createNotificationSchema = Joi.object({
  userId: Joi.string().uuid().required(),
  title: Joi.string().min(1).max(255).required(),
  body: Joi.string().min(1).max(5000).required(),
  summary: Joi.string().max(500).allow(null, ''),
  type: Joi.string().valid(...NOTIFICATION_TYPES).default('info'),
  category: Joi.string().valid(...NOTIFICATION_CATEGORIES).default('system'),
  entityType: Joi.string().max(100).allow(null, ''),
  entityId: Joi.string().uuid().allow(null, ''),
  actionUrl: Joi.string().max(500).allow(null, ''),
  actionType: Joi.string().max(50).allow(null, ''),
  imageUrl: Joi.string().uri().max(500).allow(null, ''),
  icon: Joi.string().max(100).allow(null, ''),
  priority: Joi.string().valid(...NOTIFICATION_PRIORITIES).default('normal'),
  senderId: Joi.string().uuid().allow(null),
  data: Joi.object().allow(null),
  scheduledAt: Joi.date().iso().allow(null),
  expiresAt: Joi.date().iso().allow(null),
});

/**
 * Schema for test push notification
 */
const testPushSchema = Joi.object({
  title: Joi.string().max(255).allow(null, ''),
  body: Joi.string().max(1000).allow(null, ''),
});

/**
 * Schema for sending push notification
 */
const sendPushSchema = Joi.object({
  userIds: Joi.array().items(Joi.string().uuid()).min(1).max(1000),
  role: Joi.string().valid('rider', 'volunteer', 'police', 'admin', 'super_admin'),
  title: Joi.string().min(1).max(255).required(),
  body: Joi.string().min(1).max(2000).required(),
  type: Joi.string().valid('chat', 'incident', 'announcement', 'sos', 'approval', 'alert', 'system'),
  targetId: Joi.string().uuid().allow(null, ''),
  data: Joi.object().allow(null),
  priority: Joi.string().valid('normal', 'high').default('normal'),
  imageUrl: Joi.string().uri().max(500).allow(null, ''),
}).or('userIds', 'role');

/**
 * Schema for processing pending push notifications
 */
const processPendingSchema = Joi.object({
  limit: Joi.number().integer().min(1).max(500).default(100),
});

/**
 * Validation middleware factory
 * @param {Joi.Schema} schema - Joi schema to validate against
 * @param {string} property - Request property to validate ('body', 'query', 'params')
 */
const validate = (schema, property = 'body') => {
  return (req, res, next) => {
    const { error, value } = schema.validate(req[property], {
      abortEarly: false,
      stripUnknown: true,
    });

    if (error) {
      const errors = error.details.map((detail) => ({
        field: detail.path.join('.'),
        message: detail.message,
      }));

      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors,
      });
    }

    // Replace request property with validated value
    req[property] = value;
    next();
  };
};

module.exports = {
  NOTIFICATION_TYPES,
  NOTIFICATION_CATEGORIES,
  NOTIFICATION_PRIORITIES,
  listNotificationsSchema,
  notificationIdSchema,
  unreadCountSchema,
  createNotificationSchema,
  testPushSchema,
  sendPushSchema,
  processPendingSchema,
  validate,
};
