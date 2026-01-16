'use strict';

const emergencyRepository = require('./emergency.repository');
const { ROLES, hasMinimumRole } = require('../../constants/roles');

/**
 * Emergency Service - Business logic for emergency contacts and SOS
 */

// ==================== Emergency Contacts ====================

/**
 * Get all emergency contacts with pagination and filtering (admin view)
 * @param {Object} options - Query options
 * @returns {Promise<Object>}
 */
const getContacts = async (options = {}) => {
  const { contacts, total } = await emergencyRepository.findAllContacts(options);

  return {
    contacts: contacts.map(formatContact),
    total,
    page: options.page || 1,
    limit: options.limit || 20,
  };
};

/**
 * Get active emergency contacts (public view)
 * @param {Object} options - Query options
 * @returns {Promise<Array>}
 */
const getActiveContacts = async (options = {}) => {
  const contacts = await emergencyRepository.findActiveContacts(options);
  return contacts.map(formatContactPublic);
};

/**
 * Get emergency contact by ID
 * @param {string} id - Contact UUID
 * @returns {Promise<Object|null>}
 */
const getContactById = async (id) => {
  const contact = await emergencyRepository.findContactById(id);
  if (!contact) {
    return null;
  }
  return formatContact(contact);
};

/**
 * Create a new emergency contact
 * @param {Object} data - Contact data
 * @param {Object} currentUser - User creating the contact
 * @returns {Promise<Object>}
 */
const createContact = async (data, currentUser) => {
  // Validate admin permission
  if (!hasMinimumRole(currentUser.role, ROLES.ADMIN)) {
    throw new Error('ACCESS_DENIED');
  }

  // Validate required fields
  if (!data.name || !data.phone) {
    throw new Error('MISSING_REQUIRED_FIELDS');
  }

  // Validate category if provided
  const validCategories = ['police', 'hospital', 'fire', 'rescue', 'hotline', 'government', 'other'];
  if (data.category && !validCategories.includes(data.category)) {
    throw new Error('INVALID_CATEGORY');
  }

  const contact = await emergencyRepository.createContact(data, currentUser.id);
  return formatContact(contact);
};

/**
 * Update an emergency contact
 * @param {string} id - Contact UUID
 * @param {Object} updates - Fields to update
 * @param {Object} currentUser - User updating the contact
 * @returns {Promise<Object>}
 */
const updateContact = async (id, updates, currentUser) => {
  // Validate admin permission
  if (!hasMinimumRole(currentUser.role, ROLES.ADMIN)) {
    throw new Error('ACCESS_DENIED');
  }

  // Check if contact exists
  const existingContact = await emergencyRepository.findContactById(id);
  if (!existingContact) {
    throw new Error('CONTACT_NOT_FOUND');
  }

  // Validate category if provided
  const validCategories = ['police', 'hospital', 'fire', 'rescue', 'hotline', 'government', 'other'];
  if (updates.category && !validCategories.includes(updates.category)) {
    throw new Error('INVALID_CATEGORY');
  }

  const contact = await emergencyRepository.updateContact(id, updates, currentUser.id);
  return formatContact(contact);
};

/**
 * Delete an emergency contact
 * @param {string} id - Contact UUID
 * @param {Object} currentUser - User deleting the contact
 * @returns {Promise<boolean>}
 */
const deleteContact = async (id, currentUser) => {
  // Validate admin permission
  if (!hasMinimumRole(currentUser.role, ROLES.ADMIN)) {
    throw new Error('ACCESS_DENIED');
  }

  // Check if contact exists
  const existingContact = await emergencyRepository.findContactById(id);
  if (!existingContact) {
    throw new Error('CONTACT_NOT_FOUND');
  }

  const result = await emergencyRepository.deleteContact(id);
  return result.affectedRows > 0;
};

/**
 * Get emergency contact statistics
 * @returns {Promise<Object>}
 */
const getContactStats = async () => {
  return emergencyRepository.getContactCountByCategory();
};

// ==================== SOS Alerts ====================

/**
 * Trigger SOS alert
 * @param {Object} data - SOS data (latitude, longitude, message)
 * @param {Object} currentUser - User triggering SOS
 * @returns {Object}
 */
const triggerSos = (data, currentUser) => {
  // Check if user already has an active SOS
  const existingSos = emergencyRepository.getSosAlertByUserId(currentUser.id);
  if (existingSos && existingSos.status === 'active') {
    // Update location if SOS already exists
    if (data.latitude && data.longitude) {
      const updated = emergencyRepository.updateSosAlertLocation(
        currentUser.id,
        data.latitude,
        data.longitude
      );
      if (updated) {
        return formatSosAlert(updated, currentUser);
      }
    }
    return formatSosAlert(existingSos, currentUser);
  }

  const alert = emergencyRepository.createSosAlert({
    userId: currentUser.id,
    latitude: data.latitude || null,
    longitude: data.longitude || null,
    message: data.message || null,
  });

  return formatSosAlert(alert, currentUser);
};

/**
 * Cancel SOS alert
 * @param {Object} currentUser - User cancelling SOS
 * @returns {Object|null}
 */
const cancelSos = (currentUser) => {
  const alert = emergencyRepository.cancelSosAlert(currentUser.id);
  if (!alert) {
    throw new Error('NO_ACTIVE_SOS');
  }
  return formatSosAlert(alert, currentUser);
};

/**
 * Get SOS status for current user
 * @param {Object} currentUser - Current user
 * @returns {Object}
 */
const getSosStatus = (currentUser) => {
  const alert = emergencyRepository.getSosAlertByUserId(currentUser.id);
  if (!alert) {
    return {
      hasActiveSos: false,
      sos: null,
    };
  }
  return {
    hasActiveSos: alert.status === 'active',
    sos: formatSosAlert(alert, currentUser),
  };
};

/**
 * Get all active SOS alerts (for police+ users)
 * @param {Object} currentUser - Current user
 * @returns {Array}
 */
const getAllActiveSos = (currentUser) => {
  // Only police+ can view all active SOS alerts
  if (!hasMinimumRole(currentUser.role, ROLES.POLICE)) {
    throw new Error('ACCESS_DENIED');
  }

  const alerts = emergencyRepository.getAllActiveSosAlerts();
  return alerts.map(alert => formatSosAlertForResponder(alert));
};

/**
 * Resolve SOS alert (for police+ users)
 * @param {string} alertId - Alert UUID
 * @param {string} notes - Resolution notes
 * @param {Object} currentUser - Current user (responder)
 * @returns {Object}
 */
const resolveSos = (alertId, notes, currentUser) => {
  // Only police+ can resolve SOS alerts
  if (!hasMinimumRole(currentUser.role, ROLES.POLICE)) {
    throw new Error('ACCESS_DENIED');
  }

  // Check if alert exists
  const existingAlert = emergencyRepository.getSosAlertById(alertId);
  if (!existingAlert) {
    throw new Error('SOS_NOT_FOUND');
  }

  if (existingAlert.status !== 'active') {
    throw new Error('SOS_NOT_ACTIVE');
  }

  const resolved = emergencyRepository.resolveSosAlert(alertId, currentUser.id, notes);
  if (!resolved) {
    throw new Error('RESOLVE_FAILED');
  }

  return formatSosAlertForResponder(resolved);
};

/**
 * Get SOS statistics
 * @param {Object} currentUser - Current user
 * @returns {Object}
 */
const getSosStats = (currentUser) => {
  // Only volunteer+ can view SOS stats
  if (!hasMinimumRole(currentUser.role, ROLES.VOLUNTEER)) {
    throw new Error('ACCESS_DENIED');
  }

  return emergencyRepository.getSosAlertStats();
};

// ==================== Formatters ====================

/**
 * Format emergency contact for response (admin view)
 * @param {Object} contact - Contact from database
 * @returns {Object}
 */
const formatContact = (contact) => {
  if (!contact) return null;

  return {
    id: contact.id,
    name: contact.name,
    phone: contact.phone,
    phoneSecondary: contact.phone_secondary,
    email: contact.email,
    category: contact.category,
    description: contact.description,
    address: contact.address,
    province: contact.province,
    district: contact.district,
    location: contact.location_lat && contact.location_lng ? {
      latitude: parseFloat(contact.location_lat),
      longitude: parseFloat(contact.location_lng),
    } : null,
    operatingHours: contact.operating_hours,
    is24Hours: Boolean(contact.is_24_hours),
    isActive: Boolean(contact.is_active),
    isNationwide: Boolean(contact.is_nationwide),
    priority: contact.priority,
    iconUrl: contact.icon_url,
    createdBy: contact.created_by,
    updatedBy: contact.updated_by,
    createdAt: contact.created_at,
    updatedAt: contact.updated_at,
  };
};

/**
 * Format emergency contact for public response
 * @param {Object} contact - Contact from database
 * @returns {Object}
 */
const formatContactPublic = (contact) => {
  if (!contact) return null;

  return {
    id: contact.id,
    name: contact.name,
    phone: contact.phone,
    phoneSecondary: contact.phone_secondary,
    category: contact.category,
    description: contact.description,
    address: contact.address,
    province: contact.province,
    district: contact.district,
    location: contact.location_lat && contact.location_lng ? {
      latitude: parseFloat(contact.location_lat),
      longitude: parseFloat(contact.location_lng),
    } : null,
    operatingHours: contact.operating_hours,
    is24Hours: Boolean(contact.is_24_hours),
    isNationwide: Boolean(contact.is_nationwide),
    priority: contact.priority,
    iconUrl: contact.icon_url,
  };
};

/**
 * Format SOS alert for user response
 * @param {Object} alert - SOS alert
 * @param {Object} user - User object
 * @returns {Object}
 */
const formatSosAlert = (alert, user) => {
  if (!alert) return null;

  return {
    id: alert.id,
    status: alert.status,
    location: alert.latitude && alert.longitude ? {
      latitude: alert.latitude,
      longitude: alert.longitude,
    } : null,
    message: alert.message,
    triggeredAt: alert.triggeredAt,
    cancelledAt: alert.cancelledAt || null,
    resolvedAt: alert.resolvedAt || null,
    lastUpdatedAt: alert.lastUpdatedAt || null,
  };
};

/**
 * Format SOS alert for responder view (includes user info)
 * @param {Object} alert - SOS alert
 * @returns {Object}
 */
const formatSosAlertForResponder = (alert) => {
  if (!alert) return null;

  return {
    id: alert.id,
    userId: alert.userId,
    status: alert.status,
    location: alert.latitude && alert.longitude ? {
      latitude: alert.latitude,
      longitude: alert.longitude,
    } : null,
    message: alert.message,
    triggeredAt: alert.triggeredAt,
    cancelledAt: alert.cancelledAt || null,
    resolvedAt: alert.resolvedAt || null,
    resolvedBy: alert.resolvedBy || null,
    resolutionNotes: alert.resolutionNotes || null,
    lastUpdatedAt: alert.lastUpdatedAt || null,
  };
};

module.exports = {
  // Emergency Contacts
  getContacts,
  getActiveContacts,
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
