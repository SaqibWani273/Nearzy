const express = require('express');
const router = express.Router();
const { sequelize } = require('../models');

const startTime = Date.now();

/**
 * @swagger
 * tags:
 *   - name: Health
 *     description: Endpoints for server health and status checks
 */

/**
 * @swagger
 * /health:
 *   get:
 *     tags: [Health]
 *     summary: Get server health status
 *     responses:
 *       200: { description: Server is healthy }
 */
router.get('/', async (req, res) => {
  const health = {
    status: 'UP',
    application: 'localezy',
    timestamp: new Date().toISOString(),
    uptime: getUptime(),
    database: await checkDatabase(),
  };
  res.json(health);
});

async function checkDatabase() {
  try {
    await sequelize.authenticate();
    const [results] = await sequelize.query('SELECT version()');
    return {
      status: 'UP',
      database: 'PostgreSQL',
      version: results[0].version || 'unknown',
    };
  } catch (err) {
    return {
      status: 'DOWN',
      error: err.message,
    };
  }
}

function getUptime() {
  const uptimeMs = Date.now() - startTime;
  const seconds = Math.floor(uptimeMs / 1000);
  const hours = Math.floor(seconds / 3600);
  const minutes = Math.floor((seconds % 3600) / 60);
  const secs = seconds % 60;
  return `${hours}h ${minutes}m ${secs}s`;
}

module.exports = router;
