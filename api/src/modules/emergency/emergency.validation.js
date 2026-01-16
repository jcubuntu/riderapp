'use strict';

const Joi = require('joi');

/**
 * Emergency Validation Schemas
 */

// Valid emergency contact categories
const CONTACT_CATEGORIES = ['police', 'hospital', 'fire', 'rescue', 'hotline', 'government', 'other'];

/**
 * Query params for listing contacts (public)
 */
const listContactsSchema = Joi.object({
  category: Joi.string().valid(...CONTACT_CATEGORIES).allow(''),
  province: Joi.string().max(100).allow(''),
});

/**
 * Query params for listing contacts (admin)
 */
const listContactsAdminSchema = Joi.object({
  page: Joi.number().integer().min(1).default(1),
  limit: Joi.number().integer().min(1).max(100).default(20),
  search: Joi.string().max(100).allow(''),
  category: Joi.string().valid(...CONTACT_CATEGORIES).allow(''),
  province: Joi.string().max(100).allow(''),
  isActive: Joi.string().valid('true', 'false').allow(''),
  isNationwide: Joi.string().valid('true', 'false').allow(''),
  is24Hours: Joi.string().valid('true', 'false').allow(''),
  sortBy: Joi.string().valid('priority', 'name', 'category', 'created_at', 'updated_at').default('priority'),
  sortOrder: Joi.string().valid('ASC', 'DESC', 'asc', 'desc').default('DESC'),
});

/**
 * Path params for contact ID
 */
const contactIdSchema = Joi.object({
  id: Joi.string().uuid().required(),
});

/**
 * Create contact body
 */
const createContactSchema = Joi.object({
  name: Joi.string().min(1).max(255).required()
    .messages({ 'string.empty': 'Contact name is required' }),
  phone: Joi.string().pattern(/^[0-9+\-\s()]{3,20}$/).required()
    .messages({
      'string.pattern.base': 'Phone number must be 3-20 characters with valid phone characters',
      'string.empty': 'Phone number is required',
    }),
  phoneSecondary: Joi.string().pattern(/^[0-9+\-\s()]{3,20}$/).allow(null, '')
    .messages({ 'string.pattern.base': 'Secondary phone must be valid phone format' }),
  email: Joi.string().email().max(255).allow(null, ''),
  category: Joi.string().valid(...CONTACT_CATEGORIES).default('other'),
  description: Joi.string().max(2000).allow(null, ''),
  address: Joi.string().max(1000).allow(null, ''),
  province: Joi.string().max(100).allow(null, ''),
  district: Joi.string().max(100).allow(null, ''),
  locationLat: Joi.number().min(-90).max(90).allow(null),
  locationLng: Joi.number().min(-180).max(180).allow(null),
  operatingHours: Joi.string().max(255).allow(null, ''),
  is24Hours: Joi.boolean().default(false),
  isActive: Joi.boolean().default(true),
  isNationwide: Joi.boolean().default(false),
  priority: Joi.number().integer().min(0).max(1000).default(0),
  iconUrl: Joi.string().uri().max(500).allow(null, ''),
});

/**
 * Update contact body
 */
const updateContactSchema = Joi.object({
  name: Joi.string().min(1).max(255)
    .messages({ 'string.empty': 'Contact name cannot be empty' }),
  phone: Joi.string().pattern(/^[0-9+\-\s()]{3,20}$/)
    .messages({ 'string.pattern.base': 'Phone number must be 3-20 characters with valid phone characters' }),
  phoneSecondary: Joi.string().pattern(/^[0-9+\-\s()]{3,20}$/).allow(null, ''),
  email: Joi.string().email().max(255).allow(null, ''),
  category: Joi.string().valid(...CONTACT_CATEGORIES),
  description: Joi.string().max(2000).allow(null, ''),
  address: Joi.string().max(1000).allow(null, ''),
  province: Joi.string().max(100).allow(null, ''),
  district: Joi.string().max(100).allow(null, ''),
  locationLat: Joi.number().min(-90).max(90).allow(null),
  locationLng: Joi.number().min(-180).max(180).allow(null),
  operatingHours: Joi.string().max(255).allow(null, ''),
  is24Hours: Joi.boolean(),
  isActive: Joi.boolean(),
  isNationwide: Joi.boolean(),
  priority: Joi.number().integer().min(0).max(1000),
  iconUrl: Joi.string().uri().max(500).allow(null, ''),
}).min(1).message('At least one field must be provided for update');

/**
 * Trigger SOS body
 */
const triggerSosSchema = Joi.object({
  latitude: Joi.number().min(-90).max(90).allow(null),
  longitude: Joi.number().min(-180).max(180).allow(null),
  message: Joi.string().max(500).allow(null, ''),
});

/**
 * Resolve SOS body
 */
const resolveSosSchema = Joi.object({
  notes: Joi.string().max(1000).allow(null, ''),
});

/**
 * Path params for SOS ID
 */
const sosIdSchema = Joi.object({
  id: Joi.string().uuid().required(),
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
  CONTACT_CATEGORIES,
  listContactsSchema,
  listContactsAdminSchema,
  contactIdSchema,
  createContactSchema,
  updateContactSchema,
  triggerSosSchema,
  resolveSosSchema,
  sosIdSchema,
  validate,
};
