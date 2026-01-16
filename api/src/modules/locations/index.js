'use strict';

/**
 * Locations Module
 * Handles rider location tracking and sharing
 */

const locationsRoutes = require('./locations.routes');
const locationsController = require('./locations.controller');
const locationsService = require('./locations.service');
const locationsRepository = require('./locations.repository');

module.exports = {
  routes: locationsRoutes,
  controller: locationsController,
  service: locationsService,
  repository: locationsRepository,
};
