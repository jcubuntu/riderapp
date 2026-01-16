'use strict';

const affiliationsService = require('./affiliations.service');
const { successResponse } = require('../../utils/response.utils');

/**
 * Get all active affiliations (public)
 */
const getAllAffiliations = async (req, res) => {
  const affiliations = await affiliationsService.getAllAffiliations();
  return successResponse(res, { affiliations });
};

/**
 * Get all affiliations including inactive (admin only)
 */
const getAllAffiliationsAdmin = async (req, res) => {
  const affiliations = await affiliationsService.getAllAffiliationsAdmin();
  return successResponse(res, { affiliations });
};

/**
 * Get affiliation by ID
 */
const getAffiliationById = async (req, res) => {
  const affiliation = await affiliationsService.getAffiliationById(req.params.id);
  return successResponse(res, { affiliation });
};

/**
 * Create a new affiliation (admin only)
 */
const createAffiliation = async (req, res) => {
  const affiliation = await affiliationsService.createAffiliation(
    req.body,
    req.user.id
  );
  return successResponse(res, { affiliation }, 201);
};

/**
 * Update an affiliation (admin only)
 */
const updateAffiliation = async (req, res) => {
  const affiliation = await affiliationsService.updateAffiliation(
    req.params.id,
    req.body
  );
  return successResponse(res, { affiliation });
};

/**
 * Delete an affiliation (admin only)
 */
const deleteAffiliation = async (req, res) => {
  const hard = req.query.hard === 'true';
  await affiliationsService.deleteAffiliation(req.params.id, hard);
  return successResponse(res, { message: 'Affiliation deleted successfully' });
};

/**
 * Restore a soft-deleted affiliation (admin only)
 */
const restoreAffiliation = async (req, res) => {
  const affiliation = await affiliationsService.restoreAffiliation(req.params.id);
  return successResponse(res, { affiliation });
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
