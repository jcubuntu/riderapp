'use strict';

const db = require('../../config/database');
const { v4: uuidv4 } = require('uuid');

/**
 * Emergency Repository - Database operations for emergency contacts and SOS
 */

// In-memory store for active SOS alerts (consider moving to Redis/DB for production)
const activeSosAlerts = new Map();

// ==================== Emergency Contacts ====================

/**
 * Find all emergency contacts with pagination and filtering
 * @param {Object} options - Query options
 * @returns {Promise<{contacts: Array, total: number}>}
 */
const findAllContacts = async (options = {}) => {
  const {
    page = 1,
    limit = 20,
    search = '',
    category = '',
    province = '',
    isActive = null,
    isNationwide = null,
    is24Hours = null,
    sortBy = 'priority',
    sortOrder = 'DESC',
  } = options;

  const offset = (page - 1) * limit;

  // Build WHERE clause
  const conditions = [];
  const params = [];

  if (search) {
    conditions.push('(name LIKE ? OR phone LIKE ? OR description LIKE ?)');
    const searchTerm = `%${search}%`;
    params.push(searchTerm, searchTerm, searchTerm);
  }

  if (category) {
    conditions.push('category = ?');
    params.push(category);
  }

  if (province) {
    conditions.push('province = ?');
    params.push(province);
  }

  if (isActive !== null) {
    conditions.push('is_active = ?');
    params.push(isActive);
  }

  if (isNationwide !== null) {
    conditions.push('is_nationwide = ?');
    params.push(isNationwide);
  }

  if (is24Hours !== null) {
    conditions.push('is_24_hours = ?');
    params.push(is24Hours);
  }

  const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

  // Validate sort column
  const allowedSortColumns = ['priority', 'name', 'category', 'created_at', 'updated_at'];
  const safeSortBy = allowedSortColumns.includes(sortBy) ? sortBy : 'priority';
  const safeSortOrder = sortOrder.toUpperCase() === 'ASC' ? 'ASC' : 'DESC';

  // Get total count
  const countSql = `SELECT COUNT(*) as total FROM emergency_contacts ${whereClause}`;
  const countResult = await db.queryOne(countSql, params);
  const total = countResult ? Number(countResult.total) : 0;

  // Get contacts
  const sql = `
    SELECT id, name, phone, phone_secondary, email, category,
           description, address, province, district,
           location_lat, location_lng, operating_hours, is_24_hours,
           is_active, is_nationwide, priority, icon_url,
           created_by, updated_by, created_at, updated_at
    FROM emergency_contacts
    ${whereClause}
    ORDER BY ${safeSortBy} ${safeSortOrder}, name ASC
    LIMIT ? OFFSET ?
  `;

  const contacts = await db.query(sql, [...params, limit, offset]);

  return { contacts, total };
};

/**
 * Find active emergency contacts for public display
 * @param {Object} options - Query options
 * @returns {Promise<Array>}
 */
const findActiveContacts = async (options = {}) => {
  const { category = '', province = '', limit = 50 } = options;

  const conditions = ['is_active = TRUE'];
  const params = [];

  if (category) {
    conditions.push('category = ?');
    params.push(category);
  }

  // If province specified, get both provincial and nationwide contacts
  if (province) {
    conditions.push('(province = ? OR is_nationwide = TRUE)');
    params.push(province);
  }

  const whereClause = `WHERE ${conditions.join(' AND ')}`;

  const sql = `
    SELECT id, name, phone, phone_secondary, category,
           description, address, province, district,
           location_lat, location_lng, operating_hours, is_24_hours,
           is_nationwide, priority, icon_url
    FROM emergency_contacts
    ${whereClause}
    ORDER BY priority DESC, name ASC
    LIMIT ?
  `;

  return db.query(sql, [...params, limit]);
};

/**
 * Find emergency contact by ID
 * @param {string} id - Contact UUID
 * @returns {Promise<Object|null>}
 */
const findContactById = async (id) => {
  const sql = `
    SELECT id, name, phone, phone_secondary, email, category,
           description, address, province, district,
           location_lat, location_lng, operating_hours, is_24_hours,
           is_active, is_nationwide, priority, icon_url,
           created_by, updated_by, created_at, updated_at
    FROM emergency_contacts
    WHERE id = ?
  `;
  return db.queryOne(sql, [id]);
};

/**
 * Create a new emergency contact
 * @param {Object} data - Contact data
 * @param {string} createdBy - User ID who created the contact
 * @returns {Promise<Object>}
 */
const createContact = async (data, createdBy) => {
  const id = uuidv4();

  const sql = `
    INSERT INTO emergency_contacts (
      id, name, phone, phone_secondary, email, category,
      description, address, province, district,
      location_lat, location_lng, operating_hours, is_24_hours,
      is_active, is_nationwide, priority, icon_url, created_by
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `;

  await db.query(sql, [
    id,
    data.name,
    data.phone,
    data.phoneSecondary || null,
    data.email || null,
    data.category || 'other',
    data.description || null,
    data.address || null,
    data.province || null,
    data.district || null,
    data.locationLat || null,
    data.locationLng || null,
    data.operatingHours || null,
    data.is24Hours || false,
    data.isActive !== false, // default true
    data.isNationwide || false,
    data.priority || 0,
    data.iconUrl || null,
    createdBy,
  ]);

  return findContactById(id);
};

/**
 * Update an emergency contact
 * @param {string} id - Contact UUID
 * @param {Object} updates - Fields to update
 * @param {string} updatedBy - User ID who updated the contact
 * @returns {Promise<Object>}
 */
const updateContact = async (id, updates, updatedBy) => {
  const allowedFields = [
    'name', 'phone', 'phone_secondary', 'email', 'category',
    'description', 'address', 'province', 'district',
    'location_lat', 'location_lng', 'operating_hours', 'is_24_hours',
    'is_active', 'is_nationwide', 'priority', 'icon_url',
  ];

  // Map camelCase to snake_case
  const fieldMapping = {
    phoneSecondary: 'phone_secondary',
    locationLat: 'location_lat',
    locationLng: 'location_lng',
    operatingHours: 'operating_hours',
    is24Hours: 'is_24_hours',
    isActive: 'is_active',
    isNationwide: 'is_nationwide',
    iconUrl: 'icon_url',
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
    return findContactById(id);
  }

  // Add updated_by
  updatePairs.push('updated_by = ?');
  values.push(updatedBy);

  values.push(id);

  const sql = `
    UPDATE emergency_contacts
    SET ${updatePairs.join(', ')}, updated_at = CURRENT_TIMESTAMP
    WHERE id = ?
  `;

  await db.update(sql, values);
  return findContactById(id);
};

/**
 * Delete an emergency contact
 * @param {string} id - Contact UUID
 * @returns {Promise<{affectedRows: number}>}
 */
const deleteContact = async (id) => {
  const sql = 'DELETE FROM emergency_contacts WHERE id = ?';
  return db.remove(sql, [id]);
};

/**
 * Get emergency contact counts by category
 * @returns {Promise<Object>}
 */
const getContactCountByCategory = async () => {
  const sql = `
    SELECT category, COUNT(*) as count
    FROM emergency_contacts
    WHERE is_active = TRUE
    GROUP BY category
  `;
  const results = await db.query(sql);

  const counts = {
    police: 0,
    hospital: 0,
    fire: 0,
    rescue: 0,
    hotline: 0,
    government: 0,
    other: 0,
    total: 0,
  };

  results.forEach(row => {
    counts[row.category] = Number(row.count);
    counts.total += Number(row.count);
  });

  return counts;
};

// ==================== SOS Alerts ====================

/**
 * Create/trigger a new SOS alert
 * @param {Object} data - SOS data
 * @returns {Object} Created SOS alert
 */
const createSosAlert = (data) => {
  const { userId, latitude, longitude, message } = data;

  // Check if user already has an active SOS
  if (activeSosAlerts.has(userId)) {
    return activeSosAlerts.get(userId);
  }

  const alert = {
    id: uuidv4(),
    userId,
    latitude,
    longitude,
    message: message || null,
    triggeredAt: new Date().toISOString(),
    status: 'active',
  };

  activeSosAlerts.set(userId, alert);
  return alert;
};

/**
 * Get SOS alert by user ID
 * @param {string} userId - User UUID
 * @returns {Object|null}
 */
const getSosAlertByUserId = (userId) => {
  return activeSosAlerts.get(userId) || null;
};

/**
 * Get SOS alert by ID
 * @param {string} id - Alert UUID
 * @returns {Object|null}
 */
const getSosAlertById = (id) => {
  for (const alert of activeSosAlerts.values()) {
    if (alert.id === id) {
      return alert;
    }
  }
  return null;
};

/**
 * Cancel/deactivate SOS alert
 * @param {string} userId - User UUID
 * @returns {Object|null} Cancelled alert or null if not found
 */
const cancelSosAlert = (userId) => {
  const alert = activeSosAlerts.get(userId);
  if (alert) {
    alert.status = 'cancelled';
    alert.cancelledAt = new Date().toISOString();
    activeSosAlerts.delete(userId);
    return alert;
  }
  return null;
};

/**
 * Get all active SOS alerts
 * @returns {Array} Active alerts
 */
const getAllActiveSosAlerts = () => {
  return Array.from(activeSosAlerts.values()).filter(alert => alert.status === 'active');
};

/**
 * Update SOS alert location
 * @param {string} userId - User UUID
 * @param {number} latitude - New latitude
 * @param {number} longitude - New longitude
 * @returns {Object|null} Updated alert or null
 */
const updateSosAlertLocation = (userId, latitude, longitude) => {
  const alert = activeSosAlerts.get(userId);
  if (alert && alert.status === 'active') {
    alert.latitude = latitude;
    alert.longitude = longitude;
    alert.lastUpdatedAt = new Date().toISOString();
    return alert;
  }
  return null;
};

/**
 * Resolve SOS alert (by police/responder)
 * @param {string} alertId - Alert UUID
 * @param {string} resolvedBy - Resolver user ID
 * @param {string} notes - Resolution notes
 * @returns {Object|null}
 */
const resolveSosAlert = (alertId, resolvedBy, notes = null) => {
  for (const [userId, alert] of activeSosAlerts.entries()) {
    if (alert.id === alertId) {
      alert.status = 'resolved';
      alert.resolvedAt = new Date().toISOString();
      alert.resolvedBy = resolvedBy;
      alert.resolutionNotes = notes;
      activeSosAlerts.delete(userId);
      return alert;
    }
  }
  return null;
};

/**
 * Get SOS alert count (for stats)
 * @returns {Object}
 */
const getSosAlertStats = () => {
  const alerts = Array.from(activeSosAlerts.values());
  return {
    active: alerts.filter(a => a.status === 'active').length,
    total: alerts.length,
  };
};

module.exports = {
  // Emergency Contacts
  findAllContacts,
  findActiveContacts,
  findContactById,
  createContact,
  updateContact,
  deleteContact,
  getContactCountByCategory,
  // SOS Alerts
  createSosAlert,
  getSosAlertByUserId,
  getSosAlertById,
  cancelSosAlert,
  getAllActiveSosAlerts,
  updateSosAlertLocation,
  resolveSosAlert,
  getSosAlertStats,
};
