'use strict';

const path = require('path');
const incidentsService = require('./incidents.service');
const {
  successResponse,
  createdResponse,
  paginatedResponse,
  notFoundResponse,
  badRequestResponse,
  forbiddenResponse,
  calculatePagination,
  parsePaginationQuery,
} = require('../../utils/response.utils');

/**
 * Incidents Controller - Handle HTTP requests for incident management
 */

// ============= Incident Endpoints =============

/**
 * Get all incidents (paginated)
 * GET /incidents
 */
const getIncidents = async (req, res) => {
  try {
    const { page, limit } = parsePaginationQuery(req.query);
    const {
      search, category, status, priority, province,
      assignedTo, reportedBy, dateFrom, dateTo, sortBy, sortOrder,
    } = req.query;

    const result = await incidentsService.getIncidents({
      page,
      limit,
      search,
      category,
      status,
      priority,
      province,
      assignedTo,
      reportedBy,
      dateFrom,
      dateTo,
      sortBy,
      sortOrder,
    });

    const pagination = calculatePagination(page, limit, result.total);

    return paginatedResponse(res, result.incidents, pagination, 'Incidents retrieved successfully');
  } catch (error) {
    console.error('Get incidents error:', error);
    return badRequestResponse(res, 'Failed to retrieve incidents');
  }
};

/**
 * Get own incidents (paginated)
 * GET /incidents/my
 */
const getMyIncidents = async (req, res) => {
  try {
    const { page, limit } = parsePaginationQuery(req.query);
    const { search, category, status, priority, sortBy, sortOrder } = req.query;

    const result = await incidentsService.getMyIncidents(req.user.id, {
      page,
      limit,
      search,
      category,
      status,
      priority,
      sortBy,
      sortOrder,
    });

    const pagination = calculatePagination(page, limit, result.total);

    return paginatedResponse(res, result.incidents, pagination, 'Your incidents retrieved successfully');
  } catch (error) {
    console.error('Get my incidents error:', error);
    return badRequestResponse(res, 'Failed to retrieve your incidents');
  }
};

/**
 * Get incident by ID
 * GET /incidents/:id
 */
const getIncidentById = async (req, res) => {
  try {
    const { id } = req.params;
    const includeDetails = req.query.includeDetails !== 'false';

    const incident = await incidentsService.getIncidentById(id, req.user, includeDetails);

    if (!incident) {
      return notFoundResponse(res, 'Incident not found');
    }

    return successResponse(res, incident, 'Incident retrieved successfully');
  } catch (error) {
    console.error('Get incident by ID error:', error);

    switch (error.message) {
      case 'ACCESS_DENIED':
        return forbiddenResponse(res, 'You do not have permission to view this incident');
      default:
        return badRequestResponse(res, 'Failed to retrieve incident');
    }
  }
};

/**
 * Create incident
 * POST /incidents
 */
const createIncident = async (req, res) => {
  try {
    const incident = await incidentsService.createIncident(req.body, req.user);

    return createdResponse(res, incident, 'Incident created successfully');
  } catch (error) {
    console.error('Create incident error:', error);

    switch (error.message) {
      case 'INVALID_CATEGORY':
        return badRequestResponse(res, 'Invalid incident category');
      case 'INVALID_PRIORITY':
        return badRequestResponse(res, 'Invalid incident priority');
      default:
        return badRequestResponse(res, 'Failed to create incident');
    }
  }
};

/**
 * Update incident
 * PUT /incidents/:id
 */
const updateIncident = async (req, res) => {
  try {
    const { id } = req.params;

    const incident = await incidentsService.updateIncident(id, req.body, req.user);

    return successResponse(res, incident, 'Incident updated successfully');
  } catch (error) {
    console.error('Update incident error:', error);

    switch (error.message) {
      case 'INCIDENT_NOT_FOUND':
        return notFoundResponse(res, 'Incident not found');
      case 'ACCESS_DENIED':
        return forbiddenResponse(res, 'You do not have permission to update this incident');
      case 'CANNOT_UPDATE_NON_PENDING':
        return forbiddenResponse(res, 'You can only update incidents with pending status');
      case 'INVALID_CATEGORY':
        return badRequestResponse(res, 'Invalid incident category');
      case 'INVALID_PRIORITY':
        return badRequestResponse(res, 'Invalid incident priority');
      default:
        return badRequestResponse(res, 'Failed to update incident');
    }
  }
};

/**
 * Delete incident
 * DELETE /incidents/:id
 */
const deleteIncident = async (req, res) => {
  try {
    const { id } = req.params;

    await incidentsService.deleteIncident(id, req.user);

    return successResponse(res, null, 'Incident deleted successfully');
  } catch (error) {
    console.error('Delete incident error:', error);

    switch (error.message) {
      case 'INCIDENT_NOT_FOUND':
        return notFoundResponse(res, 'Incident not found');
      case 'ACCESS_DENIED':
        return forbiddenResponse(res, 'You do not have permission to delete this incident');
      default:
        return badRequestResponse(res, 'Failed to delete incident');
    }
  }
};

/**
 * Update incident status
 * PATCH /incidents/:id/status
 */
const updateIncidentStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status, notes } = req.body;

    const incident = await incidentsService.updateIncidentStatus(id, status, notes, req.user);

    return successResponse(res, incident, 'Incident status updated successfully');
  } catch (error) {
    console.error('Update incident status error:', error);

    switch (error.message) {
      case 'INCIDENT_NOT_FOUND':
        return notFoundResponse(res, 'Incident not found');
      case 'INVALID_STATUS':
        return badRequestResponse(res, 'Invalid status value');
      case 'INVALID_STATUS_TRANSITION':
        return badRequestResponse(res, 'Invalid status transition');
      case 'ACCESS_DENIED':
        return forbiddenResponse(res, 'You do not have permission to change incident status');
      default:
        return badRequestResponse(res, 'Failed to update incident status');
    }
  }
};

/**
 * Assign incident to officer
 * POST /incidents/:id/assign
 */
const assignIncident = async (req, res) => {
  try {
    const { id } = req.params;
    const { assigneeId } = req.body;

    const incident = await incidentsService.assignIncident(id, assigneeId, req.user);

    return successResponse(res, incident, 'Incident assigned successfully');
  } catch (error) {
    console.error('Assign incident error:', error);

    switch (error.message) {
      case 'INCIDENT_NOT_FOUND':
        return notFoundResponse(res, 'Incident not found');
      case 'ACCESS_DENIED':
        return forbiddenResponse(res, 'You do not have permission to assign incidents');
      case 'CANNOT_ASSIGN_CLOSED_INCIDENT':
        return badRequestResponse(res, 'Cannot assign resolved or rejected incidents');
      default:
        return badRequestResponse(res, 'Failed to assign incident');
    }
  }
};

/**
 * Unassign incident
 * DELETE /incidents/:id/assign
 */
const unassignIncident = async (req, res) => {
  try {
    const { id } = req.params;

    const incident = await incidentsService.unassignIncident(id, req.user);

    return successResponse(res, incident, 'Incident unassigned successfully');
  } catch (error) {
    console.error('Unassign incident error:', error);

    switch (error.message) {
      case 'INCIDENT_NOT_FOUND':
        return notFoundResponse(res, 'Incident not found');
      case 'ACCESS_DENIED':
        return forbiddenResponse(res, 'You do not have permission to unassign incidents');
      default:
        return badRequestResponse(res, 'Failed to unassign incident');
    }
  }
};

/**
 * Get incident statistics
 * GET /incidents/stats
 */
const getIncidentStats = async (req, res) => {
  try {
    const stats = await incidentsService.getIncidentStats();

    return successResponse(res, stats, 'Incident statistics retrieved successfully');
  } catch (error) {
    console.error('Get incident stats error:', error);
    return badRequestResponse(res, 'Failed to retrieve incident statistics');
  }
};

// ============= Attachment Endpoints =============

/**
 * Get attachments for an incident
 * GET /incidents/:id/attachments
 */
const getAttachments = async (req, res) => {
  try {
    const { id } = req.params;

    const attachments = await incidentsService.getAttachments(id, req.user);

    return successResponse(res, attachments, 'Attachments retrieved successfully');
  } catch (error) {
    console.error('Get attachments error:', error);

    switch (error.message) {
      case 'INCIDENT_NOT_FOUND':
        return notFoundResponse(res, 'Incident not found');
      case 'ACCESS_DENIED':
        return forbiddenResponse(res, 'You do not have permission to view these attachments');
      default:
        return badRequestResponse(res, 'Failed to retrieve attachments');
    }
  }
};

/**
 * Upload attachment(s) to an incident
 * POST /incidents/:id/attachments
 */
const uploadAttachments = async (req, res) => {
  try {
    const { id } = req.params;

    // Check if files were uploaded
    if (!req.files || req.files.length === 0) {
      return badRequestResponse(res, 'No files uploaded');
    }

    const uploadedAttachments = [];
    const errors = [];

    // Process each uploaded file
    for (const file of req.files) {
      try {
        const fileType = incidentsService.getFileTypeFromMime(file.mimetype);

        // Generate file URL (adjust based on your file serving strategy)
        const fileUrl = `/uploads/incidents/${file.filename}`;

        const attachmentData = {
          fileName: file.originalname,
          filePath: file.path,
          fileUrl: fileUrl,
          fileType: fileType,
          mimeType: file.mimetype,
          fileSize: file.size,
          description: req.body.description || null,
        };

        const attachment = await incidentsService.addAttachment(id, attachmentData, req.user);
        uploadedAttachments.push(attachment);
      } catch (fileError) {
        errors.push({
          fileName: file.originalname,
          error: fileError.message,
        });
      }
    }

    if (uploadedAttachments.length === 0) {
      return badRequestResponse(res, 'Failed to upload any attachments', errors);
    }

    const response = {
      uploaded: uploadedAttachments,
      uploadedCount: uploadedAttachments.length,
    };

    if (errors.length > 0) {
      response.errors = errors;
      response.errorCount = errors.length;
    }

    return createdResponse(res, response, `${uploadedAttachments.length} attachment(s) uploaded successfully`);
  } catch (error) {
    console.error('Upload attachments error:', error);

    switch (error.message) {
      case 'INCIDENT_NOT_FOUND':
        return notFoundResponse(res, 'Incident not found');
      case 'ACCESS_DENIED':
        return forbiddenResponse(res, 'You do not have permission to upload attachments to this incident');
      case 'ATTACHMENT_LIMIT_EXCEEDED':
        return badRequestResponse(res, 'Maximum attachment limit (10) exceeded');
      default:
        return badRequestResponse(res, 'Failed to upload attachments');
    }
  }
};

/**
 * Delete an attachment
 * DELETE /incidents/:id/attachments/:attachmentId
 */
const deleteAttachment = async (req, res) => {
  try {
    const { attachmentId } = req.params;

    await incidentsService.deleteAttachment(attachmentId, req.user);

    return successResponse(res, null, 'Attachment deleted successfully');
  } catch (error) {
    console.error('Delete attachment error:', error);

    switch (error.message) {
      case 'ATTACHMENT_NOT_FOUND':
        return notFoundResponse(res, 'Attachment not found');
      case 'INCIDENT_NOT_FOUND':
        return notFoundResponse(res, 'Incident not found');
      case 'ACCESS_DENIED':
        return forbiddenResponse(res, 'You do not have permission to delete this attachment');
      default:
        return badRequestResponse(res, 'Failed to delete attachment');
    }
  }
};

module.exports = {
  // Incident endpoints
  getIncidents,
  getMyIncidents,
  getIncidentById,
  createIncident,
  updateIncident,
  deleteIncident,
  updateIncidentStatus,
  assignIncident,
  unassignIncident,
  getIncidentStats,
  // Attachment endpoints
  getAttachments,
  uploadAttachments,
  deleteAttachment,
};
