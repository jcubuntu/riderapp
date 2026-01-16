'use strict';

const incidentsRoutes = require('./incidents.routes');
const incidentsController = require('./incidents.controller');
const incidentsService = require('./incidents.service');
const incidentsRepository = require('./incidents.repository');
const incidentsValidation = require('./incidents.validation');

module.exports = {
  routes: incidentsRoutes,
  controller: incidentsController,
  service: incidentsService,
  repository: incidentsRepository,
  validation: incidentsValidation,
};
