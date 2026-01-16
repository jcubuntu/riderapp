'use strict';

/**
 * User account status constants
 */
const USER_STATUS = Object.freeze({
  ACTIVE: 'active',
  INACTIVE: 'inactive',
  SUSPENDED: 'suspended',
  PENDING: 'pending',
  DELETED: 'deleted',
});

/**
 * Incident status constants
 */
const INCIDENT_STATUS = Object.freeze({
  PENDING: 'pending',
  IN_PROGRESS: 'in_progress',
  RESOLVED: 'resolved',
  CLOSED: 'closed',
  CANCELLED: 'cancelled',
});

/**
 * Incident priority constants
 */
const INCIDENT_PRIORITY = Object.freeze({
  LOW: 'low',
  MEDIUM: 'medium',
  HIGH: 'high',
  CRITICAL: 'critical',
});

/**
 * Incident type constants
 */
const INCIDENT_TYPE = Object.freeze({
  ACCIDENT: 'accident',
  THEFT: 'theft',
  HARASSMENT: 'harassment',
  ROAD_HAZARD: 'road_hazard',
  VEHICLE_BREAKDOWN: 'vehicle_breakdown',
  TRAFFIC_VIOLATION: 'traffic_violation',
  EMERGENCY: 'emergency',
  OTHER: 'other',
});

/**
 * Notification status constants
 */
const NOTIFICATION_STATUS = Object.freeze({
  UNREAD: 'unread',
  READ: 'read',
  ARCHIVED: 'archived',
});

/**
 * Attachment type constants
 */
const ATTACHMENT_TYPE = Object.freeze({
  IMAGE: 'image',
  VIDEO: 'video',
  DOCUMENT: 'document',
  AUDIO: 'audio',
});

/**
 * Token status constants
 */
const TOKEN_STATUS = Object.freeze({
  ACTIVE: 'active',
  REVOKED: 'revoked',
  EXPIRED: 'expired',
});

/**
 * Get all values from a status object
 * @param {Object} statusObj - Status object
 * @returns {string[]} Array of status values
 */
const getStatusValues = (statusObj) => Object.values(statusObj);

/**
 * Check if a value is a valid status
 * @param {Object} statusObj - Status object to check against
 * @param {string} value - Value to check
 * @returns {boolean} True if valid
 */
const isValidStatus = (statusObj, value) => getStatusValues(statusObj).includes(value);

/**
 * Status display names
 */
const STATUS_DISPLAY_NAMES = Object.freeze({
  // User statuses
  [USER_STATUS.ACTIVE]: 'Active',
  [USER_STATUS.INACTIVE]: 'Inactive',
  [USER_STATUS.SUSPENDED]: 'Suspended',
  [USER_STATUS.PENDING]: 'Pending Verification',
  [USER_STATUS.DELETED]: 'Deleted',

  // Incident statuses
  [INCIDENT_STATUS.PENDING]: 'Pending',
  [INCIDENT_STATUS.IN_PROGRESS]: 'In Progress',
  [INCIDENT_STATUS.RESOLVED]: 'Resolved',
  [INCIDENT_STATUS.CLOSED]: 'Closed',
  [INCIDENT_STATUS.CANCELLED]: 'Cancelled',

  // Priority levels
  [INCIDENT_PRIORITY.LOW]: 'Low Priority',
  [INCIDENT_PRIORITY.MEDIUM]: 'Medium Priority',
  [INCIDENT_PRIORITY.HIGH]: 'High Priority',
  [INCIDENT_PRIORITY.CRITICAL]: 'Critical',
});

/**
 * Get display name for a status value
 * @param {string} status - Status value
 * @returns {string} Display name
 */
const getStatusDisplayName = (status) => {
  return STATUS_DISPLAY_NAMES[status] || status;
};

/**
 * Incident type display names and descriptions
 */
const INCIDENT_TYPE_INFO = Object.freeze({
  [INCIDENT_TYPE.ACCIDENT]: {
    displayName: 'Accident',
    description: 'Traffic accident or collision',
    icon: 'car-crash',
    defaultPriority: INCIDENT_PRIORITY.HIGH,
  },
  [INCIDENT_TYPE.THEFT]: {
    displayName: 'Theft',
    description: 'Vehicle or property theft',
    icon: 'theft',
    defaultPriority: INCIDENT_PRIORITY.HIGH,
  },
  [INCIDENT_TYPE.HARASSMENT]: {
    displayName: 'Harassment',
    description: 'Road rage or harassment incident',
    icon: 'warning',
    defaultPriority: INCIDENT_PRIORITY.MEDIUM,
  },
  [INCIDENT_TYPE.ROAD_HAZARD]: {
    displayName: 'Road Hazard',
    description: 'Dangerous road conditions or obstacles',
    icon: 'road',
    defaultPriority: INCIDENT_PRIORITY.MEDIUM,
  },
  [INCIDENT_TYPE.VEHICLE_BREAKDOWN]: {
    displayName: 'Vehicle Breakdown',
    description: 'Mechanical failure or breakdown',
    icon: 'tools',
    defaultPriority: INCIDENT_PRIORITY.LOW,
  },
  [INCIDENT_TYPE.TRAFFIC_VIOLATION]: {
    displayName: 'Traffic Violation',
    description: 'Witnessed traffic violation',
    icon: 'traffic-light',
    defaultPriority: INCIDENT_PRIORITY.LOW,
  },
  [INCIDENT_TYPE.EMERGENCY]: {
    displayName: 'Emergency',
    description: 'Life-threatening emergency',
    icon: 'emergency',
    defaultPriority: INCIDENT_PRIORITY.CRITICAL,
  },
  [INCIDENT_TYPE.OTHER]: {
    displayName: 'Other',
    description: 'Other type of incident',
    icon: 'info',
    defaultPriority: INCIDENT_PRIORITY.LOW,
  },
});

/**
 * Get incident type info
 * @param {string} type - Incident type
 * @returns {Object} Type info object
 */
const getIncidentTypeInfo = (type) => {
  return INCIDENT_TYPE_INFO[type] || INCIDENT_TYPE_INFO[INCIDENT_TYPE.OTHER];
};

/**
 * Status transition rules for incidents
 * Defines which statuses can transition to which
 */
const INCIDENT_STATUS_TRANSITIONS = Object.freeze({
  [INCIDENT_STATUS.PENDING]: [INCIDENT_STATUS.IN_PROGRESS, INCIDENT_STATUS.CANCELLED],
  [INCIDENT_STATUS.IN_PROGRESS]: [INCIDENT_STATUS.RESOLVED, INCIDENT_STATUS.PENDING, INCIDENT_STATUS.CANCELLED],
  [INCIDENT_STATUS.RESOLVED]: [INCIDENT_STATUS.CLOSED, INCIDENT_STATUS.IN_PROGRESS],
  [INCIDENT_STATUS.CLOSED]: [], // Final state
  [INCIDENT_STATUS.CANCELLED]: [], // Final state
});

/**
 * Check if status transition is valid
 * @param {string} currentStatus - Current status
 * @param {string} newStatus - New status to transition to
 * @returns {boolean} True if transition is valid
 */
const isValidStatusTransition = (currentStatus, newStatus) => {
  const allowedTransitions = INCIDENT_STATUS_TRANSITIONS[currentStatus];
  if (!allowedTransitions) return false;
  return allowedTransitions.includes(newStatus);
};

/**
 * Get allowed status transitions
 * @param {string} currentStatus - Current status
 * @returns {string[]} Array of allowed next statuses
 */
const getAllowedTransitions = (currentStatus) => {
  return INCIDENT_STATUS_TRANSITIONS[currentStatus] || [];
};

module.exports = {
  // Status constants
  USER_STATUS,
  INCIDENT_STATUS,
  INCIDENT_PRIORITY,
  INCIDENT_TYPE,
  NOTIFICATION_STATUS,
  ATTACHMENT_TYPE,
  TOKEN_STATUS,

  // Helper functions
  getStatusValues,
  isValidStatus,
  getStatusDisplayName,
  getIncidentTypeInfo,
  isValidStatusTransition,
  getAllowedTransitions,

  // Info objects
  STATUS_DISPLAY_NAMES,
  INCIDENT_TYPE_INFO,
  INCIDENT_STATUS_TRANSITIONS,
};
