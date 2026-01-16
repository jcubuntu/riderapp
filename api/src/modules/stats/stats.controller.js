'use strict';

const statsService = require('./stats.service');
const {
  successResponse,
  badRequestResponse,
} = require('../../utils/response.utils');

/**
 * Stats Controller - Handle HTTP requests for statistics
 */

/**
 * Get dashboard overview statistics
 * GET /stats/dashboard
 */
const getDashboard = async (req, res) => {
  try {
    const { recentLimit } = req.query;

    const stats = await statsService.getDashboardStats({
      recentLimit: recentLimit ? parseInt(recentLimit, 10) : 5,
    });

    return successResponse(res, stats, 'Dashboard statistics retrieved successfully');
  } catch (error) {
    console.error('Get dashboard stats error:', error);
    return badRequestResponse(res, 'Failed to retrieve dashboard statistics');
  }
};

/**
 * Get incident summary statistics
 * GET /stats/incidents/summary
 */
const getIncidentSummary = async (req, res) => {
  try {
    const { startDate, endDate } = req.query;

    const stats = await statsService.getIncidentSummary({ startDate, endDate });

    return successResponse(res, stats, 'Incident summary retrieved successfully');
  } catch (error) {
    console.error('Get incident summary error:', error);
    return badRequestResponse(res, 'Failed to retrieve incident summary');
  }
};

/**
 * Get incidents grouped by type
 * GET /stats/incidents/by-type
 */
const getIncidentsByType = async (req, res) => {
  try {
    const { startDate, endDate } = req.query;

    const stats = await statsService.getIncidentsByType({ startDate, endDate });

    return successResponse(res, stats, 'Incidents by type retrieved successfully');
  } catch (error) {
    console.error('Get incidents by type error:', error);
    return badRequestResponse(res, 'Failed to retrieve incidents by type');
  }
};

/**
 * Get incidents grouped by status
 * GET /stats/incidents/by-status
 */
const getIncidentsByStatus = async (req, res) => {
  try {
    const { startDate, endDate } = req.query;

    const stats = await statsService.getIncidentsByStatus({ startDate, endDate });

    return successResponse(res, stats, 'Incidents by status retrieved successfully');
  } catch (error) {
    console.error('Get incidents by status error:', error);
    return badRequestResponse(res, 'Failed to retrieve incidents by status');
  }
};

/**
 * Get incidents grouped by priority
 * GET /stats/incidents/by-priority
 */
const getIncidentsByPriority = async (req, res) => {
  try {
    const { startDate, endDate } = req.query;

    const stats = await statsService.getIncidentsByPriority({ startDate, endDate });

    return successResponse(res, stats, 'Incidents by priority retrieved successfully');
  } catch (error) {
    console.error('Get incidents by priority error:', error);
    return badRequestResponse(res, 'Failed to retrieve incidents by priority');
  }
};

/**
 * Get incident trend over time
 * GET /stats/incidents/trend
 */
const getIncidentTrend = async (req, res) => {
  try {
    const { startDate, endDate, interval } = req.query;

    const stats = await statsService.getIncidentTrend({ startDate, endDate, interval });

    return successResponse(res, stats, 'Incident trend retrieved successfully');
  } catch (error) {
    console.error('Get incident trend error:', error);
    return badRequestResponse(res, 'Failed to retrieve incident trend');
  }
};

/**
 * Get incidents grouped by province
 * GET /stats/incidents/by-province
 */
const getIncidentsByProvince = async (req, res) => {
  try {
    const { startDate, endDate, limit } = req.query;

    const stats = await statsService.getIncidentsByProvince({
      startDate,
      endDate,
      limit: limit ? parseInt(limit, 10) : 10,
    });

    return successResponse(res, stats, 'Incidents by province retrieved successfully');
  } catch (error) {
    console.error('Get incidents by province error:', error);
    return badRequestResponse(res, 'Failed to retrieve incidents by province');
  }
};

/**
 * Get user summary statistics
 * GET /stats/users/summary
 */
const getUserSummary = async (req, res) => {
  try {
    const stats = await statsService.getUserSummary();

    return successResponse(res, stats, 'User summary retrieved successfully');
  } catch (error) {
    console.error('Get user summary error:', error);
    return badRequestResponse(res, 'Failed to retrieve user summary');
  }
};

/**
 * Get users grouped by role
 * GET /stats/users/by-role
 */
const getUsersByRole = async (req, res) => {
  try {
    const { status } = req.query;

    const stats = await statsService.getUsersByRole({ status });

    return successResponse(res, stats, 'Users by role retrieved successfully');
  } catch (error) {
    console.error('Get users by role error:', error);
    return badRequestResponse(res, 'Failed to retrieve users by role');
  }
};

/**
 * Get users grouped by status
 * GET /stats/users/by-status
 */
const getUsersByStatus = async (req, res) => {
  try {
    const stats = await statsService.getUsersByStatus();

    return successResponse(res, stats, 'Users by status retrieved successfully');
  } catch (error) {
    console.error('Get users by status error:', error);
    return badRequestResponse(res, 'Failed to retrieve users by status');
  }
};

/**
 * Get user registration trend over time
 * GET /stats/users/trend
 */
const getUserRegistrationTrend = async (req, res) => {
  try {
    const { startDate, endDate, interval } = req.query;

    const stats = await statsService.getUserRegistrationTrend({ startDate, endDate, interval });

    return successResponse(res, stats, 'User registration trend retrieved successfully');
  } catch (error) {
    console.error('Get user registration trend error:', error);
    return badRequestResponse(res, 'Failed to retrieve user registration trend');
  }
};

module.exports = {
  getDashboard,
  getIncidentSummary,
  getIncidentsByType,
  getIncidentsByStatus,
  getIncidentsByPriority,
  getIncidentTrend,
  getIncidentsByProvince,
  getUserSummary,
  getUsersByRole,
  getUsersByStatus,
  getUserRegistrationTrend,
};
