'use strict';

const db = require('../../config/database');
const { v4: uuidv4 } = require('uuid');

/**
 * Incidents Repository - Database operations for incident management
 */

/**
 * Find all incidents with pagination and filtering
 * @param {Object} options - Query options
 * @returns {Promise<{incidents: Array, total: number}>}
 */
const findAll = async (options = {}) => {
  const {
    page = 1,
    limit = 10,
    search = '',
    category = '',
    status = '',
    priority = '',
    province = '',
    assignedTo = '',
    reportedBy = '',
    dateFrom = '',
    dateTo = '',
    sortBy = 'created_at',
    sortOrder = 'DESC',
  } = options;

  const offset = (page - 1) * limit;

  // Build WHERE clause
  const conditions = [];
  const params = [];

  if (search) {
    conditions.push('(i.title LIKE ? OR i.description LIKE ? OR i.location_address LIKE ?)');
    const searchTerm = `%${search}%`;
    params.push(searchTerm, searchTerm, searchTerm);
  }

  if (category) {
    conditions.push('i.category = ?');
    params.push(category);
  }

  if (status) {
    conditions.push('i.status = ?');
    params.push(status);
  }

  if (priority) {
    conditions.push('i.priority = ?');
    params.push(priority);
  }

  if (province) {
    conditions.push('i.location_province = ?');
    params.push(province);
  }

  if (assignedTo) {
    conditions.push('i.assigned_to = ?');
    params.push(assignedTo);
  }

  if (reportedBy) {
    conditions.push('i.reported_by = ?');
    params.push(reportedBy);
  }

  if (dateFrom) {
    conditions.push('i.created_at >= ?');
    params.push(dateFrom);
  }

  if (dateTo) {
    conditions.push('i.created_at <= ?');
    params.push(dateTo);
  }

  const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

  // Validate sort column
  const allowedSortColumns = [
    'created_at', 'updated_at', 'title', 'category', 'status',
    'priority', 'incident_date', 'view_count'
  ];
  const safeSortBy = allowedSortColumns.includes(sortBy) ? sortBy : 'created_at';
  const safeSortOrder = sortOrder.toUpperCase() === 'ASC' ? 'ASC' : 'DESC';

  // Get total count
  const countSql = `SELECT COUNT(*) as total FROM incidents i ${whereClause}`;
  const countResult = await db.queryOne(countSql, params);
  const total = countResult ? Number(countResult.total) : 0;

  // Get incidents with reporter and assignee info
  const sql = `
    SELECT
      i.id, i.reported_by, i.category, i.status, i.priority,
      i.title, i.description, i.location_lat, i.location_lng,
      i.location_address, i.location_province, i.location_district,
      i.incident_date, i.assigned_to, i.assigned_at,
      i.reviewed_by, i.reviewed_at, i.review_notes,
      i.resolved_by, i.resolved_at, i.resolution_notes,
      i.is_anonymous, i.view_count, i.created_at, i.updated_at,
      reporter.full_name as reporter_name, reporter.phone as reporter_phone,
      assignee.full_name as assignee_name, assignee.phone as assignee_phone
    FROM incidents i
    LEFT JOIN users reporter ON i.reported_by = reporter.id
    LEFT JOIN users assignee ON i.assigned_to = assignee.id
    ${whereClause}
    ORDER BY i.${safeSortBy} ${safeSortOrder}
    LIMIT ? OFFSET ?
  `;

  const incidents = await db.query(sql, [...params, limit, offset]);

  return { incidents, total };
};

/**
 * Find incidents by user (reporter)
 * @param {string} userId - User UUID
 * @param {Object} options - Query options
 * @returns {Promise<{incidents: Array, total: number}>}
 */
const findByUser = async (userId, options = {}) => {
  const {
    page = 1,
    limit = 10,
    search = '',
    category = '',
    status = '',
    priority = '',
    sortBy = 'created_at',
    sortOrder = 'DESC',
  } = options;

  const offset = (page - 1) * limit;

  // Build WHERE clause
  const conditions = ['i.reported_by = ?'];
  const params = [userId];

  if (search) {
    conditions.push('(i.title LIKE ? OR i.description LIKE ?)');
    const searchTerm = `%${search}%`;
    params.push(searchTerm, searchTerm);
  }

  if (category) {
    conditions.push('i.category = ?');
    params.push(category);
  }

  if (status) {
    conditions.push('i.status = ?');
    params.push(status);
  }

  if (priority) {
    conditions.push('i.priority = ?');
    params.push(priority);
  }

  const whereClause = `WHERE ${conditions.join(' AND ')}`;

  // Validate sort column
  const allowedSortColumns = ['created_at', 'updated_at', 'title', 'category', 'status', 'priority'];
  const safeSortBy = allowedSortColumns.includes(sortBy) ? sortBy : 'created_at';
  const safeSortOrder = sortOrder.toUpperCase() === 'ASC' ? 'ASC' : 'DESC';

  // Get total count
  const countSql = `SELECT COUNT(*) as total FROM incidents i ${whereClause}`;
  const countResult = await db.queryOne(countSql, params);
  const total = countResult ? Number(countResult.total) : 0;

  // Get incidents
  const sql = `
    SELECT
      i.id, i.reported_by, i.category, i.status, i.priority,
      i.title, i.description, i.location_lat, i.location_lng,
      i.location_address, i.location_province, i.location_district,
      i.incident_date, i.assigned_to, i.assigned_at,
      i.reviewed_by, i.reviewed_at, i.review_notes,
      i.resolved_by, i.resolved_at, i.resolution_notes,
      i.is_anonymous, i.view_count, i.created_at, i.updated_at,
      assignee.full_name as assignee_name, assignee.phone as assignee_phone
    FROM incidents i
    LEFT JOIN users assignee ON i.assigned_to = assignee.id
    ${whereClause}
    ORDER BY i.${safeSortBy} ${safeSortOrder}
    LIMIT ? OFFSET ?
  `;

  const incidents = await db.query(sql, [...params, limit, offset]);

  return { incidents, total };
};

/**
 * Find incident by ID
 * @param {string} id - Incident UUID
 * @returns {Promise<Object|null>}
 */
const findById = async (id) => {
  const sql = `
    SELECT
      i.id, i.reported_by, i.category, i.status, i.priority,
      i.title, i.description, i.location_lat, i.location_lng,
      i.location_address, i.location_province, i.location_district,
      i.incident_date, i.assigned_to, i.assigned_at,
      i.reviewed_by, i.reviewed_at, i.review_notes,
      i.resolved_by, i.resolved_at, i.resolution_notes,
      i.is_anonymous, i.view_count, i.created_at, i.updated_at
    FROM incidents i
    WHERE i.id = ?
  `;
  return db.queryOne(sql, [id]);
};

/**
 * Find incident by ID with full details (reporter, assignee, reviewer, resolver)
 * @param {string} id - Incident UUID
 * @returns {Promise<Object|null>}
 */
const findByIdWithDetails = async (id) => {
  const sql = `
    SELECT
      i.id, i.reported_by, i.category, i.status, i.priority,
      i.title, i.description, i.location_lat, i.location_lng,
      i.location_address, i.location_province, i.location_district,
      i.incident_date, i.assigned_to, i.assigned_at,
      i.reviewed_by, i.reviewed_at, i.review_notes,
      i.resolved_by, i.resolved_at, i.resolution_notes,
      i.is_anonymous, i.view_count, i.created_at, i.updated_at,
      reporter.full_name as reporter_name, reporter.phone as reporter_phone, reporter.role as reporter_role,
      assignee.full_name as assignee_name, assignee.phone as assignee_phone, assignee.role as assignee_role,
      reviewer.full_name as reviewer_name, reviewer.role as reviewer_role,
      resolver.full_name as resolver_name, resolver.role as resolver_role
    FROM incidents i
    LEFT JOIN users reporter ON i.reported_by = reporter.id
    LEFT JOIN users assignee ON i.assigned_to = assignee.id
    LEFT JOIN users reviewer ON i.reviewed_by = reviewer.id
    LEFT JOIN users resolver ON i.resolved_by = resolver.id
    WHERE i.id = ?
  `;
  return db.queryOne(sql, [id]);
};

/**
 * Create a new incident
 * @param {Object} data - Incident data
 * @returns {Promise<Object>}
 */
const create = async (data) => {
  const id = uuidv4();
  const {
    reportedBy,
    category = 'general',
    priority = 'medium',
    title,
    description,
    locationLat = null,
    locationLng = null,
    locationAddress = null,
    locationProvince = null,
    locationDistrict = null,
    incidentDate = null,
    isAnonymous = false,
  } = data;

  const sql = `
    INSERT INTO incidents (
      id, reported_by, category, priority, title, description,
      location_lat, location_lng, location_address, location_province, location_district,
      incident_date, is_anonymous, status, created_at, updated_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
  `;

  await db.insert(sql, [
    id, reportedBy, category, priority, title, description,
    locationLat, locationLng, locationAddress, locationProvince, locationDistrict,
    incidentDate, isAnonymous,
  ]);

  return findById(id);
};

/**
 * Update incident by ID
 * @param {string} id - Incident UUID
 * @param {Object} updates - Fields to update
 * @returns {Promise<Object>}
 */
const update = async (id, updates) => {
  const allowedFields = [
    'category', 'priority', 'title', 'description',
    'location_lat', 'location_lng', 'location_address',
    'location_province', 'location_district', 'incident_date',
    'is_anonymous',
  ];

  const updatePairs = [];
  const values = [];

  for (const [key, value] of Object.entries(updates)) {
    // Convert camelCase to snake_case
    const dbKey = key.replace(/([A-Z])/g, '_$1').toLowerCase();
    if (allowedFields.includes(dbKey)) {
      updatePairs.push(`${dbKey} = ?`);
      values.push(value);
    }
  }

  if (updatePairs.length === 0) {
    return findById(id);
  }

  values.push(id);

  const sql = `
    UPDATE incidents
    SET ${updatePairs.join(', ')}, updated_at = CURRENT_TIMESTAMP
    WHERE id = ?
  `;

  await db.update(sql, values);
  return findById(id);
};

/**
 * Update incident status
 * @param {string} id - Incident UUID
 * @param {string} status - New status
 * @param {string} userId - User making the change
 * @param {string} notes - Optional notes
 * @returns {Promise<Object>}
 */
const updateStatus = async (id, status, userId, notes = null) => {
  let sql;
  let params;

  switch (status) {
    case 'reviewing':
      sql = `
        UPDATE incidents
        SET status = ?, reviewed_by = ?, reviewed_at = CURRENT_TIMESTAMP, review_notes = ?, updated_at = CURRENT_TIMESTAMP
        WHERE id = ?
      `;
      params = [status, userId, notes, id];
      break;

    case 'verified':
      sql = `
        UPDATE incidents
        SET status = ?, reviewed_by = COALESCE(reviewed_by, ?), reviewed_at = COALESCE(reviewed_at, CURRENT_TIMESTAMP), review_notes = COALESCE(review_notes, ?), updated_at = CURRENT_TIMESTAMP
        WHERE id = ?
      `;
      params = [status, userId, notes, id];
      break;

    case 'resolved':
      sql = `
        UPDATE incidents
        SET status = ?, resolved_by = ?, resolved_at = CURRENT_TIMESTAMP, resolution_notes = ?, updated_at = CURRENT_TIMESTAMP
        WHERE id = ?
      `;
      params = [status, userId, notes, id];
      break;

    case 'rejected':
      sql = `
        UPDATE incidents
        SET status = ?, reviewed_by = ?, reviewed_at = CURRENT_TIMESTAMP, review_notes = ?, updated_at = CURRENT_TIMESTAMP
        WHERE id = ?
      `;
      params = [status, userId, notes, id];
      break;

    default:
      sql = `
        UPDATE incidents
        SET status = ?, updated_at = CURRENT_TIMESTAMP
        WHERE id = ?
      `;
      params = [status, id];
  }

  await db.update(sql, params);
  return findById(id);
};

/**
 * Assign incident to a user
 * @param {string} id - Incident UUID
 * @param {string} assigneeId - Assignee user UUID
 * @returns {Promise<Object>}
 */
const assign = async (id, assigneeId) => {
  const sql = `
    UPDATE incidents
    SET assigned_to = ?, assigned_at = CURRENT_TIMESTAMP, updated_at = CURRENT_TIMESTAMP
    WHERE id = ?
  `;
  await db.update(sql, [assigneeId, id]);
  return findById(id);
};

/**
 * Unassign incident
 * @param {string} id - Incident UUID
 * @returns {Promise<Object>}
 */
const unassign = async (id) => {
  const sql = `
    UPDATE incidents
    SET assigned_to = NULL, assigned_at = NULL, updated_at = CURRENT_TIMESTAMP
    WHERE id = ?
  `;
  await db.update(sql, [id]);
  return findById(id);
};

/**
 * Increment view count
 * @param {string} id - Incident UUID
 * @returns {Promise<void>}
 */
const incrementViewCount = async (id) => {
  const sql = `
    UPDATE incidents
    SET view_count = view_count + 1
    WHERE id = ?
  `;
  await db.update(sql, [id]);
};

/**
 * Delete incident (hard delete)
 * @param {string} id - Incident UUID
 * @returns {Promise<{affectedRows: number}>}
 */
const remove = async (id) => {
  const sql = 'DELETE FROM incidents WHERE id = ?';
  return db.remove(sql, [id]);
};

/**
 * Get incident statistics
 * @returns {Promise<Object>}
 */
const getStats = async () => {
  const [byCategory, byStatus, byPriority, byProvince, recentCount] = await Promise.all([
    // By category
    db.query(`
      SELECT category, COUNT(*) as count
      FROM incidents
      GROUP BY category
    `),
    // By status
    db.query(`
      SELECT status, COUNT(*) as count
      FROM incidents
      GROUP BY status
    `),
    // By priority
    db.query(`
      SELECT priority, COUNT(*) as count
      FROM incidents
      GROUP BY priority
    `),
    // Top provinces
    db.query(`
      SELECT location_province, COUNT(*) as count
      FROM incidents
      WHERE location_province IS NOT NULL
      GROUP BY location_province
      ORDER BY count DESC
      LIMIT 10
    `),
    // Recent (last 24 hours, 7 days, 30 days)
    db.queryOne(`
      SELECT
        SUM(CASE WHEN created_at >= DATE_SUB(NOW(), INTERVAL 24 HOUR) THEN 1 ELSE 0 END) as last_24h,
        SUM(CASE WHEN created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY) THEN 1 ELSE 0 END) as last_7d,
        SUM(CASE WHEN created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY) THEN 1 ELSE 0 END) as last_30d,
        COUNT(*) as total
      FROM incidents
    `),
  ]);

  return {
    byCategory: byCategory.reduce((acc, row) => {
      acc[row.category] = Number(row.count);
      return acc;
    }, {}),
    byStatus: byStatus.reduce((acc, row) => {
      acc[row.status] = Number(row.count);
      return acc;
    }, {}),
    byPriority: byPriority.reduce((acc, row) => {
      acc[row.priority] = Number(row.count);
      return acc;
    }, {}),
    topProvinces: byProvince.map(row => ({
      province: row.location_province,
      count: Number(row.count),
    })),
    recentCount: {
      last24h: Number(recentCount?.last_24h || 0),
      last7d: Number(recentCount?.last_7d || 0),
      last30d: Number(recentCount?.last_30d || 0),
      total: Number(recentCount?.total || 0),
    },
  };
};

// ============= Attachment Repository Functions =============

/**
 * Find attachments by incident ID
 * @param {string} incidentId - Incident UUID
 * @returns {Promise<Array>}
 */
const findAttachmentsByIncidentId = async (incidentId) => {
  const sql = `
    SELECT
      id, incident_id, file_name, file_path, file_url, file_type,
      mime_type, file_size, width, height, duration, thumbnail_url,
      description, sort_order, is_primary, uploaded_by, created_at, updated_at
    FROM incident_attachments
    WHERE incident_id = ?
    ORDER BY sort_order ASC, created_at ASC
  `;
  return db.query(sql, [incidentId]);
};

/**
 * Find attachment by ID
 * @param {string} id - Attachment UUID
 * @returns {Promise<Object|null>}
 */
const findAttachmentById = async (id) => {
  const sql = `
    SELECT
      id, incident_id, file_name, file_path, file_url, file_type,
      mime_type, file_size, width, height, duration, thumbnail_url,
      description, sort_order, is_primary, uploaded_by, created_at, updated_at
    FROM incident_attachments
    WHERE id = ?
  `;
  return db.queryOne(sql, [id]);
};

/**
 * Create attachment
 * @param {Object} data - Attachment data
 * @returns {Promise<Object>}
 */
const createAttachment = async (data) => {
  const id = uuidv4();
  const {
    incidentId,
    fileName,
    filePath,
    fileUrl,
    fileType,
    mimeType,
    fileSize,
    width = null,
    height = null,
    duration = null,
    thumbnailUrl = null,
    description = null,
    sortOrder = 0,
    isPrimary = false,
    uploadedBy,
  } = data;

  const sql = `
    INSERT INTO incident_attachments (
      id, incident_id, file_name, file_path, file_url, file_type,
      mime_type, file_size, width, height, duration, thumbnail_url,
      description, sort_order, is_primary, uploaded_by, created_at, updated_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
  `;

  await db.insert(sql, [
    id, incidentId, fileName, filePath, fileUrl, fileType,
    mimeType, fileSize, width, height, duration, thumbnailUrl,
    description, sortOrder, isPrimary, uploadedBy,
  ]);

  return findAttachmentById(id);
};

/**
 * Delete attachment
 * @param {string} id - Attachment UUID
 * @returns {Promise<{affectedRows: number}>}
 */
const removeAttachment = async (id) => {
  const sql = 'DELETE FROM incident_attachments WHERE id = ?';
  return db.remove(sql, [id]);
};

/**
 * Delete all attachments for an incident
 * @param {string} incidentId - Incident UUID
 * @returns {Promise<{affectedRows: number}>}
 */
const removeAttachmentsByIncidentId = async (incidentId) => {
  const sql = 'DELETE FROM incident_attachments WHERE incident_id = ?';
  return db.remove(sql, [incidentId]);
};

/**
 * Count attachments for an incident
 * @param {string} incidentId - Incident UUID
 * @returns {Promise<number>}
 */
const countAttachmentsByIncidentId = async (incidentId) => {
  const result = await db.queryOne(
    'SELECT COUNT(*) as count FROM incident_attachments WHERE incident_id = ?',
    [incidentId]
  );
  return Number(result?.count || 0);
};

module.exports = {
  // Incident operations
  findAll,
  findByUser,
  findById,
  findByIdWithDetails,
  create,
  update,
  updateStatus,
  assign,
  unassign,
  incrementViewCount,
  remove,
  getStats,
  // Attachment operations
  findAttachmentsByIncidentId,
  findAttachmentById,
  createAttachment,
  removeAttachment,
  removeAttachmentsByIncidentId,
  countAttachmentsByIncidentId,
};
