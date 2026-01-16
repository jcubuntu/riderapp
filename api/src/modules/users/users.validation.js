'use strict';

const Joi = require('joi');
const { getAllRoles } = require('../../constants/roles');

/**
 * Users Validation Schemas
 */

/**
 * Query params for listing users
 */
const listUsersSchema = Joi.object({
  page: Joi.number().integer().min(1).default(1),
  limit: Joi.number().integer().min(1).max(100).default(10),
  search: Joi.string().max(100).allow(''),
  role: Joi.string().valid(...getAllRoles()).allow(''),
  status: Joi.string().valid('pending', 'approved', 'rejected', 'inactive').allow(''),
  affiliation: Joi.string().max(100).allow(''),
  sortBy: Joi.string().valid('created_at', 'updated_at', 'full_name', 'email', 'role', 'status').default('created_at'),
  sortOrder: Joi.string().valid('ASC', 'DESC', 'asc', 'desc').default('DESC'),
});

/**
 * Query params for pending users
 */
const listPendingSchema = Joi.object({
  page: Joi.number().integer().min(1).default(1),
  limit: Joi.number().integer().min(1).max(100).default(10),
  search: Joi.string().max(100).allow(''),
});

/**
 * Path params for user ID
 */
const userIdSchema = Joi.object({
  id: Joi.string().uuid().required(),
});

/**
 * Update user body
 */
const updateUserSchema = Joi.object({
  email: Joi.string().email().max(255),
  phone: Joi.string().pattern(/^[0-9]{10}$/).message('Phone number must be 10 digits'),
  fullName: Joi.string().min(2).max(100),
  idCardNumber: Joi.string().pattern(/^[0-9]{13}$/).message('ID card number must be 13 digits'),
  affiliation: Joi.string().max(100).allow(null, ''),
  address: Joi.string().max(500).allow(null, ''),
  profileImageUrl: Joi.string().uri().max(500).allow(null, ''),
}).min(1).message('At least one field must be provided for update');

/**
 * Update user status body
 */
const updateStatusSchema = Joi.object({
  status: Joi.string().valid('pending', 'approved', 'rejected', 'inactive').required(),
});

/**
 * Update user role body
 */
const updateRoleSchema = Joi.object({
  role: Joi.string().valid(...getAllRoles()).required(),
});

/**
 * Reject user body
 */
const rejectUserSchema = Joi.object({
  reason: Joi.string().max(500).allow(null, ''),
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
  listUsersSchema,
  listPendingSchema,
  userIdSchema,
  updateUserSchema,
  updateStatusSchema,
  updateRoleSchema,
  rejectUserSchema,
  validate,
};
