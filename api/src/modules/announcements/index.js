'use strict';

const announcementsRoutes = require('./announcements.routes');
const announcementsController = require('./announcements.controller');
const announcementsService = require('./announcements.service');
const announcementsRepository = require('./announcements.repository');

module.exports = {
  routes: announcementsRoutes,
  controller: announcementsController,
  service: announcementsService,
  repository: announcementsRepository,
};
