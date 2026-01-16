'use strict';

const notificationsRoutes = require('./notifications.routes');
const notificationsController = require('./notifications.controller');
const notificationsService = require('./notifications.service');
const notificationsRepository = require('./notifications.repository');

module.exports = {
  routes: notificationsRoutes,
  controller: notificationsController,
  service: notificationsService,
  repository: notificationsRepository,
};
