'use strict';

const statsRepository = require('./stats.repository');

/**
 * Stats Service - Business logic for statistics
 */

/**
 * Get dashboard overview statistics
 * @param {Object} options - Query options
 * @returns {Promise<Object>}
 */
const getDashboardStats = async (options = {}) => {
  const { recentLimit = 5 } = options;

  // Execute all queries in parallel for better performance
  const [
    totalUsers,
    totalIncidents,
    pendingApprovals,
    activeIncidents,
    resolvedToday,
    recentIncidents,
    recentUsers,
  ] = await Promise.all([
    statsRepository.getTotalUsers(),
    statsRepository.getTotalIncidents(),
    statsRepository.getPendingApprovalsCount(),
    statsRepository.getActiveIncidentsCount(),
    statsRepository.getResolvedTodayCount(),
    statsRepository.getRecentIncidents(recentLimit),
    statsRepository.getRecentUsers(recentLimit),
  ]);

  return {
    totalUsers,
    totalIncidents,
    pendingApprovals,
    activeIncidents,
    resolvedToday,
    recentIncidents: recentIncidents.map(formatIncident),
    recentUsers: recentUsers.map(formatUser),
  };
};

/**
 * Get incident summary statistics
 * @param {Object} options - Query options
 * @returns {Promise<Object>}
 */
const getIncidentSummary = async (options = {}) => {
  const { startDate, endDate } = options;

  const summary = await statsRepository.getIncidentSummary({ startDate, endDate });
  const avgResolutionTime = await statsRepository.getAverageResolutionTime({ startDate, endDate });

  return {
    ...summary,
    averageResolutionTimeHours: avgResolutionTime,
  };
};

/**
 * Get incidents grouped by type
 * @param {Object} options - Query options
 * @returns {Promise<Object>}
 */
const getIncidentsByType = async (options = {}) => {
  const { startDate, endDate } = options;

  const data = await statsRepository.getIncidentsByType({ startDate, endDate });

  // Calculate total for percentage
  const total = data.reduce((sum, item) => sum + item.count, 0);

  return {
    data: data.map(item => ({
      ...item,
      percentage: total > 0 ? Math.round((item.count / total) * 1000) / 10 : 0,
    })),
    total,
  };
};

/**
 * Get incidents grouped by status
 * @param {Object} options - Query options
 * @returns {Promise<Object>}
 */
const getIncidentsByStatus = async (options = {}) => {
  const { startDate, endDate } = options;

  const data = await statsRepository.getIncidentsByStatus({ startDate, endDate });

  // Calculate total for percentage
  const total = data.reduce((sum, item) => sum + item.count, 0);

  return {
    data: data.map(item => ({
      ...item,
      percentage: total > 0 ? Math.round((item.count / total) * 1000) / 10 : 0,
    })),
    total,
  };
};

/**
 * Get incidents grouped by priority
 * @param {Object} options - Query options
 * @returns {Promise<Object>}
 */
const getIncidentsByPriority = async (options = {}) => {
  const { startDate, endDate } = options;

  const data = await statsRepository.getIncidentsByPriority({ startDate, endDate });

  // Calculate total for percentage
  const total = data.reduce((sum, item) => sum + item.count, 0);

  return {
    data: data.map(item => ({
      ...item,
      percentage: total > 0 ? Math.round((item.count / total) * 1000) / 10 : 0,
    })),
    total,
  };
};

/**
 * Get incident trend over time
 * @param {Object} options - Query options
 * @returns {Promise<Object>}
 */
const getIncidentTrend = async (options = {}) => {
  const { startDate, endDate, interval = 'daily' } = options;

  // Default to last 30 days if no dates provided
  const effectiveStartDate = startDate || getDefaultStartDate(interval);
  const effectiveEndDate = endDate || new Date().toISOString().split('T')[0];

  const data = await statsRepository.getIncidentTrend({
    startDate: effectiveStartDate,
    endDate: effectiveEndDate,
    interval,
  });

  // Calculate totals
  const totalIncidents = data.reduce((sum, item) => sum + item.count, 0);
  const totalResolved = data.reduce((sum, item) => sum + item.resolved, 0);

  return {
    data,
    summary: {
      totalIncidents,
      totalResolved,
      resolutionRate: totalIncidents > 0 ? Math.round((totalResolved / totalIncidents) * 1000) / 10 : 0,
    },
    period: {
      startDate: effectiveStartDate,
      endDate: effectiveEndDate,
      interval,
    },
  };
};

/**
 * Get incidents by province (top locations)
 * @param {Object} options - Query options
 * @returns {Promise<Object>}
 */
const getIncidentsByProvince = async (options = {}) => {
  const { startDate, endDate, limit = 10 } = options;

  const data = await statsRepository.getIncidentsByProvince({ startDate, endDate, limit });

  // Calculate total for percentage
  const total = data.reduce((sum, item) => sum + Number(item.count), 0);

  return {
    data: data.map(item => ({
      province: item.province,
      count: Number(item.count),
      percentage: total > 0 ? Math.round((Number(item.count) / total) * 1000) / 10 : 0,
    })),
    total,
  };
};

/**
 * Get user summary statistics
 * @returns {Promise<Object>}
 */
const getUserSummary = async () => {
  const summary = await statsRepository.getUserSummary();

  return {
    ...summary,
    activeRate: summary.total > 0 ?
      Math.round((summary.approved / summary.total) * 1000) / 10 : 0,
  };
};

/**
 * Get users grouped by role
 * @param {Object} options - Query options
 * @returns {Promise<Object>}
 */
const getUsersByRole = async (options = {}) => {
  const data = await statsRepository.getUsersByRole(options);

  // Calculate total for percentage
  const total = data.reduce((sum, item) => sum + item.count, 0);

  return {
    data: data.map(item => ({
      ...item,
      percentage: total > 0 ? Math.round((item.count / total) * 1000) / 10 : 0,
    })),
    total,
  };
};

/**
 * Get users grouped by status
 * @returns {Promise<Object>}
 */
const getUsersByStatus = async () => {
  const data = await statsRepository.getUsersByStatus();

  // Calculate total for percentage
  const total = data.reduce((sum, item) => sum + item.count, 0);

  return {
    data: data.map(item => ({
      ...item,
      percentage: total > 0 ? Math.round((item.count / total) * 1000) / 10 : 0,
    })),
    total,
  };
};

/**
 * Get user registration trend over time
 * @param {Object} options - Query options
 * @returns {Promise<Object>}
 */
const getUserRegistrationTrend = async (options = {}) => {
  const { startDate, endDate, interval = 'daily' } = options;

  // Default to last 30 days if no dates provided
  const effectiveStartDate = startDate || getDefaultStartDate(interval);
  const effectiveEndDate = endDate || new Date().toISOString().split('T')[0];

  const data = await statsRepository.getUserRegistrationTrend({
    startDate: effectiveStartDate,
    endDate: effectiveEndDate,
    interval,
  });

  // Calculate total
  const totalRegistrations = data.reduce((sum, item) => sum + Number(item.count), 0);

  return {
    data: data.map(item => ({
      period: item.period,
      count: Number(item.count),
    })),
    summary: {
      totalRegistrations,
    },
    period: {
      startDate: effectiveStartDate,
      endDate: effectiveEndDate,
      interval,
    },
  };
};

// ============= Helper Functions =============

/**
 * Get default start date based on interval
 * @param {string} interval - Time interval
 * @returns {string} ISO date string
 */
const getDefaultStartDate = (interval) => {
  const now = new Date();
  switch (interval) {
    case 'monthly':
      now.setMonth(now.getMonth() - 12); // Last 12 months
      break;
    case 'weekly':
      now.setDate(now.getDate() - 84); // Last 12 weeks
      break;
    case 'daily':
    default:
      now.setDate(now.getDate() - 30); // Last 30 days
      break;
  }
  return now.toISOString().split('T')[0];
};

/**
 * Format incident object for response
 * @param {Object} incident - Incident from database
 * @returns {Object}
 */
const formatIncident = (incident) => {
  if (!incident) return null;

  return {
    id: incident.id,
    title: incident.title,
    category: incident.category,
    status: incident.status,
    priority: incident.priority,
    location: {
      address: incident.location_address,
      province: incident.location_province,
      district: incident.location_district,
    },
    isAnonymous: incident.is_anonymous === 1 || incident.is_anonymous === true,
    reporter: incident.is_anonymous ? null : {
      id: incident.reporter_id,
      fullName: incident.reporter_name,
      role: incident.reporter_role,
    },
    createdAt: incident.created_at,
    updatedAt: incident.updated_at,
  };
};

/**
 * Format user object for response
 * @param {Object} user - User from database
 * @returns {Object}
 */
const formatUser = (user) => {
  if (!user) return null;

  return {
    id: user.id,
    email: user.email,
    phone: user.phone,
    fullName: user.full_name,
    role: user.role,
    status: user.status,
    affiliation: user.affiliation,
    profileImageUrl: user.profile_image_url,
    createdAt: user.created_at,
  };
};

module.exports = {
  getDashboardStats,
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
