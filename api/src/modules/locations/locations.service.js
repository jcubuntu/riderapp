'use strict';

const locationsRepository = require('./locations.repository');
const { ROLES, hasMinimumRole } = require('../../constants/roles');

/**
 * Locations Service - Business logic for location tracking
 */

// ==================== Location Updates ====================

/**
 * Update rider's location
 * @param {Object} data - Location data
 * @param {Object} currentUser - Current user
 * @returns {Promise<Object>}
 */
const updateLocation = async (data, currentUser) => {
  // Check if user has sharing enabled
  const settings = await locationsRepository.getOrCreateSettings(currentUser.id);
  const isSharing = Boolean(settings.is_enabled);

  // Create location record
  const locationData = {
    userId: currentUser.id,
    latitude: data.latitude,
    longitude: data.longitude,
    accuracy: data.accuracy || null,
    altitude: data.altitude || null,
    speed: data.speed || null,
    heading: data.heading || null,
    address: data.address || null,
    province: data.province || null,
    district: data.district || null,
    isSharing,
    batteryLevel: data.batteryLevel || null,
  };

  const location = await locationsRepository.createLocation(locationData);
  return formatLocation(location);
};

/**
 * Get current user's latest location
 * @param {Object} currentUser - Current user
 * @returns {Promise<Object|null>}
 */
const getMyLatestLocation = async (currentUser) => {
  const location = await locationsRepository.findLatestLocationByUserId(currentUser.id);
  if (!location) {
    return null;
  }
  return formatLocation(location);
};

/**
 * Get current user's location history
 * @param {Object} options - Query options
 * @param {Object} currentUser - Current user
 * @returns {Promise<Object>}
 */
const getMyLocationHistory = async (options, currentUser) => {
  const { locations, total } = await locationsRepository.findLocationHistoryByUserId(
    currentUser.id,
    options
  );

  return {
    locations: locations.map(formatLocation),
    total,
    page: options.page || 1,
    limit: options.limit || 50,
  };
};

// ==================== Viewing Rider Locations (Police+) ====================

/**
 * Get all sharing riders' locations
 * @param {Object} options - Query options
 * @param {Object} currentUser - Current user
 * @returns {Promise<Array>}
 */
const getSharingRidersLocations = async (options, currentUser) => {
  // Only police+ can view sharing riders
  if (!hasMinimumRole(currentUser.role, ROLES.POLICE)) {
    throw new Error('ACCESS_DENIED');
  }

  const locations = await locationsRepository.findSharingRidersLocations(options);
  return locations.map(formatRiderLocation);
};

/**
 * Get specific rider's latest location
 * @param {string} riderId - Rider user UUID
 * @param {Object} currentUser - Current user
 * @returns {Promise<Object>}
 */
const getRiderLocation = async (riderId, currentUser) => {
  // Only police+ can view rider locations
  if (!hasMinimumRole(currentUser.role, ROLES.POLICE)) {
    throw new Error('ACCESS_DENIED');
  }

  const location = await locationsRepository.findRiderLatestLocation(riderId);
  if (!location) {
    throw new Error('RIDER_NOT_FOUND');
  }

  return formatRiderLocation(location);
};

/**
 * Get specific rider's location history
 * @param {string} riderId - Rider user UUID
 * @param {Object} options - Query options
 * @param {Object} currentUser - Current user
 * @returns {Promise<Object>}
 */
const getRiderLocationHistory = async (riderId, options, currentUser) => {
  // Only police+ can view rider location history
  if (!hasMinimumRole(currentUser.role, ROLES.POLICE)) {
    throw new Error('ACCESS_DENIED');
  }

  // Check if rider exists by trying to get their latest location
  const latestLocation = await locationsRepository.findRiderLatestLocation(riderId);
  if (!latestLocation) {
    throw new Error('RIDER_NOT_FOUND');
  }

  const { locations, total } = await locationsRepository.findLocationHistoryByUserId(
    riderId,
    options
  );

  return {
    rider: {
      id: latestLocation.user_id,
      firstName: latestLocation.first_name,
      lastName: latestLocation.last_name,
      phone: latestLocation.phone,
      role: latestLocation.role,
    },
    locations: locations.map(formatLocation),
    total,
    page: options.page || 1,
    limit: options.limit || 50,
  };
};

// ==================== Location Sharing Settings ====================

/**
 * Get current user's sharing settings
 * @param {Object} currentUser - Current user
 * @returns {Promise<Object>}
 */
const getSettings = async (currentUser) => {
  const settings = await locationsRepository.getOrCreateSettings(currentUser.id);
  return formatSettings(settings);
};

/**
 * Update sharing settings
 * @param {Object} updates - Settings to update
 * @param {Object} currentUser - Current user
 * @returns {Promise<Object>}
 */
const updateSettings = async (updates, currentUser) => {
  // Ensure settings exist
  await locationsRepository.getOrCreateSettings(currentUser.id);

  const settings = await locationsRepository.updateSettings(currentUser.id, updates);
  return formatSettings(settings);
};

/**
 * Start sharing location
 * @param {Object} currentUser - Current user
 * @returns {Promise<Object>}
 */
const startSharing = async (currentUser) => {
  const settings = await locationsRepository.setSharing(currentUser.id, true);
  return formatSettings(settings);
};

/**
 * Stop sharing location
 * @param {Object} currentUser - Current user
 * @returns {Promise<Object>}
 */
const stopSharing = async (currentUser) => {
  const settings = await locationsRepository.setSharing(currentUser.id, false);
  return formatSettings(settings);
};

/**
 * Get sharing statistics (for dashboard)
 * @param {Object} currentUser - Current user
 * @returns {Promise<Object>}
 */
const getSharingStats = async (currentUser) => {
  // Only volunteer+ can view stats
  if (!hasMinimumRole(currentUser.role, ROLES.VOLUNTEER)) {
    throw new Error('ACCESS_DENIED');
  }

  const sharingCount = await locationsRepository.getSharingRidersCount();

  return {
    sharingRidersCount: sharingCount,
    timestamp: new Date().toISOString(),
  };
};

// ==================== Formatters ====================

/**
 * Format location for response
 * @param {Object} location - Location from database
 * @returns {Object}
 */
const formatLocation = (location) => {
  if (!location) return null;

  return {
    id: location.id,
    userId: location.user_id,
    coordinates: {
      latitude: parseFloat(location.latitude),
      longitude: parseFloat(location.longitude),
    },
    accuracy: location.accuracy ? parseFloat(location.accuracy) : null,
    altitude: location.altitude ? parseFloat(location.altitude) : null,
    speed: location.speed ? parseFloat(location.speed) : null,
    heading: location.heading ? parseFloat(location.heading) : null,
    address: location.address,
    province: location.province,
    district: location.district,
    isSharing: Boolean(location.is_sharing),
    batteryLevel: location.battery_level,
    createdAt: location.created_at,
  };
};

/**
 * Format rider location for police/admin response
 * @param {Object} location - Location with user info from database
 * @returns {Object}
 */
const formatRiderLocation = (location) => {
  if (!location) return null;

  return {
    id: location.id,
    rider: {
      id: location.user_id,
      firstName: location.first_name,
      lastName: location.last_name,
      phone: location.phone,
      role: location.role,
    },
    coordinates: {
      latitude: parseFloat(location.latitude),
      longitude: parseFloat(location.longitude),
    },
    accuracy: location.accuracy ? parseFloat(location.accuracy) : null,
    altitude: location.altitude ? parseFloat(location.altitude) : null,
    speed: location.speed ? parseFloat(location.speed) : null,
    heading: location.heading ? parseFloat(location.heading) : null,
    address: location.address,
    province: location.province,
    district: location.district,
    isSharing: Boolean(location.is_sharing),
    sharingEnabled: location.sharing_enabled !== undefined ? Boolean(location.sharing_enabled) : true,
    batteryLevel: location.battery_level,
    createdAt: location.created_at,
  };
};

/**
 * Format sharing settings for response
 * @param {Object} settings - Settings from database
 * @returns {Object}
 */
const formatSettings = (settings) => {
  if (!settings) return null;

  return {
    id: settings.id,
    userId: settings.user_id,
    isEnabled: Boolean(settings.is_enabled),
    shareWithPolice: Boolean(settings.share_with_police),
    shareWithVolunteers: Boolean(settings.share_with_volunteers),
    shareInEmergency: Boolean(settings.share_in_emergency),
    autoShareOnIncident: Boolean(settings.auto_share_on_incident),
    updatedAt: settings.updated_at,
  };
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
