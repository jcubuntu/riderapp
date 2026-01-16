'use strict';

const db = require('../../config/database');

/**
 * Users Repository - Database operations for user management
 */

/**
 * Find all users with pagination and filtering
 * @param {Object} options - Query options
 * @returns {Promise<{users: Array, total: number}>}
 */
const findAll = async (options = {}) => {
  const {
    page = 1,
    limit = 10,
    search = '',
    role = '',
    status = '',
    affiliation = '',
    sortBy = 'created_at',
    sortOrder = 'DESC',
  } = options;

  const offset = (page - 1) * limit;

  // Build WHERE clause
  const conditions = [];
  const params = [];

  if (search) {
    conditions.push('(full_name LIKE ? OR email LIKE ? OR phone LIKE ? OR id_card_number LIKE ?)');
    const searchTerm = `%${search}%`;
    params.push(searchTerm, searchTerm, searchTerm, searchTerm);
  }

  if (role) {
    conditions.push('role = ?');
    params.push(role);
  }

  if (status) {
    conditions.push('status = ?');
    params.push(status);
  }

  if (affiliation) {
    conditions.push('affiliation = ?');
    params.push(affiliation);
  }

  const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

  // Validate sort column
  const allowedSortColumns = ['created_at', 'updated_at', 'full_name', 'email', 'role', 'status'];
  const safeSortBy = allowedSortColumns.includes(sortBy) ? sortBy : 'created_at';
  const safeSortOrder = sortOrder.toUpperCase() === 'ASC' ? 'ASC' : 'DESC';

  // Get total count
  const countSql = `SELECT COUNT(*) as total FROM users ${whereClause}`;
  const countResult = await db.queryOne(countSql, params);
  const total = countResult ? Number(countResult.total) : 0;

  // Get users
  const sql = `
    SELECT id, email, phone, full_name, id_card_number,
           affiliation, address, role, status, profile_image_url,
           approved_by, approved_at, created_at, updated_at, last_login_at
    FROM users
    ${whereClause}
    ORDER BY ${safeSortBy} ${safeSortOrder}
    LIMIT ? OFFSET ?
  `;

  const users = await db.query(sql, [...params, limit, offset]);

  return { users, total };
};

/**
 * Find users pending approval
 * @param {Object} options - Query options
 * @returns {Promise<{users: Array, total: number}>}
 */
const findPending = async (options = {}) => {
  const { page = 1, limit = 10, search = '' } = options;
  const offset = (page - 1) * limit;

  const conditions = ["status = 'pending'"];
  const params = [];

  if (search) {
    conditions.push('(full_name LIKE ? OR email LIKE ? OR phone LIKE ?)');
    const searchTerm = `%${search}%`;
    params.push(searchTerm, searchTerm, searchTerm);
  }

  const whereClause = `WHERE ${conditions.join(' AND ')}`;

  // Get total count
  const countSql = `SELECT COUNT(*) as total FROM users ${whereClause}`;
  const countResult = await db.queryOne(countSql, params);
  const total = countResult ? Number(countResult.total) : 0;

  // Get users
  const sql = `
    SELECT id, email, phone, full_name, id_card_number,
           affiliation, address, role, status, profile_image_url,
           created_at, updated_at
    FROM users
    ${whereClause}
    ORDER BY created_at ASC
    LIMIT ? OFFSET ?
  `;

  const users = await db.query(sql, [...params, limit, offset]);

  return { users, total };
};

/**
 * Find user by ID
 * @param {string} id - User UUID
 * @returns {Promise<Object|null>}
 */
const findById = async (id) => {
  const sql = `
    SELECT id, email, phone, full_name, id_card_number,
           affiliation, address, role, status, profile_image_url,
           device_token, approved_by, approved_at, rejection_reason,
           created_at, updated_at, last_login_at
    FROM users
    WHERE id = ?
  `;
  return db.queryOne(sql, [id]);
};

/**
 * Find user by ID with approver info
 * @param {string} id - User UUID
 * @returns {Promise<Object|null>}
 */
const findByIdWithApprover = async (id) => {
  const sql = `
    SELECT u.id, u.email, u.phone, u.full_name, u.id_card_number,
           u.affiliation, u.address, u.role, u.status, u.profile_image_url,
           u.approved_by, u.approved_at, u.rejection_reason,
           u.created_at, u.updated_at, u.last_login_at,
           approver.full_name as approver_name, approver.role as approver_role
    FROM users u
    LEFT JOIN users approver ON u.approved_by = approver.id
    WHERE u.id = ?
  `;
  return db.queryOne(sql, [id]);
};

/**
 * Update user by ID
 * @param {string} id - User UUID
 * @param {Object} updates - Fields to update
 * @returns {Promise<Object>}
 */
const update = async (id, updates) => {
  const allowedFields = [
    'email', 'phone', 'full_name', 'id_card_number',
    'affiliation', 'address', 'profile_image_url',
  ];

  const updatePairs = [];
  const values = [];

  for (const [key, value] of Object.entries(updates)) {
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
    UPDATE users
    SET ${updatePairs.join(', ')}, updated_at = CURRENT_TIMESTAMP
    WHERE id = ?
  `;

  await db.update(sql, values);
  return findById(id);
};

/**
 * Update user status (approve/reject/etc.)
 * @param {string} id - User UUID
 * @param {string} status - New status
 * @param {string} approvedBy - Approver user ID (optional)
 * @param {string} rejectionReason - Reason for rejection (optional)
 * @returns {Promise<Object>}
 */
const updateStatus = async (id, status, approvedBy = null, rejectionReason = null) => {
  let sql;
  let params;

  if (status === 'approved') {
    sql = `
      UPDATE users
      SET status = ?, approved_by = ?, approved_at = CURRENT_TIMESTAMP, rejection_reason = NULL, updated_at = CURRENT_TIMESTAMP
      WHERE id = ?
    `;
    params = [status, approvedBy, id];
  } else if (status === 'rejected') {
    sql = `
      UPDATE users
      SET status = ?, approved_by = ?, approved_at = CURRENT_TIMESTAMP, rejection_reason = ?, updated_at = CURRENT_TIMESTAMP
      WHERE id = ?
    `;
    params = [status, approvedBy, rejectionReason, id];
  } else {
    sql = `
      UPDATE users
      SET status = ?, updated_at = CURRENT_TIMESTAMP
      WHERE id = ?
    `;
    params = [status, id];
  }

  await db.update(sql, params);
  return findById(id);
};

/**
 * Update user role
 * @param {string} id - User UUID
 * @param {string} role - New role
 * @returns {Promise<Object>}
 */
const updateRole = async (id, role) => {
  const sql = `
    UPDATE users
    SET role = ?, updated_at = CURRENT_TIMESTAMP
    WHERE id = ?
  `;
  await db.update(sql, [role, id]);
  return findById(id);
};

/**
 * Soft delete user (set status to inactive)
 * @param {string} id - User UUID
 * @returns {Promise<Object>}
 */
const softDelete = async (id) => {
  const sql = `
    UPDATE users
    SET status = 'inactive', updated_at = CURRENT_TIMESTAMP
    WHERE id = ?
  `;
  await db.update(sql, [id]);
  return findById(id);
};

/**
 * Restore soft-deleted user
 * @param {string} id - User UUID
 * @param {string} status - Status to restore to (default: 'approved')
 * @returns {Promise<Object>}
 */
const restore = async (id, status = 'approved') => {
  const sql = `
    UPDATE users
    SET status = ?, updated_at = CURRENT_TIMESTAMP
    WHERE id = ?
  `;
  await db.update(sql, [status, id]);
  return findById(id);
};

/**
 * Check if email is taken (by another user)
 * @param {string} email - Email to check
 * @param {string} excludeId - User ID to exclude from check
 * @returns {Promise<boolean>}
 */
const isEmailTaken = async (email, excludeId = null) => {
  let sql = 'SELECT id FROM users WHERE email = ?';
  const params = [email];

  if (excludeId) {
    sql += ' AND id != ?';
    params.push(excludeId);
  }

  const result = await db.queryOne(sql, params);
  return !!result;
};

/**
 * Check if phone is taken (by another user)
 * @param {string} phone - Phone to check
 * @param {string} excludeId - User ID to exclude from check
 * @returns {Promise<boolean>}
 */
const isPhoneTaken = async (phone, excludeId = null) => {
  let sql = 'SELECT id FROM users WHERE phone = ?';
  const params = [phone];

  if (excludeId) {
    sql += ' AND id != ?';
    params.push(excludeId);
  }

  const result = await db.queryOne(sql, params);
  return !!result;
};

/**
 * Check if ID card number is taken (by another user)
 * @param {string} idCardNumber - ID card number to check
 * @param {string} excludeId - User ID to exclude from check
 * @returns {Promise<boolean>}
 */
const isIdCardTaken = async (idCardNumber, excludeId = null) => {
  let sql = 'SELECT id FROM users WHERE id_card_number = ?';
  const params = [idCardNumber];

  if (excludeId) {
    sql += ' AND id != ?';
    params.push(excludeId);
  }

  const result = await db.queryOne(sql, params);
  return !!result;
};

/**
 * Get user count by status
 * @returns {Promise<Object>}
 */
const getCountByStatus = async () => {
  const sql = `
    SELECT status, COUNT(*) as count
    FROM users
    GROUP BY status
  `;
  const results = await db.query(sql);

  const counts = {
    pending: 0,
    approved: 0,
    rejected: 0,
    inactive: 0,
    total: 0,
  };

  results.forEach(row => {
    counts[row.status] = Number(row.count);
    counts.total += Number(row.count);
  });

  return counts;
};

/**
 * Get user count by role
 * @returns {Promise<Object>}
 */
const getCountByRole = async () => {
  const sql = `
    SELECT role, COUNT(*) as count
    FROM users
    WHERE status = 'approved'
    GROUP BY role
  `;
  const results = await db.query(sql);

  const counts = {
    rider: 0,
    volunteer: 0,
    police: 0,
    admin: 0,
    super_admin: 0,
    total: 0,
  };

  results.forEach(row => {
    counts[row.role] = Number(row.count);
    counts.total += Number(row.count);
  });

  return counts;
};

module.exports = {
  findAll,
  findPending,
  findById,
  findByIdWithApprover,
  update,
  updateStatus,
  updateRole,
  softDelete,
  restore,
  isEmailTaken,
  isPhoneTaken,
  isIdCardTaken,
  getCountByStatus,
  getCountByRole,
};
