'use strict';

const db = require('../../config/database');

/**
 * Stats Repository - Database operations for statistics
 * Aggregates data from users and incidents tables
 */

// ============= Dashboard Statistics =============

/**
 * Get total user count
 * @returns {Promise<number>}
 */
const getTotalUsers = async () => {
  const sql = `SELECT COUNT(*) as count FROM users WHERE status != 'inactive'`;
  const result = await db.queryOne(sql);
  return result ? Number(result.count) : 0;
};

/**
 * Get total incident count
 * @param {Object} options - Filter options
 * @returns {Promise<number>}
 */
const getTotalIncidents = async (options = {}) => {
  const { startDate, endDate } = options;
  let sql = `SELECT COUNT(*) as count FROM incidents WHERE 1=1`;
  const params = [];

  if (startDate) {
    sql += ` AND created_at >= ?`;
    params.push(startDate);
  }
  if (endDate) {
    sql += ` AND created_at <= ?`;
    params.push(endDate);
  }

  const result = await db.queryOne(sql, params);
  return result ? Number(result.count) : 0;
};

/**
 * Get count of pending user approvals
 * @returns {Promise<number>}
 */
const getPendingApprovalsCount = async () => {
  const sql = `SELECT COUNT(*) as count FROM users WHERE status = 'pending'`;
  const result = await db.queryOne(sql);
  return result ? Number(result.count) : 0;
};

/**
 * Get count of active incidents (pending or reviewing)
 * @returns {Promise<number>}
 */
const getActiveIncidentsCount = async () => {
  const sql = `SELECT COUNT(*) as count FROM incidents WHERE status IN ('pending', 'reviewing')`;
  const result = await db.queryOne(sql);
  return result ? Number(result.count) : 0;
};

/**
 * Get count of incidents resolved today
 * @returns {Promise<number>}
 */
const getResolvedTodayCount = async () => {
  const sql = `
    SELECT COUNT(*) as count
    FROM incidents
    WHERE status = 'resolved'
    AND DATE(resolved_at) = CURDATE()
  `;
  const result = await db.queryOne(sql);
  return result ? Number(result.count) : 0;
};

/**
 * Get recent incidents
 * @param {number} limit - Number of incidents to return
 * @returns {Promise<Array>}
 */
const getRecentIncidents = async (limit = 5) => {
  const sql = `
    SELECT
      i.id, i.title, i.category, i.status, i.priority,
      i.location_address, i.location_province, i.location_district,
      i.is_anonymous, i.created_at, i.updated_at,
      u.id as reporter_id, u.full_name as reporter_name, u.role as reporter_role
    FROM incidents i
    LEFT JOIN users u ON i.reported_by = u.id
    ORDER BY i.created_at DESC
    LIMIT ?
  `;
  return db.query(sql, [limit]);
};

/**
 * Get recent users
 * @param {number} limit - Number of users to return
 * @returns {Promise<Array>}
 */
const getRecentUsers = async (limit = 5) => {
  const sql = `
    SELECT
      id, email, phone, full_name, role, status,
      profile_image_url, affiliation, created_at
    FROM users
    ORDER BY created_at DESC
    LIMIT ?
  `;
  return db.query(sql, [limit]);
};

// ============= User Statistics =============

/**
 * Get user count summary
 * @returns {Promise<Object>}
 */
const getUserSummary = async () => {
  const sql = `
    SELECT
      COUNT(*) as total,
      SUM(CASE WHEN status = 'pending' THEN 1 ELSE 0 END) as pending,
      SUM(CASE WHEN status = 'approved' THEN 1 ELSE 0 END) as approved,
      SUM(CASE WHEN status = 'rejected' THEN 1 ELSE 0 END) as rejected,
      SUM(CASE WHEN status = 'inactive' THEN 1 ELSE 0 END) as inactive
    FROM users
  `;
  const result = await db.queryOne(sql);

  return {
    total: Number(result?.total || 0),
    pending: Number(result?.pending || 0),
    approved: Number(result?.approved || 0),
    rejected: Number(result?.rejected || 0),
    inactive: Number(result?.inactive || 0),
  };
};

/**
 * Get users grouped by role
 * @param {Object} options - Filter options
 * @returns {Promise<Array>}
 */
const getUsersByRole = async (options = {}) => {
  const { status = 'approved' } = options;
  let sql = `
    SELECT role, COUNT(*) as count
    FROM users
  `;
  const params = [];

  if (status) {
    sql += ` WHERE status = ?`;
    params.push(status);
  }

  sql += ` GROUP BY role ORDER BY count DESC`;

  const results = await db.query(sql, params);

  // Ensure all roles are represented
  const roleMap = {
    rider: 0,
    volunteer: 0,
    police: 0,
    admin: 0,
    super_admin: 0,
  };

  results.forEach(row => {
    roleMap[row.role] = Number(row.count);
  });

  return Object.entries(roleMap).map(([role, count]) => ({
    role,
    count,
  }));
};

/**
 * Get users grouped by status
 * @returns {Promise<Array>}
 */
const getUsersByStatus = async () => {
  const sql = `
    SELECT status, COUNT(*) as count
    FROM users
    GROUP BY status
    ORDER BY count DESC
  `;
  const results = await db.query(sql);

  // Ensure all statuses are represented
  const statusMap = {
    pending: 0,
    approved: 0,
    rejected: 0,
    inactive: 0,
  };

  results.forEach(row => {
    statusMap[row.status] = Number(row.count);
  });

  return Object.entries(statusMap).map(([status, count]) => ({
    status,
    count,
  }));
};

/**
 * Get user registration trend over time
 * @param {Object} options - Filter options
 * @returns {Promise<Array>}
 */
const getUserRegistrationTrend = async (options = {}) => {
  const { startDate, endDate, interval = 'daily' } = options;

  let dateFormat;
  let groupBy;
  switch (interval) {
    case 'monthly':
      dateFormat = '%Y-%m';
      groupBy = "DATE_FORMAT(created_at, '%Y-%m')";
      break;
    case 'weekly':
      dateFormat = '%Y-%u';
      groupBy = "DATE_FORMAT(created_at, '%Y-%u')";
      break;
    case 'daily':
    default:
      dateFormat = '%Y-%m-%d';
      groupBy = 'DATE(created_at)';
      break;
  }

  let sql = `
    SELECT
      DATE_FORMAT(created_at, '${dateFormat}') as period,
      COUNT(*) as count
    FROM users
    WHERE 1=1
  `;
  const params = [];

  if (startDate) {
    sql += ` AND created_at >= ?`;
    params.push(startDate);
  }
  if (endDate) {
    sql += ` AND created_at <= ?`;
    params.push(endDate);
  }

  sql += ` GROUP BY ${groupBy} ORDER BY period ASC`;

  return db.query(sql, params);
};

// ============= Incident Statistics =============

/**
 * Get incident count summary
 * @param {Object} options - Filter options
 * @returns {Promise<Object>}
 */
const getIncidentSummary = async (options = {}) => {
  const { startDate, endDate } = options;

  let sql = `
    SELECT
      COUNT(*) as total,
      SUM(CASE WHEN status = 'pending' THEN 1 ELSE 0 END) as pending,
      SUM(CASE WHEN status = 'reviewing' THEN 1 ELSE 0 END) as reviewing,
      SUM(CASE WHEN status = 'verified' THEN 1 ELSE 0 END) as verified,
      SUM(CASE WHEN status = 'resolved' THEN 1 ELSE 0 END) as resolved,
      SUM(CASE WHEN status = 'rejected' THEN 1 ELSE 0 END) as rejected
    FROM incidents
    WHERE 1=1
  `;
  const params = [];

  if (startDate) {
    sql += ` AND created_at >= ?`;
    params.push(startDate);
  }
  if (endDate) {
    sql += ` AND created_at <= ?`;
    params.push(endDate);
  }

  const result = await db.queryOne(sql, params);

  return {
    total: Number(result?.total || 0),
    pending: Number(result?.pending || 0),
    reviewing: Number(result?.reviewing || 0),
    verified: Number(result?.verified || 0),
    resolved: Number(result?.resolved || 0),
    rejected: Number(result?.rejected || 0),
  };
};

/**
 * Get incidents grouped by type (category)
 * @param {Object} options - Filter options
 * @returns {Promise<Array>}
 */
const getIncidentsByType = async (options = {}) => {
  const { startDate, endDate } = options;

  let sql = `
    SELECT category as type, COUNT(*) as count
    FROM incidents
    WHERE 1=1
  `;
  const params = [];

  if (startDate) {
    sql += ` AND created_at >= ?`;
    params.push(startDate);
  }
  if (endDate) {
    sql += ` AND created_at <= ?`;
    params.push(endDate);
  }

  sql += ` GROUP BY category ORDER BY count DESC`;

  const results = await db.query(sql, params);

  // Ensure all categories are represented
  const categoryMap = {
    intelligence: 0,
    accident: 0,
    general: 0,
  };

  results.forEach(row => {
    categoryMap[row.type] = Number(row.count);
  });

  return Object.entries(categoryMap).map(([type, count]) => ({
    type,
    count,
  }));
};

/**
 * Get incidents grouped by status
 * @param {Object} options - Filter options
 * @returns {Promise<Array>}
 */
const getIncidentsByStatus = async (options = {}) => {
  const { startDate, endDate } = options;

  let sql = `
    SELECT status, COUNT(*) as count
    FROM incidents
    WHERE 1=1
  `;
  const params = [];

  if (startDate) {
    sql += ` AND created_at >= ?`;
    params.push(startDate);
  }
  if (endDate) {
    sql += ` AND created_at <= ?`;
    params.push(endDate);
  }

  sql += ` GROUP BY status ORDER BY count DESC`;

  const results = await db.query(sql, params);

  // Ensure all statuses are represented
  const statusMap = {
    pending: 0,
    reviewing: 0,
    verified: 0,
    resolved: 0,
    rejected: 0,
  };

  results.forEach(row => {
    statusMap[row.status] = Number(row.count);
  });

  return Object.entries(statusMap).map(([status, count]) => ({
    status,
    count,
  }));
};

/**
 * Get incidents grouped by priority
 * @param {Object} options - Filter options
 * @returns {Promise<Array>}
 */
const getIncidentsByPriority = async (options = {}) => {
  const { startDate, endDate } = options;

  let sql = `
    SELECT priority, COUNT(*) as count
    FROM incidents
    WHERE 1=1
  `;
  const params = [];

  if (startDate) {
    sql += ` AND created_at >= ?`;
    params.push(startDate);
  }
  if (endDate) {
    sql += ` AND created_at <= ?`;
    params.push(endDate);
  }

  sql += ` GROUP BY priority ORDER BY count DESC`;

  const results = await db.query(sql, params);

  // Ensure all priorities are represented
  const priorityMap = {
    low: 0,
    medium: 0,
    high: 0,
    critical: 0,
  };

  results.forEach(row => {
    priorityMap[row.priority] = Number(row.count);
  });

  return Object.entries(priorityMap).map(([priority, count]) => ({
    priority,
    count,
  }));
};

/**
 * Get incident trend over time
 * @param {Object} options - Filter options
 * @returns {Promise<Array>}
 */
const getIncidentTrend = async (options = {}) => {
  const { startDate, endDate, interval = 'daily' } = options;

  let dateFormat;
  let groupBy;
  switch (interval) {
    case 'monthly':
      dateFormat = '%Y-%m';
      groupBy = "DATE_FORMAT(created_at, '%Y-%m')";
      break;
    case 'weekly':
      dateFormat = '%Y-%u';
      groupBy = "DATE_FORMAT(created_at, '%Y-%u')";
      break;
    case 'daily':
    default:
      dateFormat = '%Y-%m-%d';
      groupBy = 'DATE(created_at)';
      break;
  }

  let sql = `
    SELECT
      DATE_FORMAT(created_at, '${dateFormat}') as period,
      COUNT(*) as count,
      SUM(CASE WHEN status = 'resolved' THEN 1 ELSE 0 END) as resolved
    FROM incidents
    WHERE 1=1
  `;
  const params = [];

  if (startDate) {
    sql += ` AND created_at >= ?`;
    params.push(startDate);
  }
  if (endDate) {
    sql += ` AND created_at <= ?`;
    params.push(endDate);
  }

  sql += ` GROUP BY ${groupBy} ORDER BY period ASC`;

  const results = await db.query(sql, params);

  return results.map(row => ({
    period: row.period,
    count: Number(row.count),
    resolved: Number(row.resolved),
  }));
};

/**
 * Get incidents by province (top locations)
 * @param {Object} options - Filter options
 * @returns {Promise<Array>}
 */
const getIncidentsByProvince = async (options = {}) => {
  const { startDate, endDate, limit = 10 } = options;

  let sql = `
    SELECT
      COALESCE(location_province, 'Unknown') as province,
      COUNT(*) as count
    FROM incidents
    WHERE 1=1
  `;
  const params = [];

  if (startDate) {
    sql += ` AND created_at >= ?`;
    params.push(startDate);
  }
  if (endDate) {
    sql += ` AND created_at <= ?`;
    params.push(endDate);
  }

  sql += ` GROUP BY location_province ORDER BY count DESC LIMIT ?`;
  params.push(limit);

  return db.query(sql, params);
};

/**
 * Get average resolution time (in hours)
 * @param {Object} options - Filter options
 * @returns {Promise<number>}
 */
const getAverageResolutionTime = async (options = {}) => {
  const { startDate, endDate } = options;

  let sql = `
    SELECT AVG(TIMESTAMPDIFF(HOUR, created_at, resolved_at)) as avg_hours
    FROM incidents
    WHERE status = 'resolved' AND resolved_at IS NOT NULL
  `;
  const params = [];

  if (startDate) {
    sql += ` AND created_at >= ?`;
    params.push(startDate);
  }
  if (endDate) {
    sql += ` AND created_at <= ?`;
    params.push(endDate);
  }

  const result = await db.queryOne(sql, params);
  return result?.avg_hours ? Math.round(Number(result.avg_hours) * 10) / 10 : 0;
};

module.exports = {
  // Dashboard
  getTotalUsers,
  getTotalIncidents,
  getPendingApprovalsCount,
  getActiveIncidentsCount,
  getResolvedTodayCount,
  getRecentIncidents,
  getRecentUsers,
  // Users
  getUserSummary,
  getUsersByRole,
  getUsersByStatus,
  getUserRegistrationTrend,
  // Incidents
  getIncidentSummary,
  getIncidentsByType,
  getIncidentsByStatus,
  getIncidentsByPriority,
  getIncidentTrend,
  getIncidentsByProvince,
  getAverageResolutionTime,
};
