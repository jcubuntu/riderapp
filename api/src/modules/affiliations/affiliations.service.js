'use strict';

const affiliationsRepository = require('./affiliations.repository');
const { ApiError } = require('../../middleware/error.middleware');

/**
 * Get all active affiliations (public)
 * @returns {Promise<Array>} List of affiliations
 */
const getAllAffiliations = async () => {
  return affiliationsRepository.findAll();
};

/**
 * Get all affiliations including inactive (admin only)
 * @returns {Promise<Array>} List of all affiliations
 */
const getAllAffiliationsAdmin = async () => {
  return affiliationsRepository.findAllAdmin();
};

/**
 * Get affiliation by ID
 * @param {string} id - Affiliation UUID
 * @returns {Promise<Object>} Affiliation
 */
const getAffiliationById = async (id) => {
  const affiliation = await affiliationsRepository.findById(id);
  if (!affiliation) {
    throw new ApiError(404, 'Affiliation not found');
  }
  return affiliation;
};

/**
 * Create a new affiliation (admin only)
 * @param {Object} data - Affiliation data
 * @param {string} createdBy - User ID who created
 * @returns {Promise<Object>} Created affiliation
 */
const createAffiliation = async (data, createdBy) => {
  // Check if name already exists
  const existing = await affiliationsRepository.findByName(data.name);
  if (existing) {
    throw new ApiError(409, 'Affiliation with this name already exists');
  }

  return affiliationsRepository.create({
    name: data.name,
    description: data.description,
    createdBy,
  });
};

/**
 * Update an affiliation (admin only)
 * @param {string} id - Affiliation UUID
 * @param {Object} updates - Fields to update
 * @returns {Promise<Object>} Updated affiliation
 */
const updateAffiliation = async (id, updates) => {
  const affiliation = await affiliationsRepository.findById(id);
  if (!affiliation) {
    throw new ApiError(404, 'Affiliation not found');
  }

  // Check if new name conflicts with existing
  if (updates.name && updates.name !== affiliation.name) {
    const existing = await affiliationsRepository.findByName(updates.name);
    if (existing) {
      throw new ApiError(409, 'Affiliation with this name already exists');
    }
  }

  return affiliationsRepository.update(id, updates);
};

/**
 * Delete an affiliation (admin only)
 * @param {string} id - Affiliation UUID
 * @param {boolean} hard - If true, permanently delete
 * @returns {Promise<boolean>} Success status
 */
const deleteAffiliation = async (id, hard = false) => {
  const affiliation = await affiliationsRepository.findById(id);
  if (!affiliation) {
    throw new ApiError(404, 'Affiliation not found');
  }

  if (hard) {
    return affiliationsRepository.hardDelete(id);
  }
  return affiliationsRepository.softDelete(id);
};

/**
 * Restore a soft-deleted affiliation (admin only)
 * @param {string} id - Affiliation UUID
 * @returns {Promise<Object>} Restored affiliation
 */
const restoreAffiliation = async (id) => {
  const affiliation = await affiliationsRepository.findById(id);
  if (!affiliation) {
    throw new ApiError(404, 'Affiliation not found');
  }

  return affiliationsRepository.update(id, { isActive: true });
};

module.exports = {
  getAllAffiliations,
  getAllAffiliationsAdmin,
  getAffiliationById,
  createAffiliation,
  updateAffiliation,
  deleteAffiliation,
  restoreAffiliation,
};
