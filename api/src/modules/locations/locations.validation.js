'use strict';

const Joi = require('joi');

/**
 * Locations Validation Schemas
 */

/**
 * Update location body
 */
const updateLocationSchema = Joi.object({
  latitude: Joi.number().min(-90).max(90).required()
    .messages({
      'number.min': 'Latitude must be between -90 and 90',
      'number.max': 'Latitude must be between -90 and 90',
      'any.required': 'Latitude is required',
    }),
  longitude: Joi.number().min(-180).max(180).required()
    .messages({
      'number.min': 'Longitude must be between -180 and 180',
      'number.max': 'Longitude must be between -180 and 180',
      'any.required': 'Longitude is required',
    }),
  accuracy: Joi.number().min(0).max(10000).allow(null)
    .messages({ 'number.max': 'Accuracy must be less than 10000 meters' }),
  altitude: Joi.number().min(-500).max(10000).allow(null)
    .messages({
      'number.min': 'Altitude must be greater than -500 meters',
      'number.max': 'Altitude must be less than 10000 meters',
    }),
  speed: Joi.number().min(0).max(500).allow(null)
    .messages({ 'number.max': 'Speed must be less than 500 m/s' }),
  heading: Joi.number().min(0).max(360).allow(null)
    .messages({
      'number.min': 'Heading must be between 0 and 360 degrees',
      'number.max': 'Heading must be between 0 and 360 degrees',
    }),
  address: Joi.string().max(500).allow(null, '')
    .messages({ 'string.max': 'Address must be less than 500 characters' }),
  province: Joi.string().max(100).allow(null, '')
    .messages({ 'string.max': 'Province must be less than 100 characters' }),
  district: Joi.string().max(100).allow(null, '')
    .messages({ 'string.max': 'District must be less than 100 characters' }),
  batteryLevel: Joi.number().integer().min(0).max(100).allow(null)
    .messages({
      'number.min': 'Battery level must be between 0 and 100',
      'number.max': 'Battery level must be between 0 and 100',
    }),
});

/**
 * Query params for location history
 */
const locationHistoryQuerySchema = Joi.object({
  page: Joi.number().integer().min(1).default(1),
  limit: Joi.number().integer().min(1).max(200).default(50),
  startDate: Joi.date().iso().allow(''),
  endDate: Joi.date().iso().allow('')
    .when('startDate', {
      is: Joi.exist(),
      then: Joi.date().greater(Joi.ref('startDate')),
    }),
});

/**
 * Query params for riders list
 */
const ridersQuerySchema = Joi.object({
  province: Joi.string().max(100).allow(''),
  limit: Joi.number().integer().min(1).max(500).default(100),
});

/**
 * Path params for rider ID
 */
const riderIdSchema = Joi.object({
  id: Joi.string().uuid().required()
    .messages({ 'string.guid': 'Invalid rider ID format' }),
});

/**
 * Update sharing settings body
 */
const updateSettingsSchema = Joi.object({
  isEnabled: Joi.boolean(),
  shareWithPolice: Joi.boolean(),
  shareWithVolunteers: Joi.boolean(),
  shareInEmergency: Joi.boolean(),
  autoShareOnIncident: Joi.boolean(),
}).min(1).message('At least one setting must be provided for update');

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
  updateLocationSchema,
  locationHistoryQuerySchema,
  ridersQuerySchema,
  riderIdSchema,
  updateSettingsSchema,
  validate,
};
