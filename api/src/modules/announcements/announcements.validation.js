'use strict';

const Joi = require('joi');

/**
 * Announcements Validation Schemas
 */

// Valid enum values based on database schema
const CATEGORIES = ['general', 'safety', 'event', 'alert', 'update', 'maintenance'];
const PRIORITIES = ['low', 'normal', 'high', 'urgent'];
const TARGET_AUDIENCES = ['all', 'riders', 'police', 'admin'];
const STATUSES = ['draft', 'scheduled', 'published', 'archived'];

/**
 * Query params for listing announcements (admin view)
 */
const listAnnouncementsSchema = Joi.object({
  page: Joi.number().integer().min(1).default(1),
  limit: Joi.number().integer().min(1).max(100).default(10),
  search: Joi.string().max(100).allow(''),
  category: Joi.string().valid(...CATEGORIES).allow(''),
  priority: Joi.string().valid(...PRIORITIES).allow(''),
  status: Joi.string().valid(...STATUSES).allow(''),
  targetAudience: Joi.string().valid(...TARGET_AUDIENCES).allow(''),
  isPinned: Joi.string().valid('true', 'false').allow(''),
  sortBy: Joi.string().valid('created_at', 'updated_at', 'title', 'priority', 'category', 'status', 'publish_at', 'is_pinned').default('created_at'),
  sortOrder: Joi.string().valid('ASC', 'DESC', 'asc', 'desc').default('DESC'),
});

/**
 * Query params for active announcements (user view)
 */
const listActiveAnnouncementsSchema = Joi.object({
  page: Joi.number().integer().min(1).default(1),
  limit: Joi.number().integer().min(1).max(100).default(10),
});

/**
 * Path params for announcement ID
 */
const announcementIdSchema = Joi.object({
  id: Joi.string().uuid().required(),
});

/**
 * Create announcement body
 */
const createAnnouncementSchema = Joi.object({
  title: Joi.string().min(1).max(255).required(),
  content: Joi.string().min(1).required(),
  summary: Joi.string().max(500).allow(null, ''),
  imageUrl: Joi.string().uri().max(500).allow(null, ''),
  attachmentUrl: Joi.string().uri().max(500).allow(null, ''),
  attachmentName: Joi.string().max(255).allow(null, ''),
  category: Joi.string().valid(...CATEGORIES).default('general'),
  priority: Joi.string().valid(...PRIORITIES).default('normal'),
  targetAudience: Joi.string().valid(...TARGET_AUDIENCES).default('all'),
  targetProvince: Joi.string().max(100).allow(null, ''),
  status: Joi.string().valid('draft', 'scheduled', 'published').default('draft'),
  publishAt: Joi.date().iso().allow(null),
  expiresAt: Joi.date().iso().allow(null),
  isPinned: Joi.boolean().default(false),
});

/**
 * Update announcement body
 */
const updateAnnouncementSchema = Joi.object({
  title: Joi.string().min(1).max(255),
  content: Joi.string().min(1),
  summary: Joi.string().max(500).allow(null, ''),
  imageUrl: Joi.string().uri().max(500).allow(null, ''),
  attachmentUrl: Joi.string().uri().max(500).allow(null, ''),
  attachmentName: Joi.string().max(255).allow(null, ''),
  category: Joi.string().valid(...CATEGORIES),
  priority: Joi.string().valid(...PRIORITIES),
  targetAudience: Joi.string().valid(...TARGET_AUDIENCES),
  targetProvince: Joi.string().max(100).allow(null, ''),
  status: Joi.string().valid('draft', 'scheduled', 'published'),
  publishAt: Joi.date().iso().allow(null),
  expiresAt: Joi.date().iso().allow(null),
  isPinned: Joi.boolean(),
}).min(1).message('At least one field must be provided for update');

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
  listAnnouncementsSchema,
  listActiveAnnouncementsSchema,
  announcementIdSchema,
  createAnnouncementSchema,
  updateAnnouncementSchema,
  validate,
  // Export constants for use in other modules
  CATEGORIES,
  PRIORITIES,
  TARGET_AUDIENCES,
  STATUSES,
};
