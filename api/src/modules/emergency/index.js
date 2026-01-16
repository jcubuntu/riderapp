'use strict';

const emergencyRoutes = require('./emergency.routes');
const emergencyController = require('./emergency.controller');
const emergencyService = require('./emergency.service');
const emergencyRepository = require('./emergency.repository');

module.exports = {
  routes: emergencyRoutes,
  controller: emergencyController,
  service: emergencyService,
  repository: emergencyRepository,
};
