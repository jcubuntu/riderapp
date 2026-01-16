'use strict';

const locationsService = require('./locations.service');
const {
  successResponse,
  paginatedResponse,
  createdResponse,
  notFoundResponse,
  badRequestResponse,
  forbiddenResponse,
  calculatePagination,
  parsePaginationQuery,
} = require('../../utils/response.utils');

/**
 * Locations Controller - Handle HTTP requests for location tracking
 */

// ==================== Location Updates ====================

/**
 * Update current user's location
 * POST /locations/update
 */
const updateLocation = async (req, res) => {
  try {
    const location = await locationsService.updateLocation(req.body, req.user);

    return createdResponse(res, location, 'Location updated successfully');
  } catch (error) {
    console.error('Update location error:', error);
    return badRequestResponse(res, 'Failed to update location');
  }
};

/**
 * Get current user's latest location
 * GET /locations/my/latest
 */
const getMyLatestLocation = async (req, res) => {
  try {
    const location = await locationsService.getMyLatestLocation(req.user);

    if (!location) {
      return successResponse(res, null, 'No location found');
    }

    return successResponse(res, location, 'Latest location retrieved successfully');
  } catch (error) {
    console.error('Get my latest location error:', error);
    return badRequestResponse(res, 'Failed to retrieve latest location');
  }
};

/**
 * Get current user's location history
 * GET /locations/my
 */
const getMyLocationHistory = async (req, res) => {
  try {
    const { page, limit } = parsePaginationQuery(req.query, { page: 1, limit: 50, maxLimit: 200 });
    const { startDate, endDate } = req.query;

    const result = await locationsService.getMyLocationHistory(
      { page, limit, startDate, endDate },
      req.user
    );

    const pagination = calculatePagination(page, limit, result.total);

    return paginatedResponse(res, result.locations, pagination, 'Location history retrieved successfully');
  } catch (error) {
    console.error('Get my location history error:', error);
    return badRequestResponse(res, 'Failed to retrieve location history');
  }
};

// ==================== Viewing Rider Locations (Police+) ====================

/**
 * Get all sharing riders' locations
 * GET /locations/riders
 */
const getSharingRidersLocations = async (req, res) => {
  try {
    const { province, limit } = req.query;

    const locations = await locationsService.getSharingRidersLocations(
      { province, limit: parseInt(limit, 10) || 100 },
      req.user
    );

    return successResponse(res, locations, 'Sharing riders locations retrieved successfully');
  } catch (error) {
    console.error('Get sharing riders locations error:', error);

    switch (error.message) {
      case 'ACCESS_DENIED':
        return forbiddenResponse(res, 'You do not have permission to view rider locations');
      default:
        return badRequestResponse(res, 'Failed to retrieve rider locations');
    }
  }
};

/**
 * Get specific rider's latest location
 * GET /locations/riders/:id
 */
const getRiderLocation = async (req, res) => {
  try {
    const { id } = req.params;

    const location = await locationsService.getRiderLocation(id, req.user);

    return successResponse(res, location, 'Rider location retrieved successfully');
  } catch (error) {
    console.error('Get rider location error:', error);

    switch (error.message) {
      case 'ACCESS_DENIED':
        return forbiddenResponse(res, 'You do not have permission to view rider locations');
      case 'RIDER_NOT_FOUND':
        return notFoundResponse(res, 'Rider not found or no location data available');
      default:
        return badRequestResponse(res, 'Failed to retrieve rider location');
    }
  }
};

/**
 * Get specific rider's location history
 * GET /locations/riders/:id/history
 */
const getRiderLocationHistory = async (req, res) => {
  try {
    const { id } = req.params;
    const { page, limit } = parsePaginationQuery(req.query, { page: 1, limit: 50, maxLimit: 200 });
    const { startDate, endDate } = req.query;

    const result = await locationsService.getRiderLocationHistory(
      id,
      { page, limit, startDate, endDate },
      req.user
    );

    const pagination = calculatePagination(page, limit, result.total);

    return paginatedResponse(
      res,
      { rider: result.rider, locations: result.locations },
      pagination,
      'Rider location history retrieved successfully'
    );
  } catch (error) {
    console.error('Get rider location history error:', error);

    switch (error.message) {
      case 'ACCESS_DENIED':
        return forbiddenResponse(res, 'You do not have permission to view rider location history');
      case 'RIDER_NOT_FOUND':
        return notFoundResponse(res, 'Rider not found');
      default:
        return badRequestResponse(res, 'Failed to retrieve rider location history');
    }
  }
};

// ==================== Location Sharing Settings ====================

/**
 * Get current user's sharing settings
 * GET /locations/settings
 */
const getSettings = async (req, res) => {
  try {
    const settings = await locationsService.getSettings(req.user);

    return successResponse(res, settings, 'Sharing settings retrieved successfully');
  } catch (error) {
    console.error('Get sharing settings error:', error);
    return badRequestResponse(res, 'Failed to retrieve sharing settings');
  }
};

/**
 * Update sharing settings
 * PUT /locations/settings
 */
const updateSettings = async (req, res) => {
  try {
    const settings = await locationsService.updateSettings(req.body, req.user);

    return successResponse(res, settings, 'Sharing settings updated successfully');
  } catch (error) {
    console.error('Update sharing settings error:', error);
    return badRequestResponse(res, 'Failed to update sharing settings');
  }
};

/**
 * Start sharing location
 * POST /locations/share/start
 */
const startSharing = async (req, res) => {
  try {
    const settings = await locationsService.startSharing(req.user);

    return successResponse(res, settings, 'Location sharing started');
  } catch (error) {
    console.error('Start sharing error:', error);
    return badRequestResponse(res, 'Failed to start location sharing');
  }
};

/**
 * Stop sharing location
 * POST /locations/share/stop
 */
const stopSharing = async (req, res) => {
  try {
    const settings = await locationsService.stopSharing(req.user);

    return successResponse(res, settings, 'Location sharing stopped');
  } catch (error) {
    console.error('Stop sharing error:', error);
    return badRequestResponse(res, 'Failed to stop location sharing');
  }
};

/**
 * Get sharing statistics
 * GET /locations/stats
 */
const getSharingStats = async (req, res) => {
  try {
    const stats = await locationsService.getSharingStats(req.user);

    return successResponse(res, stats, 'Sharing statistics retrieved successfully');
  } catch (error) {
    console.error('Get sharing stats error:', error);

    switch (error.message) {
      case 'ACCESS_DENIED':
        return forbiddenResponse(res, 'You do not have permission to view statistics');
      default:
        return badRequestResponse(res, 'Failed to retrieve sharing statistics');
    }
  }
};

module.exports = {
  // Location Updates
  updateLocation,
  getMyLatestLocation,
  getMyLocationHistory,
  // Viewing Rider Locations
  getSharingRidersLocations,
  getRiderLocation,
  getRiderLocationHistory,
  // Sharing Settings
  getSettings,
  updateSettings,
  startSharing,
  stopSharing,
  getSharingStats,
};
