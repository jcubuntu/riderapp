'use strict';

const express = require('express');
const router = express.Router();
const locationsController = require('./locations.controller');
const { authenticate } = require('../../middleware/auth.middleware');
const { policeOrAdmin, volunteerOrHigher } = require('../../middleware/role.middleware');
const {
  validate,
  updateLocationSchema,
  locationHistoryQuerySchema,
  ridersQuerySchema,
  riderIdSchema,
  updateSettingsSchema,
} = require('./locations.validation');

/**
 * Locations Routes
 *
 * Location Updates:
 *   POST   /locations/update          - Update current location (any authenticated)
 *   GET    /locations/my              - Get own location history (any authenticated)
 *   GET    /locations/my/latest       - Get latest location (any authenticated)
 *
 * Viewing Rider Locations (police+):
 *   GET    /locations/riders          - Get all sharing riders' locations (police+)
 *   GET    /locations/riders/:id      - Get specific rider's latest location (police+)
 *   GET    /locations/riders/:id/history - Get rider's location history (police+)
 *
 * Sharing Settings:
 *   GET    /locations/settings        - Get sharing settings (any authenticated)
 *   PUT    /locations/settings        - Update sharing settings (any authenticated)
 *   POST   /locations/share/start     - Start sharing location (any authenticated)
 *   POST   /locations/share/stop      - Stop sharing location (any authenticated)
 *
 * Statistics:
 *   GET    /locations/stats           - Get sharing statistics (volunteer+)
 */

// ==================== Location Update Routes ====================

/**
 * @route   POST /api/v1/locations/update
 * @desc    Update current user's location
 * @access  Any authenticated user
 * @body    {latitude, longitude, accuracy?, altitude?, speed?, heading?, address?, province?, district?, batteryLevel?}
 */
router.post(
  '/update',
  authenticate,
  validate(updateLocationSchema, 'body'),
  locationsController.updateLocation
);

/**
 * @route   GET /api/v1/locations/my
 * @desc    Get current user's location history (last 24 hours by default)
 * @access  Any authenticated user
 * @query   {page?, limit?, startDate?, endDate?}
 */
router.get(
  '/my',
  authenticate,
  validate(locationHistoryQuerySchema, 'query'),
  locationsController.getMyLocationHistory
);

/**
 * @route   GET /api/v1/locations/my/latest
 * @desc    Get current user's latest location
 * @access  Any authenticated user
 */
router.get(
  '/my/latest',
  authenticate,
  locationsController.getMyLatestLocation
);

// ==================== Viewing Rider Locations Routes (police+) ====================

/**
 * @route   GET /api/v1/locations/riders
 * @desc    Get all sharing riders' latest locations
 * @access  Police+
 * @query   {province?, limit?}
 */
router.get(
  '/riders',
  authenticate,
  policeOrAdmin,
  validate(ridersQuerySchema, 'query'),
  locationsController.getSharingRidersLocations
);

/**
 * @route   GET /api/v1/locations/riders/:id
 * @desc    Get specific rider's latest location
 * @access  Police+
 * @params  {id} - Rider UUID
 */
router.get(
  '/riders/:id',
  authenticate,
  policeOrAdmin,
  validate(riderIdSchema, 'params'),
  locationsController.getRiderLocation
);

/**
 * @route   GET /api/v1/locations/riders/:id/history
 * @desc    Get specific rider's location history
 * @access  Police+
 * @params  {id} - Rider UUID
 * @query   {page?, limit?, startDate?, endDate?}
 */
router.get(
  '/riders/:id/history',
  authenticate,
  policeOrAdmin,
  validate(riderIdSchema, 'params'),
  validate(locationHistoryQuerySchema, 'query'),
  locationsController.getRiderLocationHistory
);

// ==================== Sharing Settings Routes ====================

/**
 * @route   GET /api/v1/locations/settings
 * @desc    Get current user's sharing settings
 * @access  Any authenticated user
 */
router.get(
  '/settings',
  authenticate,
  locationsController.getSettings
);

/**
 * @route   PUT /api/v1/locations/settings
 * @desc    Update sharing settings
 * @access  Any authenticated user
 * @body    {isEnabled?, shareWithPolice?, shareWithVolunteers?, shareInEmergency?, autoShareOnIncident?}
 */
router.put(
  '/settings',
  authenticate,
  validate(updateSettingsSchema, 'body'),
  locationsController.updateSettings
);

/**
 * @route   POST /api/v1/locations/share/start
 * @desc    Start sharing location
 * @access  Any authenticated user
 */
router.post(
  '/share/start',
  authenticate,
  locationsController.startSharing
);

/**
 * @route   POST /api/v1/locations/share/stop
 * @desc    Stop sharing location
 * @access  Any authenticated user
 */
router.post(
  '/share/stop',
  authenticate,
  locationsController.stopSharing
);

// ==================== Statistics Routes ====================

/**
 * @route   GET /api/v1/locations/stats
 * @desc    Get sharing statistics
 * @access  Volunteer+
 */
router.get(
  '/stats',
  authenticate,
  volunteerOrHigher,
  locationsController.getSharingStats
);

module.exports = router;
