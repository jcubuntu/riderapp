'use strict';

const express = require('express');
const router = express.Router();
const emergencyController = require('./emergency.controller');
const { authenticate } = require('../../middleware/auth.middleware');
const { adminOnly, policeOrAdmin, volunteerOrHigher } = require('../../middleware/role.middleware');
const {
  validate,
  listContactsSchema,
  listContactsAdminSchema,
  contactIdSchema,
  createContactSchema,
  updateContactSchema,
  triggerSosSchema,
  resolveSosSchema,
  sosIdSchema,
} = require('./emergency.validation');

/**
 * Emergency Routes
 *
 * Emergency Contacts:
 *   GET    /emergency/contacts          - List active contacts (any authenticated)
 *   GET    /emergency/contacts/admin    - List all contacts with filters (admin+)
 *   GET    /emergency/contacts/stats    - Get contact statistics (admin+)
 *   GET    /emergency/contacts/:id      - Get contact by ID (admin+)
 *   POST   /emergency/contacts          - Create contact (admin+)
 *   PUT    /emergency/contacts/:id      - Update contact (admin+)
 *   DELETE /emergency/contacts/:id      - Delete contact (admin+)
 *
 * SOS Alerts:
 *   POST   /emergency/sos               - Trigger SOS alert (any authenticated)
 *   DELETE /emergency/sos               - Cancel SOS alert (any authenticated)
 *   GET    /emergency/sos/status        - Check SOS status (any authenticated)
 *   GET    /emergency/sos/active        - List all active SOS (police+)
 *   GET    /emergency/sos/stats         - Get SOS statistics (volunteer+)
 *   POST   /emergency/sos/:id/resolve   - Resolve SOS alert (police+)
 */

// ==================== Emergency Contacts Routes ====================

/**
 * @route   GET /api/v1/emergency/contacts
 * @desc    List active emergency contacts (public for authenticated users)
 * @access  Any authenticated user
 * @query   {category?, province?}
 */
router.get(
  '/contacts',
  authenticate,
  validate(listContactsSchema, 'query'),
  emergencyController.getContacts
);

/**
 * @route   GET /api/v1/emergency/contacts/admin
 * @desc    List all emergency contacts with pagination and filters
 * @access  Admin+
 * @query   {page, limit, search, category, province, isActive, isNationwide, is24Hours, sortBy, sortOrder}
 */
router.get(
  '/contacts/admin',
  authenticate,
  adminOnly,
  validate(listContactsAdminSchema, 'query'),
  emergencyController.getContactsAdmin
);

/**
 * @route   GET /api/v1/emergency/contacts/stats
 * @desc    Get emergency contact statistics by category
 * @access  Admin+
 */
router.get(
  '/contacts/stats',
  authenticate,
  adminOnly,
  emergencyController.getContactStats
);

/**
 * @route   GET /api/v1/emergency/contacts/:id
 * @desc    Get emergency contact by ID
 * @access  Admin+
 * @params  {id} - Contact UUID
 */
router.get(
  '/contacts/:id',
  authenticate,
  adminOnly,
  validate(contactIdSchema, 'params'),
  emergencyController.getContactById
);

/**
 * @route   POST /api/v1/emergency/contacts
 * @desc    Create a new emergency contact
 * @access  Admin+
 * @body    {name, phone, phoneSecondary?, email?, category?, description?, address?, province?, district?, locationLat?, locationLng?, operatingHours?, is24Hours?, isActive?, isNationwide?, priority?, iconUrl?}
 */
router.post(
  '/contacts',
  authenticate,
  adminOnly,
  validate(createContactSchema, 'body'),
  emergencyController.createContact
);

/**
 * @route   PUT /api/v1/emergency/contacts/:id
 * @desc    Update an emergency contact
 * @access  Admin+
 * @params  {id} - Contact UUID
 * @body    {name?, phone?, phoneSecondary?, email?, category?, description?, address?, province?, district?, locationLat?, locationLng?, operatingHours?, is24Hours?, isActive?, isNationwide?, priority?, iconUrl?}
 */
router.put(
  '/contacts/:id',
  authenticate,
  adminOnly,
  validate(contactIdSchema, 'params'),
  validate(updateContactSchema, 'body'),
  emergencyController.updateContact
);

/**
 * @route   DELETE /api/v1/emergency/contacts/:id
 * @desc    Delete an emergency contact
 * @access  Admin+
 * @params  {id} - Contact UUID
 */
router.delete(
  '/contacts/:id',
  authenticate,
  adminOnly,
  validate(contactIdSchema, 'params'),
  emergencyController.deleteContact
);

// ==================== SOS Alert Routes ====================

/**
 * @route   POST /api/v1/emergency/sos
 * @desc    Trigger a new SOS alert
 * @access  Any authenticated user
 * @body    {latitude?, longitude?, message?}
 */
router.post(
  '/sos',
  authenticate,
  validate(triggerSosSchema, 'body'),
  emergencyController.triggerSos
);

/**
 * @route   DELETE /api/v1/emergency/sos
 * @desc    Cancel current user's SOS alert
 * @access  Any authenticated user
 */
router.delete(
  '/sos',
  authenticate,
  emergencyController.cancelSos
);

/**
 * @route   GET /api/v1/emergency/sos/status
 * @desc    Get current user's SOS status
 * @access  Any authenticated user
 */
router.get(
  '/sos/status',
  authenticate,
  emergencyController.getSosStatus
);

/**
 * @route   GET /api/v1/emergency/sos/active
 * @desc    Get all active SOS alerts (for responders)
 * @access  Police+
 */
router.get(
  '/sos/active',
  authenticate,
  policeOrAdmin,
  emergencyController.getAllActiveSos
);

/**
 * @route   GET /api/v1/emergency/sos/stats
 * @desc    Get SOS statistics
 * @access  Volunteer+
 */
router.get(
  '/sos/stats',
  authenticate,
  volunteerOrHigher,
  emergencyController.getSosStats
);

/**
 * @route   POST /api/v1/emergency/sos/:id/resolve
 * @desc    Resolve an SOS alert
 * @access  Police+
 * @params  {id} - SOS alert UUID
 * @body    {notes?}
 */
router.post(
  '/sos/:id/resolve',
  authenticate,
  policeOrAdmin,
  validate(sosIdSchema, 'params'),
  validate(resolveSosSchema, 'body'),
  emergencyController.resolveSos
);

module.exports = router;
