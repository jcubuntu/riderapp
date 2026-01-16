'use strict';

const express = require('express');
const router = express.Router();

// Import route modules
const authRoutes = require('../modules/auth/auth.routes');
const affiliationsRoutes = require('../modules/affiliations/affiliations.routes');
const usersRoutes = require('../modules/users/users.routes');
const notificationsRoutes = require('../modules/notifications/notifications.routes');
const announcementsRoutes = require('../modules/announcements/announcements.routes');
const statsRoutes = require('../modules/stats/stats.routes');
const emergencyRoutes = require('../modules/emergency/emergency.routes');
const incidentsRoutes = require('../modules/incidents/incidents.routes');
const chatRoutes = require('../modules/chat/chat.routes');
const locationsRoutes = require('../modules/locations/locations.routes');
const uploadsRoutes = require('../modules/uploads/uploads.routes');

// API welcome route
router.get('/', (req, res) => {
  res.json({
    success: true,
    message: 'Welcome to RiderApp API',
    version: process.env.API_VERSION || 'v1',
    documentation: '/api/v1/docs',
    endpoints: {
      auth: {
        register: 'POST /api/v1/auth/register',
        login: 'POST /api/v1/auth/login',
        refresh: 'POST /api/v1/auth/refresh',
        logout: 'POST /api/v1/auth/logout',
        me: 'GET /api/v1/auth/me',
        status: 'GET /api/v1/auth/status?userId=<uuid>',
        approvalStatus: 'GET /api/v1/auth/approval-status',
        profile: 'PATCH /api/v1/auth/profile',
        changePassword: 'POST /api/v1/auth/change-password',
        logoutAll: 'POST /api/v1/auth/logout-all',
        sessions: 'GET /api/v1/auth/sessions',
        deviceToken: 'POST /api/v1/auth/device-token',
      },
      users: {
        list: 'GET /api/v1/users',
        stats: 'GET /api/v1/users/stats',
        pending: 'GET /api/v1/users/pending',
        get: 'GET /api/v1/users/:id',
        update: 'PUT /api/v1/users/:id',
        delete: 'DELETE /api/v1/users/:id',
        updateStatus: 'PATCH /api/v1/users/:id/status',
        updateRole: 'PATCH /api/v1/users/:id/role',
        approve: 'POST /api/v1/users/:id/approve',
        reject: 'POST /api/v1/users/:id/reject',
      },
      incidents: {
        list: 'GET /api/v1/incidents',
        my: 'GET /api/v1/incidents/my',
        stats: 'GET /api/v1/incidents/stats',
        create: 'POST /api/v1/incidents',
        get: 'GET /api/v1/incidents/:id',
        update: 'PUT /api/v1/incidents/:id',
        delete: 'DELETE /api/v1/incidents/:id',
        updateStatus: 'PATCH /api/v1/incidents/:id/status',
        assign: 'POST /api/v1/incidents/:id/assign',
        unassign: 'DELETE /api/v1/incidents/:id/assign',
        attachments: 'GET /api/v1/incidents/:id/attachments',
        uploadAttachments: 'POST /api/v1/incidents/:id/attachments',
        deleteAttachment: 'DELETE /api/v1/incidents/:id/attachments/:attachmentId',
      },
      affiliations: {
        list: 'GET /api/v1/affiliations',
        listAdmin: 'GET /api/v1/affiliations/admin',
        get: 'GET /api/v1/affiliations/:id',
        create: 'POST /api/v1/affiliations',
        update: 'PUT /api/v1/affiliations/:id',
        delete: 'DELETE /api/v1/affiliations/:id',
        restore: 'POST /api/v1/affiliations/:id/restore',
      },
      notifications: {
        list: 'GET /api/v1/notifications',
        unreadCount: 'GET /api/v1/notifications/unread-count',
        readAll: 'PATCH /api/v1/notifications/read-all',
        get: 'GET /api/v1/notifications/:id',
        markRead: 'PATCH /api/v1/notifications/:id/read',
        delete: 'DELETE /api/v1/notifications/:id',
      },
      announcements: {
        list: 'GET /api/v1/announcements',
        listAdmin: 'GET /api/v1/announcements/admin',
        unreadCount: 'GET /api/v1/announcements/unread-count',
        stats: 'GET /api/v1/announcements/stats',
        get: 'GET /api/v1/announcements/:id',
        create: 'POST /api/v1/announcements',
        update: 'PUT /api/v1/announcements/:id',
        delete: 'DELETE /api/v1/announcements/:id',
        markRead: 'PATCH /api/v1/announcements/:id/read',
        publish: 'POST /api/v1/announcements/:id/publish',
        archive: 'POST /api/v1/announcements/:id/archive',
      },
      stats: {
        dashboard: 'GET /api/v1/stats/dashboard',
        incidentsSummary: 'GET /api/v1/stats/incidents/summary',
        incidentsByType: 'GET /api/v1/stats/incidents/by-type',
        incidentsByStatus: 'GET /api/v1/stats/incidents/by-status',
        incidentsByPriority: 'GET /api/v1/stats/incidents/by-priority',
        incidentsTrend: 'GET /api/v1/stats/incidents/trend',
        incidentsByProvince: 'GET /api/v1/stats/incidents/by-province',
        usersSummary: 'GET /api/v1/stats/users/summary',
        usersByRole: 'GET /api/v1/stats/users/by-role',
        usersByStatus: 'GET /api/v1/stats/users/by-status',
        usersTrend: 'GET /api/v1/stats/users/trend',
      },
      emergency: {
        contacts: 'GET /api/v1/emergency/contacts',
        contactsAdmin: 'GET /api/v1/emergency/contacts/admin',
        contactsStats: 'GET /api/v1/emergency/contacts/stats',
        contactGet: 'GET /api/v1/emergency/contacts/:id',
        contactCreate: 'POST /api/v1/emergency/contacts',
        contactUpdate: 'PUT /api/v1/emergency/contacts/:id',
        contactDelete: 'DELETE /api/v1/emergency/contacts/:id',
        sosTrigger: 'POST /api/v1/emergency/sos',
        sosCancel: 'DELETE /api/v1/emergency/sos',
        sosStatus: 'GET /api/v1/emergency/sos/status',
        sosActive: 'GET /api/v1/emergency/sos/active',
        sosStats: 'GET /api/v1/emergency/sos/stats',
        sosResolve: 'POST /api/v1/emergency/sos/:id/resolve',
      },
      chat: {
        conversations: 'GET /api/v1/chat/conversations',
        createConversation: 'POST /api/v1/chat/conversations',
        getConversation: 'GET /api/v1/chat/conversations/:id',
        leaveConversation: 'DELETE /api/v1/chat/conversations/:id',
        markRead: 'PATCH /api/v1/chat/conversations/:id/read',
        messages: 'GET /api/v1/chat/conversations/:id/messages',
        sendMessage: 'POST /api/v1/chat/conversations/:id/messages',
        unreadCount: 'GET /api/v1/chat/unread-count',
      },
      locations: {
        update: 'POST /api/v1/locations/update',
        myHistory: 'GET /api/v1/locations/my',
        myLatest: 'GET /api/v1/locations/my/latest',
        riders: 'GET /api/v1/locations/riders',
        riderLocation: 'GET /api/v1/locations/riders/:id',
        riderHistory: 'GET /api/v1/locations/riders/:id/history',
        settings: 'GET /api/v1/locations/settings',
        updateSettings: 'PUT /api/v1/locations/settings',
        startSharing: 'POST /api/v1/locations/share/start',
        stopSharing: 'POST /api/v1/locations/share/stop',
        stats: 'GET /api/v1/locations/stats',
      },
      uploads: {
        uploadImage: 'POST /api/v1/uploads/image',
        uploadImages: 'POST /api/v1/uploads/images',
        uploadProfile: 'POST /api/v1/uploads/profile',
        uploadChat: 'POST /api/v1/uploads/chat',
        deleteFile: 'DELETE /api/v1/uploads/:type/:filename',
        fileInfo: 'GET /api/v1/uploads/:type/:filename/info',
        listFiles: 'GET /api/v1/uploads/:type/list',
      },
    },
    timestamp: new Date().toISOString(),
  });
});

// Health check for API routes
router.get('/health', (req, res) => {
  res.json({
    success: true,
    message: 'API routes are healthy',
    timestamp: new Date().toISOString(),
  });
});

// Mount route modules
router.use('/auth', authRoutes);
router.use('/affiliations', affiliationsRoutes);
router.use('/users', usersRoutes);
router.use('/notifications', notificationsRoutes);
router.use('/announcements', announcementsRoutes);
router.use('/stats', statsRoutes);
router.use('/emergency', emergencyRoutes);
router.use('/incidents', incidentsRoutes);
router.use('/chat', chatRoutes);
router.use('/locations', locationsRoutes);
router.use('/uploads', uploadsRoutes);

module.exports = router;
