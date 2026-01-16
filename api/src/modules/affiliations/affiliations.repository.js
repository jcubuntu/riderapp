'use strict';

const db = require('../../config/database');

/**
 * Get all active affiliations
 * @returns {Promise<Array>} List of affiliations
 */
const findAll = async () => {
  const rows = await db.query(
    `SELECT id, name, description, is_active, created_at, updated_at
     FROM affiliations
     WHERE is_active = TRUE
     ORDER BY name ASC`
  );
  return rows;
};

/**
 * Get all affiliations (including inactive) - for admin
 * @returns {Promise<Array>} List of all affiliations
 */
const findAllAdmin = async () => {
  const rows = await db.query(
    `SELECT id, name, description, is_active, created_at, updated_at, created_by
     FROM affiliations
     ORDER BY name ASC`
  );
  return rows;
};

/**
 * Find affiliation by ID
 * @param {string} id - Affiliation UUID
 * @returns {Promise<Object|null>} Affiliation or null
 */
const findById = async (id) => {
  const rows = await db.query(
    `SELECT id, name, description, is_active, created_at, updated_at, created_by
     FROM affiliations
     WHERE id = ?`,
    [id]
  );
  return rows[0] || null;
};

/**
 * Find affiliation by name
 * @param {string} name - Affiliation name
 * @returns {Promise<Object|null>} Affiliation or null
 */
const findByName = async (name) => {
  const rows = await db.query(
    `SELECT id, name, description, is_active, created_at, updated_at
     FROM affiliations
     WHERE name = ?`,
    [name]
  );
  return rows[0] || null;
};

/**
 * Create a new affiliation
 * @param {Object} data - Affiliation data
 * @returns {Promise<Object>} Created affiliation
 */
const create = async (data) => {
  const id = require('crypto').randomUUID();

  await db.query(
    `INSERT INTO affiliations (id, name, description, created_by)
     VALUES (?, ?, ?, ?)`,
    [id, data.name, data.description || null, data.createdBy || null]
  );

  return findById(id);
};

/**
 * Update an affiliation
 * @param {string} id - Affiliation UUID
 * @param {Object} updates - Fields to update
 * @returns {Promise<Object>} Updated affiliation
 */
const update = async (id, updates) => {
  const fields = [];
  const values = [];

  if (updates.name !== undefined) {
    fields.push('name = ?');
    values.push(updates.name);
  }
  if (updates.description !== undefined) {
    fields.push('description = ?');
    values.push(updates.description);
  }
  if (updates.isActive !== undefined) {
    fields.push('is_active = ?');
    values.push(updates.isActive);
  }

  if (fields.length === 0) {
    return findById(id);
  }

  values.push(id);
  await db.query(
    `UPDATE affiliations SET ${fields.join(', ')} WHERE id = ?`,
    values
  );

  return findById(id);
};

/**
 * Delete an affiliation (soft delete by setting is_active to false)
 * @param {string} id - Affiliation UUID
 * @returns {Promise<boolean>} Success status
 */
const softDelete = async (id) => {
  const result = await db.query(
    `UPDATE affiliations SET is_active = FALSE WHERE id = ?`,
    [id]
  );
  return result.affectedRows > 0;
};

/**
 * Hard delete an affiliation (permanent)
 * @param {string} id - Affiliation UUID
 * @returns {Promise<boolean>} Success status
 */
const hardDelete = async (id) => {
  const result = await db.query(
    `DELETE FROM affiliations WHERE id = ?`,
    [id]
  );
  return result.affectedRows > 0;
};

module.exports = {
  findAll,
  findAllAdmin,
  findById,
  findByName,
  create,
  update,
  softDelete,
  hardDelete,
};
