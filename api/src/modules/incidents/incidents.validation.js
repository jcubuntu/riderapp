'use strict';

const Joi = require('joi');

/**
 * Incidents Validation Schemas
 */

// Incident category enum
const CATEGORIES = ['intelligence', 'accident', 'general'];

// Incident status enum
const STATUSES = ['pending', 'reviewing', 'verified', 'resolved', 'rejected'];

// Incident priority enum
const PRIORITIES = ['low', 'medium', 'high', 'critical'];

/**
 * Query params for listing incidents
 */
const listIncidentsSchema = Joi.object({
  page: Joi.number().integer().min(1).default(1),
  limit: Joi.number().integer().min(1).max(100).default(10),
  search: Joi.string().max(200).allow(''),
  category: Joi.string().valid(...CATEGORIES).allow(''),
  status: Joi.string().valid(...STATUSES).allow(''),
  priority: Joi.string().valid(...PRIORITIES).allow(''),
  province: Joi.string().max(100).allow(''),
  assignedTo: Joi.string().uuid().allow(''),
  reportedBy: Joi.string().uuid().allow(''),
  dateFrom: Joi.date().iso().allow(''),
  dateTo: Joi.date().iso().allow(''),
  sortBy: Joi.string().valid(
    'created_at', 'updated_at', 'title', 'category', 'status', 'priority', 'incident_date', 'view_count'
  ).default('created_at'),
  sortOrder: Joi.string().valid('ASC', 'DESC', 'asc', 'desc').default('DESC'),
});

/**
 * Query params for listing own incidents
 */
const listMyIncidentsSchema = Joi.object({
  page: Joi.number().integer().min(1).default(1),
  limit: Joi.number().integer().min(1).max(100).default(10),
  search: Joi.string().max(200).allow(''),
  category: Joi.string().valid(...CATEGORIES).allow(''),
  status: Joi.string().valid(...STATUSES).allow(''),
  priority: Joi.string().valid(...PRIORITIES).allow(''),
  sortBy: Joi.string().valid('created_at', 'updated_at', 'title', 'category', 'status', 'priority').default('created_at'),
  sortOrder: Joi.string().valid('ASC', 'DESC', 'asc', 'desc').default('DESC'),
});

/**
 * Path params for incident ID
 */
const incidentIdSchema = Joi.object({
  id: Joi.string().uuid().required(),
});

/**
 * Path params for incident and attachment IDs
 */
const attachmentIdSchema = Joi.object({
  id: Joi.string().uuid().required(),
  attachmentId: Joi.string().uuid().required(),
});

/**
 * Create incident body
 */
const createIncidentSchema = Joi.object({
  title: Joi.string().min(5).max(255).required()
    .messages({
      'string.min': 'Title must be at least 5 characters',
      'string.max': 'Title cannot exceed 255 characters',
      'any.required': 'Title is required',
    }),
  description: Joi.string().min(10).max(5000).required()
    .messages({
      'string.min': 'Description must be at least 10 characters',
      'string.max': 'Description cannot exceed 5000 characters',
      'any.required': 'Description is required',
    }),
  category: Joi.string().valid(...CATEGORIES).default('general')
    .messages({
      'any.only': `Category must be one of: ${CATEGORIES.join(', ')}`,
    }),
  priority: Joi.string().valid(...PRIORITIES).default('medium')
    .messages({
      'any.only': `Priority must be one of: ${PRIORITIES.join(', ')}`,
    }),
  locationLat: Joi.number().min(-90).max(90).allow(null)
    .messages({
      'number.min': 'Latitude must be between -90 and 90',
      'number.max': 'Latitude must be between -90 and 90',
    }),
  locationLng: Joi.number().min(-180).max(180).allow(null)
    .messages({
      'number.min': 'Longitude must be between -180 and 180',
      'number.max': 'Longitude must be between -180 and 180',
    }),
  locationAddress: Joi.string().max(500).allow(null, ''),
  locationProvince: Joi.string().max(100).allow(null, ''),
  locationDistrict: Joi.string().max(100).allow(null, ''),
  incidentDate: Joi.date().iso().max('now').allow(null)
    .messages({
      'date.max': 'Incident date cannot be in the future',
    }),
  isAnonymous: Joi.boolean().default(false),
});

/**
 * Update incident body
 */
const updateIncidentSchema = Joi.object({
  title: Joi.string().min(5).max(255)
    .messages({
      'string.min': 'Title must be at least 5 characters',
      'string.max': 'Title cannot exceed 255 characters',
    }),
  description: Joi.string().min(10).max(5000)
    .messages({
      'string.min': 'Description must be at least 10 characters',
      'string.max': 'Description cannot exceed 5000 characters',
    }),
  category: Joi.string().valid(...CATEGORIES)
    .messages({
      'any.only': `Category must be one of: ${CATEGORIES.join(', ')}`,
    }),
  priority: Joi.string().valid(...PRIORITIES)
    .messages({
      'any.only': `Priority must be one of: ${PRIORITIES.join(', ')}`,
    }),
  locationLat: Joi.number().min(-90).max(90).allow(null)
    .messages({
      'number.min': 'Latitude must be between -90 and 90',
      'number.max': 'Latitude must be between -90 and 90',
    }),
  locationLng: Joi.number().min(-180).max(180).allow(null)
    .messages({
      'number.min': 'Longitude must be between -180 and 180',
      'number.max': 'Longitude must be between -180 and 180',
    }),
  locationAddress: Joi.string().max(500).allow(null, ''),
  locationProvince: Joi.string().max(100).allow(null, ''),
  locationDistrict: Joi.string().max(100).allow(null, ''),
  incidentDate: Joi.date().iso().max('now').allow(null)
    .messages({
      'date.max': 'Incident date cannot be in the future',
    }),
  isAnonymous: Joi.boolean(),
}).min(1).messages({
  'object.min': 'At least one field must be provided for update',
});

/**
 * Update incident status body
 */
const updateStatusSchema = Joi.object({
  status: Joi.string().valid(...STATUSES).required()
    .messages({
      'any.only': `Status must be one of: ${STATUSES.join(', ')}`,
      'any.required': 'Status is required',
    }),
  notes: Joi.string().max(1000).allow(null, '')
    .messages({
      'string.max': 'Notes cannot exceed 1000 characters',
    }),
});

/**
 * Assign incident body
 */
const assignIncidentSchema = Joi.object({
  assigneeId: Joi.string().uuid().required()
    .messages({
      'string.guid': 'Invalid assignee ID format',
      'any.required': 'Assignee ID is required',
    }),
});

/**
 * Upload attachment body (for description)
 */
const uploadAttachmentSchema = Joi.object({
  description: Joi.string().max(500).allow(null, ''),
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
  // Constants
  CATEGORIES,
  STATUSES,
  PRIORITIES,
  // Schemas
  listIncidentsSchema,
  listMyIncidentsSchema,
  incidentIdSchema,
  attachmentIdSchema,
  createIncidentSchema,
  updateIncidentSchema,
  updateStatusSchema,
  assignIncidentSchema,
  uploadAttachmentSchema,
  // Middleware
  validate,
};
