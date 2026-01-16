'use strict';

const incidentsRepository = require('./incidents.repository');
const { ROLES, hasMinimumRole } = require('../../constants/roles');

/**
 * Incidents Service - Business logic for incident management
 */

// ============= Constants =============

const INCIDENT_CATEGORIES = ['intelligence', 'accident', 'general'];
const INCIDENT_STATUSES = ['pending', 'reviewing', 'verified', 'resolved', 'rejected'];
const INCIDENT_PRIORITIES = ['low', 'medium', 'high', 'critical'];

// Status transitions allowed
const STATUS_TRANSITIONS = {
  pending: ['reviewing', 'rejected'],
  reviewing: ['verified', 'rejected', 'pending'],
  verified: ['resolved', 'reviewing'],
  resolved: ['verified'], // Can reopen
  rejected: ['pending'], // Can reopen
};

// ============= Incident Services =============

/**
 * Get all incidents with pagination and filtering
 * @param {Object} options - Query options
 * @returns {Promise<Object>}
 */
const getIncidents = async (options = {}) => {
  const { incidents, total } = await incidentsRepository.findAll(options);

  return {
    incidents: incidents.map(formatIncident),
    total,
    page: options.page || 1,
    limit: options.limit || 10,
  };
};

/**
 * Get incidents by user (own incidents)
 * @param {string} userId - User UUID
 * @param {Object} options - Query options
 * @returns {Promise<Object>}
 */
const getMyIncidents = async (userId, options = {}) => {
  const { incidents, total } = await incidentsRepository.findByUser(userId, options);

  return {
    incidents: incidents.map(formatIncident),
    total,
    page: options.page || 1,
    limit: options.limit || 10,
  };
};

/**
 * Get incident by ID
 * @param {string} id - Incident UUID
 * @param {Object} currentUser - Current user
 * @param {boolean} includeDetails - Include reporter/assignee/reviewer details
 * @returns {Promise<Object|null>}
 */
const getIncidentById = async (id, currentUser, includeDetails = true) => {
  const incident = includeDetails
    ? await incidentsRepository.findByIdWithDetails(id)
    : await incidentsRepository.findById(id);

  if (!incident) {
    return null;
  }

  // Check access - owner or volunteer+
  const isOwner = incident.reported_by === currentUser.id;
  const isVolunteerOrHigher = hasMinimumRole(currentUser.role, ROLES.VOLUNTEER);

  if (!isOwner && !isVolunteerOrHigher) {
    throw new Error('ACCESS_DENIED');
  }

  // Increment view count (don't await, fire and forget)
  incidentsRepository.incrementViewCount(id).catch(() => {});

  // Mask reporter info if anonymous and viewer is not the owner and not admin+
  const formatted = formatIncident(incident);
  if (incident.is_anonymous && !isOwner && !hasMinimumRole(currentUser.role, ROLES.ADMIN)) {
    formatted.reporterName = 'Anonymous';
    formatted.reporterPhone = null;
  }

  return formatted;
};

/**
 * Create a new incident
 * @param {Object} data - Incident data
 * @param {Object} currentUser - Current user creating the incident
 * @returns {Promise<Object>}
 */
const createIncident = async (data, currentUser) => {
  // Validate category
  if (data.category && !INCIDENT_CATEGORIES.includes(data.category)) {
    throw new Error('INVALID_CATEGORY');
  }

  // Validate priority
  if (data.priority && !INCIDENT_PRIORITIES.includes(data.priority)) {
    throw new Error('INVALID_PRIORITY');
  }

  const incidentData = {
    ...data,
    reportedBy: currentUser.id,
  };

  const incident = await incidentsRepository.create(incidentData);
  return formatIncident(incident);
};

/**
 * Update an incident
 * @param {string} id - Incident UUID
 * @param {Object} updates - Fields to update
 * @param {Object} currentUser - Current user
 * @returns {Promise<Object>}
 */
const updateIncident = async (id, updates, currentUser) => {
  // Get the incident
  const incident = await incidentsRepository.findById(id);
  if (!incident) {
    throw new Error('INCIDENT_NOT_FOUND');
  }

  // Check permissions - owner or admin+
  const isOwner = incident.reported_by === currentUser.id;
  const isAdmin = hasMinimumRole(currentUser.role, ROLES.ADMIN);

  if (!isOwner && !isAdmin) {
    throw new Error('ACCESS_DENIED');
  }

  // Non-admin owners can only update pending incidents
  if (!isAdmin && incident.status !== 'pending') {
    throw new Error('CANNOT_UPDATE_NON_PENDING');
  }

  // Validate category if provided
  if (updates.category && !INCIDENT_CATEGORIES.includes(updates.category)) {
    throw new Error('INVALID_CATEGORY');
  }

  // Validate priority if provided
  if (updates.priority && !INCIDENT_PRIORITIES.includes(updates.priority)) {
    throw new Error('INVALID_PRIORITY');
  }

  const updatedIncident = await incidentsRepository.update(id, updates);
  return formatIncident(updatedIncident);
};

/**
 * Update incident status
 * @param {string} id - Incident UUID
 * @param {string} status - New status
 * @param {string} notes - Optional notes
 * @param {Object} currentUser - Current user
 * @returns {Promise<Object>}
 */
const updateIncidentStatus = async (id, status, notes, currentUser) => {
  // Validate status
  if (!INCIDENT_STATUSES.includes(status)) {
    throw new Error('INVALID_STATUS');
  }

  // Get the incident
  const incident = await incidentsRepository.findById(id);
  if (!incident) {
    throw new Error('INCIDENT_NOT_FOUND');
  }

  // Check if transition is allowed
  const allowedTransitions = STATUS_TRANSITIONS[incident.status] || [];
  if (!allowedTransitions.includes(status)) {
    throw new Error('INVALID_STATUS_TRANSITION');
  }

  // Check permissions - police+ required for status updates
  if (!hasMinimumRole(currentUser.role, ROLES.POLICE)) {
    throw new Error('ACCESS_DENIED');
  }

  const updatedIncident = await incidentsRepository.updateStatus(id, status, currentUser.id, notes);
  return formatIncident(updatedIncident);
};

/**
 * Assign incident to a user
 * @param {string} id - Incident UUID
 * @param {string} assigneeId - User to assign to
 * @param {Object} currentUser - Current user
 * @returns {Promise<Object>}
 */
const assignIncident = async (id, assigneeId, currentUser) => {
  // Get the incident
  const incident = await incidentsRepository.findById(id);
  if (!incident) {
    throw new Error('INCIDENT_NOT_FOUND');
  }

  // Check permissions - police+ required
  if (!hasMinimumRole(currentUser.role, ROLES.POLICE)) {
    throw new Error('ACCESS_DENIED');
  }

  // Cannot assign resolved or rejected incidents
  if (['resolved', 'rejected'].includes(incident.status)) {
    throw new Error('CANNOT_ASSIGN_CLOSED_INCIDENT');
  }

  const updatedIncident = await incidentsRepository.assign(id, assigneeId);
  return formatIncident(updatedIncident);
};

/**
 * Unassign incident
 * @param {string} id - Incident UUID
 * @param {Object} currentUser - Current user
 * @returns {Promise<Object>}
 */
const unassignIncident = async (id, currentUser) => {
  // Get the incident
  const incident = await incidentsRepository.findById(id);
  if (!incident) {
    throw new Error('INCIDENT_NOT_FOUND');
  }

  // Check permissions - police+ required
  if (!hasMinimumRole(currentUser.role, ROLES.POLICE)) {
    throw new Error('ACCESS_DENIED');
  }

  const updatedIncident = await incidentsRepository.unassign(id);
  return formatIncident(updatedIncident);
};

/**
 * Delete an incident
 * @param {string} id - Incident UUID
 * @param {Object} currentUser - Current user
 * @returns {Promise<boolean>}
 */
const deleteIncident = async (id, currentUser) => {
  // Get the incident
  const incident = await incidentsRepository.findById(id);
  if (!incident) {
    throw new Error('INCIDENT_NOT_FOUND');
  }

  // Check permissions - admin+ only
  if (!hasMinimumRole(currentUser.role, ROLES.ADMIN)) {
    throw new Error('ACCESS_DENIED');
  }

  // Delete attachments first
  await incidentsRepository.removeAttachmentsByIncidentId(id);

  // Delete the incident
  const result = await incidentsRepository.remove(id);
  return result.affectedRows > 0;
};

/**
 * Get incident statistics
 * @returns {Promise<Object>}
 */
const getIncidentStats = async () => {
  return incidentsRepository.getStats();
};

// ============= Attachment Services =============

/**
 * Get attachments for an incident
 * @param {string} incidentId - Incident UUID
 * @param {Object} currentUser - Current user
 * @returns {Promise<Array>}
 */
const getAttachments = async (incidentId, currentUser) => {
  // Get the incident to check access
  const incident = await incidentsRepository.findById(incidentId);
  if (!incident) {
    throw new Error('INCIDENT_NOT_FOUND');
  }

  // Check access - owner or volunteer+
  const isOwner = incident.reported_by === currentUser.id;
  const isVolunteerOrHigher = hasMinimumRole(currentUser.role, ROLES.VOLUNTEER);

  if (!isOwner && !isVolunteerOrHigher) {
    throw new Error('ACCESS_DENIED');
  }

  const attachments = await incidentsRepository.findAttachmentsByIncidentId(incidentId);
  return attachments.map(formatAttachment);
};

/**
 * Add attachment to an incident
 * @param {string} incidentId - Incident UUID
 * @param {Object} fileData - File data
 * @param {Object} currentUser - Current user
 * @returns {Promise<Object>}
 */
const addAttachment = async (incidentId, fileData, currentUser) => {
  // Get the incident
  const incident = await incidentsRepository.findById(incidentId);
  if (!incident) {
    throw new Error('INCIDENT_NOT_FOUND');
  }

  // Check permissions - owner only
  if (incident.reported_by !== currentUser.id) {
    throw new Error('ACCESS_DENIED');
  }

  // Check attachment limit (e.g., max 10 attachments per incident)
  const attachmentCount = await incidentsRepository.countAttachmentsByIncidentId(incidentId);
  if (attachmentCount >= 10) {
    throw new Error('ATTACHMENT_LIMIT_EXCEEDED');
  }

  const attachmentData = {
    ...fileData,
    incidentId,
    uploadedBy: currentUser.id,
    sortOrder: attachmentCount,
  };

  const attachment = await incidentsRepository.createAttachment(attachmentData);
  return formatAttachment(attachment);
};

/**
 * Delete an attachment
 * @param {string} attachmentId - Attachment UUID
 * @param {Object} currentUser - Current user
 * @returns {Promise<boolean>}
 */
const deleteAttachment = async (attachmentId, currentUser) => {
  // Get the attachment
  const attachment = await incidentsRepository.findAttachmentById(attachmentId);
  if (!attachment) {
    throw new Error('ATTACHMENT_NOT_FOUND');
  }

  // Get the incident
  const incident = await incidentsRepository.findById(attachment.incident_id);
  if (!incident) {
    throw new Error('INCIDENT_NOT_FOUND');
  }

  // Check permissions - owner or admin+
  const isOwner = incident.reported_by === currentUser.id;
  const isAdmin = hasMinimumRole(currentUser.role, ROLES.ADMIN);

  if (!isOwner && !isAdmin) {
    throw new Error('ACCESS_DENIED');
  }

  const result = await incidentsRepository.removeAttachment(attachmentId);
  return result.affectedRows > 0;
};

// ============= Helper Functions =============

/**
 * Format incident object for response
 * @param {Object} incident - Incident from database
 * @returns {Object}
 */
const formatIncident = (incident) => {
  if (!incident) return null;

  return {
    id: incident.id,
    reportedBy: incident.reported_by,
    category: incident.category,
    status: incident.status,
    priority: incident.priority,
    title: incident.title,
    description: incident.description,
    location: {
      lat: incident.location_lat ? parseFloat(incident.location_lat) : null,
      lng: incident.location_lng ? parseFloat(incident.location_lng) : null,
      address: incident.location_address,
      province: incident.location_province,
      district: incident.location_district,
    },
    incidentDate: incident.incident_date,
    assignedTo: incident.assigned_to,
    assignedAt: incident.assigned_at,
    reviewedBy: incident.reviewed_by,
    reviewedAt: incident.reviewed_at,
    reviewNotes: incident.review_notes,
    resolvedBy: incident.resolved_by,
    resolvedAt: incident.resolved_at,
    resolutionNotes: incident.resolution_notes,
    isAnonymous: Boolean(incident.is_anonymous),
    viewCount: incident.view_count,
    createdAt: incident.created_at,
    updatedAt: incident.updated_at,
    // Related user info (if joined)
    reporterName: incident.reporter_name || null,
    reporterPhone: incident.reporter_phone || null,
    reporterRole: incident.reporter_role || null,
    assigneeName: incident.assignee_name || null,
    assigneePhone: incident.assignee_phone || null,
    assigneeRole: incident.assignee_role || null,
    reviewerName: incident.reviewer_name || null,
    reviewerRole: incident.reviewer_role || null,
    resolverName: incident.resolver_name || null,
    resolverRole: incident.resolver_role || null,
  };
};

/**
 * Format attachment object for response
 * @param {Object} attachment - Attachment from database
 * @returns {Object}
 */
const formatAttachment = (attachment) => {
  if (!attachment) return null;

  return {
    id: attachment.id,
    incidentId: attachment.incident_id,
    fileName: attachment.file_name,
    filePath: attachment.file_path,
    fileUrl: attachment.file_url,
    fileType: attachment.file_type,
    mimeType: attachment.mime_type,
    fileSize: attachment.file_size,
    width: attachment.width,
    height: attachment.height,
    duration: attachment.duration,
    thumbnailUrl: attachment.thumbnail_url,
    description: attachment.description,
    sortOrder: attachment.sort_order,
    isPrimary: Boolean(attachment.is_primary),
    uploadedBy: attachment.uploaded_by,
    createdAt: attachment.created_at,
    updatedAt: attachment.updated_at,
  };
};

/**
 * Determine file type from MIME type
 * @param {string} mimeType - MIME type
 * @returns {string}
 */
const getFileTypeFromMime = (mimeType) => {
  if (mimeType.startsWith('image/')) return 'image';
  if (mimeType.startsWith('video/')) return 'video';
  if (mimeType.startsWith('audio/')) return 'audio';
  return 'document';
};

module.exports = {
  // Constants
  INCIDENT_CATEGORIES,
  INCIDENT_STATUSES,
  INCIDENT_PRIORITIES,
  // Incident services
  getIncidents,
  getMyIncidents,
  getIncidentById,
  createIncident,
  updateIncident,
  updateIncidentStatus,
  assignIncident,
  unassignIncident,
  deleteIncident,
  getIncidentStats,
  // Attachment services
  getAttachments,
  addAttachment,
  deleteAttachment,
  // Helpers
  getFileTypeFromMime,
};
