'use strict';

const db = require('../../config/database');
const { v4: uuidv4 } = require('uuid');

/**
 * Locations Repository - Database operations for location tracking
 */

// ==================== Location Records ====================

/**
 * Create a new location record
 * @param {Object} data - Location data
 * @returns {Promise<Object>}
 */
const createLocation = async (data) => {
  const id = uuidv4();

  const sql = `
    INSERT INTO locations (
      id, user_id, latitude, longitude, accuracy, altitude,
      speed, heading, address, province, district,
      is_sharing, battery_level
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `;

  await db.query(sql, [
    id,
    data.userId,
    data.latitude,
    data.longitude,
    data.accuracy || null,
    data.altitude || null,
    data.speed || null,
    data.heading || null,
    data.address || null,
    data.province || null,
    data.district || null,
    data.isSharing || false,
    data.batteryLevel || null,
  ]);

  return findLocationById(id);
};

/**
 * Find location by ID
 * @param {string} id - Location UUID
 * @returns {Promise<Object|null>}
 */
const findLocationById = async (id) => {
  const sql = `
    SELECT id, user_id, latitude, longitude, accuracy, altitude,
           speed, heading, address, province, district,
           is_sharing, battery_level, created_at
    FROM locations
    WHERE id = ?
  `;
  return db.queryOne(sql, [id]);
};

/**
 * Find latest location for a user
 * @param {string} userId - User UUID
 * @returns {Promise<Object|null>}
 */
const findLatestLocationByUserId = async (userId) => {
  const sql = `
    SELECT id, user_id, latitude, longitude, accuracy, altitude,
           speed, heading, address, province, district,
           is_sharing, battery_level, created_at
    FROM locations
    WHERE user_id = ?
    ORDER BY created_at DESC
    LIMIT 1
  `;
  return db.queryOne(sql, [userId]);
};

/**
 * Find location history for a user
 * @param {string} userId - User UUID
 * @param {Object} options - Query options
 * @returns {Promise<{locations: Array, total: number}>}
 */
const findLocationHistoryByUserId = async (userId, options = {}) => {
  const {
    page = 1,
    limit = 50,
    startDate = null,
    endDate = null,
  } = options;

  const offset = (page - 1) * limit;
  const conditions = ['user_id = ?'];
  const params = [userId];

  // Filter by date range (default to last 24 hours if not specified)
  if (startDate) {
    conditions.push('created_at >= ?');
    params.push(startDate);
  } else {
    // Default to last 24 hours
    conditions.push('created_at >= DATE_SUB(NOW(), INTERVAL 24 HOUR)');
  }

  if (endDate) {
    conditions.push('created_at <= ?');
    params.push(endDate);
  }

  const whereClause = `WHERE ${conditions.join(' AND ')}`;

  // Get total count
  const countSql = `SELECT COUNT(*) as total FROM locations ${whereClause}`;
  const countResult = await db.queryOne(countSql, params);
  const total = countResult ? Number(countResult.total) : 0;

  // Get locations
  const sql = `
    SELECT id, user_id, latitude, longitude, accuracy, altitude,
           speed, heading, address, province, district,
           is_sharing, battery_level, created_at
    FROM locations
    ${whereClause}
    ORDER BY created_at DESC
    LIMIT ? OFFSET ?
  `;

  const locations = await db.query(sql, [...params, limit, offset]);

  return { locations, total };
};

/**
 * Find all sharing riders' latest locations
 * @param {Object} options - Query options
 * @returns {Promise<Array>}
 */
const findSharingRidersLocations = async (options = {}) => {
  const { province = '', limit = 100 } = options;

  const conditions = ['l.is_sharing = TRUE'];
  const params = [];

  if (province) {
    conditions.push('l.province = ?');
    params.push(province);
  }

  // Get only users who have sharing enabled in their settings
  const whereClause = `WHERE ${conditions.join(' AND ')}`;

  // Subquery to get the latest location for each user who is sharing
  const sql = `
    SELECT l.id, l.user_id, l.latitude, l.longitude, l.accuracy, l.altitude,
           l.speed, l.heading, l.address, l.province, l.district,
           l.is_sharing, l.battery_level, l.created_at,
           u.first_name, u.last_name, u.phone, u.role
    FROM locations l
    INNER JOIN (
      SELECT user_id, MAX(created_at) as max_created_at
      FROM locations
      WHERE is_sharing = TRUE
      AND created_at >= DATE_SUB(NOW(), INTERVAL 1 HOUR)
      GROUP BY user_id
    ) latest ON l.user_id = latest.user_id AND l.created_at = latest.max_created_at
    INNER JOIN users u ON l.user_id = u.id
    INNER JOIN location_sharing_settings s ON l.user_id = s.user_id
    ${whereClause}
    AND s.is_enabled = TRUE
    ORDER BY l.created_at DESC
    LIMIT ?
  `;

  return db.query(sql, [...params, limit]);
};

/**
 * Find specific rider's latest location
 * @param {string} userId - User UUID
 * @returns {Promise<Object|null>}
 */
const findRiderLatestLocation = async (userId) => {
  const sql = `
    SELECT l.id, l.user_id, l.latitude, l.longitude, l.accuracy, l.altitude,
           l.speed, l.heading, l.address, l.province, l.district,
           l.is_sharing, l.battery_level, l.created_at,
           u.first_name, u.last_name, u.phone, u.role,
           s.is_enabled as sharing_enabled
    FROM locations l
    INNER JOIN users u ON l.user_id = u.id
    LEFT JOIN location_sharing_settings s ON l.user_id = s.user_id
    WHERE l.user_id = ?
    ORDER BY l.created_at DESC
    LIMIT 1
  `;
  return db.queryOne(sql, [userId]);
};

/**
 * Delete old location records (for cleanup)
 * @param {number} hoursOld - Delete records older than this many hours
 * @returns {Promise<{affectedRows: number}>}
 */
const deleteOldLocations = async (hoursOld = 24) => {
  const sql = `
    DELETE FROM locations
    WHERE created_at < DATE_SUB(NOW(), INTERVAL ? HOUR)
  `;
  return db.remove(sql, [hoursOld]);
};

// ==================== Location Sharing Settings ====================

/**
 * Find sharing settings by user ID
 * @param {string} userId - User UUID
 * @returns {Promise<Object|null>}
 */
const findSettingsByUserId = async (userId) => {
  const sql = `
    SELECT id, user_id, is_enabled, share_with_police, share_with_volunteers,
           share_in_emergency, auto_share_on_incident, updated_at
    FROM location_sharing_settings
    WHERE user_id = ?
  `;
  return db.queryOne(sql, [userId]);
};

/**
 * Create sharing settings for a user
 * @param {string} userId - User UUID
 * @param {Object} data - Settings data
 * @returns {Promise<Object>}
 */
const createSettings = async (userId, data = {}) => {
  const id = uuidv4();

  const sql = `
    INSERT INTO location_sharing_settings (
      id, user_id, is_enabled, share_with_police, share_with_volunteers,
      share_in_emergency, auto_share_on_incident
    ) VALUES (?, ?, ?, ?, ?, ?, ?)
  `;

  await db.query(sql, [
    id,
    userId,
    data.isEnabled || false,
    data.shareWithPolice !== false, // default true
    data.shareWithVolunteers !== false, // default true
    data.shareInEmergency !== false, // default true
    data.autoShareOnIncident !== false, // default true
  ]);

  return findSettingsByUserId(userId);
};

/**
 * Update sharing settings
 * @param {string} userId - User UUID
 * @param {Object} updates - Settings to update
 * @returns {Promise<Object>}
 */
const updateSettings = async (userId, updates) => {
  const allowedFields = [
    'is_enabled', 'share_with_police', 'share_with_volunteers',
    'share_in_emergency', 'auto_share_on_incident',
  ];

  // Map camelCase to snake_case
  const fieldMapping = {
    isEnabled: 'is_enabled',
    shareWithPolice: 'share_with_police',
    shareWithVolunteers: 'share_with_volunteers',
    shareInEmergency: 'share_in_emergency',
    autoShareOnIncident: 'auto_share_on_incident',
  };

  const updatePairs = [];
  const values = [];

  for (const [key, value] of Object.entries(updates)) {
    const dbKey = fieldMapping[key] || key;
    if (allowedFields.includes(dbKey)) {
      updatePairs.push(`${dbKey} = ?`);
      values.push(value);
    }
  }

  if (updatePairs.length === 0) {
    return findSettingsByUserId(userId);
  }

  values.push(userId);

  const sql = `
    UPDATE location_sharing_settings
    SET ${updatePairs.join(', ')}
    WHERE user_id = ?
  `;

  await db.update(sql, values);
  return findSettingsByUserId(userId);
};

/**
 * Get or create settings for a user
 * @param {string} userId - User UUID
 * @returns {Promise<Object>}
 */
const getOrCreateSettings = async (userId) => {
  let settings = await findSettingsByUserId(userId);
  if (!settings) {
    settings = await createSettings(userId);
  }
  return settings;
};

/**
 * Set sharing status (start/stop sharing)
 * @param {string} userId - User UUID
 * @param {boolean} isEnabled - Enable/disable sharing
 * @returns {Promise<Object>}
 */
const setSharing = async (userId, isEnabled) => {
  // Ensure settings exist
  await getOrCreateSettings(userId);

  // Update the is_enabled setting
  return updateSettings(userId, { isEnabled });
};

/**
 * Check if user is currently sharing
 * @param {string} userId - User UUID
 * @returns {Promise<boolean>}
 */
const isUserSharing = async (userId) => {
  const settings = await findSettingsByUserId(userId);
  return settings ? Boolean(settings.is_enabled) : false;
};

/**
 * Get count of sharing riders
 * @returns {Promise<number>}
 */
const getSharingRidersCount = async () => {
  const sql = `
    SELECT COUNT(DISTINCT l.user_id) as count
    FROM locations l
    INNER JOIN location_sharing_settings s ON l.user_id = s.user_id
    WHERE l.is_sharing = TRUE
    AND s.is_enabled = TRUE
    AND l.created_at >= DATE_SUB(NOW(), INTERVAL 1 HOUR)
  `;
  const result = await db.queryOne(sql);
  return result ? Number(result.count) : 0;
};

module.exports = {
  // Location Records
  createLocation,
  findLocationById,
  findLatestLocationByUserId,
  findLocationHistoryByUserId,
  findSharingRidersLocations,
  findRiderLatestLocation,
  deleteOldLocations,
  // Sharing Settings
  findSettingsByUserId,
  createSettings,
  updateSettings,
  getOrCreateSettings,
  setSharing,
  isUserSharing,
  getSharingRidersCount,
};
