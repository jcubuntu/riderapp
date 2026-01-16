'use strict';

const Joi = require('joi');

/**
 * Stats Validation Schemas
 */

/**
 * Common date range query parameters
 */
const dateRangeSchema = Joi.object({
  startDate: Joi.date().iso().allow(''),
  endDate: Joi.date().iso().min(Joi.ref('startDate')).allow(''),
});

/**
 * Dashboard query parameters
 */
const dashboardSchema = Joi.object({
  recentLimit: Joi.number().integer().min(1).max(20).default(5),
});

/**
 * Incident summary query parameters
 */
const incidentSummarySchema = Joi.object({
  startDate: Joi.date().iso().allow(''),
  endDate: Joi.date().iso().allow(''),
});

/**
 * Incidents by type query parameters
 */
const incidentsByTypeSchema = Joi.object({
  startDate: Joi.date().iso().allow(''),
  endDate: Joi.date().iso().allow(''),
});

/**
 * Incidents by status query parameters
 */
const incidentsByStatusSchema = Joi.object({
  startDate: Joi.date().iso().allow(''),
  endDate: Joi.date().iso().allow(''),
});

/**
 * Incidents by priority query parameters
 */
const incidentsByPrioritySchema = Joi.object({
  startDate: Joi.date().iso().allow(''),
  endDate: Joi.date().iso().allow(''),
});

/**
 * Incident trend query parameters
 */
const incidentTrendSchema = Joi.object({
  startDate: Joi.date().iso().allow(''),
  endDate: Joi.date().iso().allow(''),
  interval: Joi.string().valid('daily', 'weekly', 'monthly').default('daily'),
});

/**
 * Incidents by province query parameters
 */
const incidentsByProvinceSchema = Joi.object({
  startDate: Joi.date().iso().allow(''),
  endDate: Joi.date().iso().allow(''),
  limit: Joi.number().integer().min(1).max(50).default(10),
});

/**
 * Users by role query parameters
 */
const usersByRoleSchema = Joi.object({
  status: Joi.string().valid('pending', 'approved', 'rejected', 'inactive', '').default('approved'),
});

/**
 * User registration trend query parameters
 */
const userTrendSchema = Joi.object({
  startDate: Joi.date().iso().allow(''),
  endDate: Joi.date().iso().allow(''),
  interval: Joi.string().valid('daily', 'weekly', 'monthly').default('daily'),
});

/**
 * Validation middleware factory
 * @param {Joi.Schema} schema - Joi schema to validate against
 * @param {string} property - Request property to validate ('body', 'query', 'params')
 */
const validate = (schema, property = 'query') => {
  return (req, res, next) => {
    const { error, value } = schema.validate(req[property], {
      abortEarly: false,
      stripUnknown: true,
      convert: true,
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
  dateRangeSchema,
  dashboardSchema,
  incidentSummarySchema,
  incidentsByTypeSchema,
  incidentsByStatusSchema,
  incidentsByPrioritySchema,
  incidentTrendSchema,
  incidentsByProvinceSchema,
  usersByRoleSchema,
  userTrendSchema,
  validate,
};
