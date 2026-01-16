'use strict';

const statsRoutes = require('./stats.routes');
const statsController = require('./stats.controller');
const statsService = require('./stats.service');
const statsRepository = require('./stats.repository');

module.exports = {
  routes: statsRoutes,
  controller: statsController,
  service: statsService,
  repository: statsRepository,
};
