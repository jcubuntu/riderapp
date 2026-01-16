'use strict';

const emergencyService = require('./emergency.service');
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
 * Emergency Controller - Handle HTTP requests for emergency contacts and SOS
 */

// ==================== Emergency Contacts ====================

/**
 * Get emergency contacts (public - active only)
 * GET /emergency/contacts
 */
const getContacts = async (req, res) => {
  try {
    const { category, province } = req.query;

    const contacts = await emergencyService.getActiveContacts({
      category,
      province,
    });

    return successResponse(res, contacts, 'Emergency contacts retrieved successfully');
  } catch (error) {
    console.error('Get emergency contacts error:', error);
    return badRequestResponse(res, 'Failed to retrieve emergency contacts');
  }
};

/**
 * Get all emergency contacts with pagination (admin view)
 * GET /emergency/contacts/admin
 */
const getContactsAdmin = async (req, res) => {
  try {
    const { page, limit } = parsePaginationQuery(req.query);
    const { search, category, province, isActive, isNationwide, is24Hours, sortBy, sortOrder } = req.query;

    // Convert string booleans to actual booleans
    const parseBoolean = (value) => {
      if (value === 'true') return true;
      if (value === 'false') return false;
      return null;
    };

    const result = await emergencyService.getContacts({
      page,
      limit,
      search,
      category,
      province,
      isActive: parseBoolean(isActive),
      isNationwide: parseBoolean(isNationwide),
      is24Hours: parseBoolean(is24Hours),
      sortBy,
      sortOrder,
    });

    const pagination = calculatePagination(page, limit, result.total);

    return paginatedResponse(res, result.contacts, pagination, 'Emergency contacts retrieved successfully');
  } catch (error) {
    console.error('Get emergency contacts (admin) error:', error);
    return badRequestResponse(res, 'Failed to retrieve emergency contacts');
  }
};

/**
 * Get emergency contact by ID
 * GET /emergency/contacts/:id
 */
const getContactById = async (req, res) => {
  try {
    const { id } = req.params;

    const contact = await emergencyService.getContactById(id);

    if (!contact) {
      return notFoundResponse(res, 'Emergency contact not found');
    }

    return successResponse(res, contact, 'Emergency contact retrieved successfully');
  } catch (error) {
    console.error('Get emergency contact by ID error:', error);
    return badRequestResponse(res, 'Failed to retrieve emergency contact');
  }
};

/**
 * Create emergency contact
 * POST /emergency/contacts
 */
const createContact = async (req, res) => {
  try {
    const contact = await emergencyService.createContact(req.body, req.user);

    return createdResponse(res, contact, 'Emergency contact created successfully');
  } catch (error) {
    console.error('Create emergency contact error:', error);

    switch (error.message) {
      case 'ACCESS_DENIED':
        return forbiddenResponse(res, 'You do not have permission to create emergency contacts');
      case 'MISSING_REQUIRED_FIELDS':
        return badRequestResponse(res, 'Name and phone are required');
      case 'INVALID_CATEGORY':
        return badRequestResponse(res, 'Invalid contact category');
      default:
        return badRequestResponse(res, 'Failed to create emergency contact');
    }
  }
};

/**
 * Update emergency contact
 * PUT /emergency/contacts/:id
 */
const updateContact = async (req, res) => {
  try {
    const { id } = req.params;

    const contact = await emergencyService.updateContact(id, req.body, req.user);

    return successResponse(res, contact, 'Emergency contact updated successfully');
  } catch (error) {
    console.error('Update emergency contact error:', error);

    switch (error.message) {
      case 'ACCESS_DENIED':
        return forbiddenResponse(res, 'You do not have permission to update emergency contacts');
      case 'CONTACT_NOT_FOUND':
        return notFoundResponse(res, 'Emergency contact not found');
      case 'INVALID_CATEGORY':
        return badRequestResponse(res, 'Invalid contact category');
      default:
        return badRequestResponse(res, 'Failed to update emergency contact');
    }
  }
};

/**
 * Delete emergency contact
 * DELETE /emergency/contacts/:id
 */
const deleteContact = async (req, res) => {
  try {
    const { id } = req.params;

    await emergencyService.deleteContact(id, req.user);

    return successResponse(res, null, 'Emergency contact deleted successfully');
  } catch (error) {
    console.error('Delete emergency contact error:', error);

    switch (error.message) {
      case 'ACCESS_DENIED':
        return forbiddenResponse(res, 'You do not have permission to delete emergency contacts');
      case 'CONTACT_NOT_FOUND':
        return notFoundResponse(res, 'Emergency contact not found');
      default:
        return badRequestResponse(res, 'Failed to delete emergency contact');
    }
  }
};

/**
 * Get emergency contact statistics
 * GET /emergency/contacts/stats
 */
const getContactStats = async (req, res) => {
  try {
    const stats = await emergencyService.getContactStats();

    return successResponse(res, stats, 'Emergency contact statistics retrieved successfully');
  } catch (error) {
    console.error('Get emergency contact stats error:', error);
    return badRequestResponse(res, 'Failed to retrieve emergency contact statistics');
  }
};

// ==================== SOS Alerts ====================

/**
 * Trigger SOS alert
 * POST /emergency/sos
 */
const triggerSos = async (req, res) => {
  try {
    const { latitude, longitude, message } = req.body;

    const sos = emergencyService.triggerSos(
      { latitude, longitude, message },
      req.user
    );

    return createdResponse(res, sos, 'SOS alert triggered successfully');
  } catch (error) {
    console.error('Trigger SOS error:', error);
    return badRequestResponse(res, 'Failed to trigger SOS alert');
  }
};

/**
 * Cancel SOS alert
 * DELETE /emergency/sos
 */
const cancelSos = async (req, res) => {
  try {
    const sos = emergencyService.cancelSos(req.user);

    return successResponse(res, sos, 'SOS alert cancelled successfully');
  } catch (error) {
    console.error('Cancel SOS error:', error);

    switch (error.message) {
      case 'NO_ACTIVE_SOS':
        return notFoundResponse(res, 'No active SOS alert found');
      default:
        return badRequestResponse(res, 'Failed to cancel SOS alert');
    }
  }
};

/**
 * Get SOS status
 * GET /emergency/sos/status
 */
const getSosStatus = async (req, res) => {
  try {
    const status = emergencyService.getSosStatus(req.user);

    return successResponse(res, status, 'SOS status retrieved successfully');
  } catch (error) {
    console.error('Get SOS status error:', error);
    return badRequestResponse(res, 'Failed to retrieve SOS status');
  }
};

/**
 * Get all active SOS alerts (for responders)
 * GET /emergency/sos/active
 */
const getAllActiveSos = async (req, res) => {
  try {
    const alerts = emergencyService.getAllActiveSos(req.user);

    return successResponse(res, alerts, 'Active SOS alerts retrieved successfully');
  } catch (error) {
    console.error('Get all active SOS error:', error);

    switch (error.message) {
      case 'ACCESS_DENIED':
        return forbiddenResponse(res, 'You do not have permission to view all SOS alerts');
      default:
        return badRequestResponse(res, 'Failed to retrieve active SOS alerts');
    }
  }
};

/**
 * Resolve SOS alert (for responders)
 * POST /emergency/sos/:id/resolve
 */
const resolveSos = async (req, res) => {
  try {
    const { id } = req.params;
    const { notes } = req.body;

    const sos = emergencyService.resolveSos(id, notes, req.user);

    return successResponse(res, sos, 'SOS alert resolved successfully');
  } catch (error) {
    console.error('Resolve SOS error:', error);

    switch (error.message) {
      case 'ACCESS_DENIED':
        return forbiddenResponse(res, 'You do not have permission to resolve SOS alerts');
      case 'SOS_NOT_FOUND':
        return notFoundResponse(res, 'SOS alert not found');
      case 'SOS_NOT_ACTIVE':
        return badRequestResponse(res, 'SOS alert is not active');
      case 'RESOLVE_FAILED':
        return badRequestResponse(res, 'Failed to resolve SOS alert');
      default:
        return badRequestResponse(res, 'Failed to resolve SOS alert');
    }
  }
};

/**
 * Get SOS statistics
 * GET /emergency/sos/stats
 */
const getSosStats = async (req, res) => {
  try {
    const stats = emergencyService.getSosStats(req.user);

    return successResponse(res, stats, 'SOS statistics retrieved successfully');
  } catch (error) {
    console.error('Get SOS stats error:', error);

    switch (error.message) {
      case 'ACCESS_DENIED':
        return forbiddenResponse(res, 'You do not have permission to view SOS statistics');
      default:
        return badRequestResponse(res, 'Failed to retrieve SOS statistics');
    }
  }
};

module.exports = {
  // Emergency Contacts
  getContacts,
  getContactsAdmin,
  getContactById,
  createContact,
  updateContact,
  deleteContact,
  getContactStats,
  // SOS Alerts
  triggerSos,
  cancelSos,
  getSosStatus,
  getAllActiveSos,
  resolveSos,
  getSosStats,
};
