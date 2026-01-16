'use strict';

const express = require('express');
const router = express.Router();
const statsController = require('./stats.controller');
const { authenticate } = require('../../middleware/auth.middleware');
const {
  adminOnly,
  volunteerOrHigher,
} = require('../../middleware/role.middleware');
const {
  validate,
  dashboardSchema,
  incidentSummarySchema,
  incidentsByTypeSchema,
  incidentsByStatusSchema,
  incidentsByPrioritySchema,
  incidentTrendSchema,
  incidentsByProvinceSchema,
  usersByRoleSchema,
  userTrendSchema,
} = require('./stats.validation');

/**
 * Stats Routes
 *
 * All routes require authentication
 *
 * Volunteer+ routes (volunteer, police, admin, super_admin):
 *   GET /stats/dashboard            - Dashboard overview
 *   GET /stats/incidents/summary    - Incident summary
 *   GET /stats/incidents/by-type    - Incidents by type
 *   GET /stats/incidents/by-status  - Incidents by status
 *   GET /stats/incidents/by-priority - Incidents by priority
 *   GET /stats/incidents/trend      - Incident trend over time
 *   GET /stats/incidents/by-province - Incidents by province
 *
 * Admin+ routes (admin, super_admin):
 *   GET /stats/users/summary        - User summary
 *   GET /stats/users/by-role        - Users by role
 *   GET /stats/users/by-status      - Users by status
 *   GET /stats/users/trend          - User registration trend
 */

// ============= Dashboard (Volunteer+) =============

/**
 * @route   GET /api/v1/stats/dashboard
 * @desc    Get dashboard overview statistics
 * @access  Volunteer+
 * @query   {recentLimit} - Number of recent items to return (default: 5, max: 20)
 */
router.get(
  '/dashboard',
  authenticate,
  volunteerOrHigher,
  validate(dashboardSchema, 'query'),
  statsController.getDashboard
);

// ============= Incident Statistics (Volunteer+) =============

/**
 * @route   GET /api/v1/stats/incidents/summary
 * @desc    Get incident summary statistics
 * @access  Volunteer+
 * @query   {startDate, endDate} - Date range filter (ISO format)
 */
router.get(
  '/incidents/summary',
  authenticate,
  volunteerOrHigher,
  validate(incidentSummarySchema, 'query'),
  statsController.getIncidentSummary
);

/**
 * @route   GET /api/v1/stats/incidents/by-type
 * @desc    Get incidents grouped by type (category)
 * @access  Volunteer+
 * @query   {startDate, endDate} - Date range filter (ISO format)
 */
router.get(
  '/incidents/by-type',
  authenticate,
  volunteerOrHigher,
  validate(incidentsByTypeSchema, 'query'),
  statsController.getIncidentsByType
);

/**
 * @route   GET /api/v1/stats/incidents/by-status
 * @desc    Get incidents grouped by status
 * @access  Volunteer+
 * @query   {startDate, endDate} - Date range filter (ISO format)
 */
router.get(
  '/incidents/by-status',
  authenticate,
  volunteerOrHigher,
  validate(incidentsByStatusSchema, 'query'),
  statsController.getIncidentsByStatus
);

/**
 * @route   GET /api/v1/stats/incidents/by-priority
 * @desc    Get incidents grouped by priority
 * @access  Volunteer+
 * @query   {startDate, endDate} - Date range filter (ISO format)
 */
router.get(
  '/incidents/by-priority',
  authenticate,
  volunteerOrHigher,
  validate(incidentsByPrioritySchema, 'query'),
  statsController.getIncidentsByPriority
);

/**
 * @route   GET /api/v1/stats/incidents/trend
 * @desc    Get incident trend over time
 * @access  Volunteer+
 * @query   {startDate, endDate, interval} - Date range and interval (daily/weekly/monthly)
 */
router.get(
  '/incidents/trend',
  authenticate,
  volunteerOrHigher,
  validate(incidentTrendSchema, 'query'),
  statsController.getIncidentTrend
);

/**
 * @route   GET /api/v1/stats/incidents/by-province
 * @desc    Get incidents grouped by province
 * @access  Volunteer+
 * @query   {startDate, endDate, limit} - Date range and result limit
 */
router.get(
  '/incidents/by-province',
  authenticate,
  volunteerOrHigher,
  validate(incidentsByProvinceSchema, 'query'),
  statsController.getIncidentsByProvince
);

// ============= User Statistics (Admin+) =============

/**
 * @route   GET /api/v1/stats/users/summary
 * @desc    Get user summary statistics
 * @access  Admin+
 */
router.get(
  '/users/summary',
  authenticate,
  adminOnly,
  statsController.getUserSummary
);

/**
 * @route   GET /api/v1/stats/users/by-role
 * @desc    Get users grouped by role
 * @access  Admin+
 * @query   {status} - Filter by user status (default: approved)
 */
router.get(
  '/users/by-role',
  authenticate,
  adminOnly,
  validate(usersByRoleSchema, 'query'),
  statsController.getUsersByRole
);

/**
 * @route   GET /api/v1/stats/users/by-status
 * @desc    Get users grouped by status
 * @access  Admin+
 */
router.get(
  '/users/by-status',
  authenticate,
  adminOnly,
  statsController.getUsersByStatus
);

/**
 * @route   GET /api/v1/stats/users/trend
 * @desc    Get user registration trend over time
 * @access  Admin+
 * @query   {startDate, endDate, interval} - Date range and interval (daily/weekly/monthly)
 */
router.get(
  '/users/trend',
  authenticate,
  adminOnly,
  validate(userTrendSchema, 'query'),
  statsController.getUserRegistrationTrend
);

module.exports = router;
