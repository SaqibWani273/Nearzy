'use strict';

const cron = require('node-cron');
const { runReplenishmentScan } = require('./replenishment');
const { runMarkdownSweep, runMarkdownReset } = require('./markdown');

/**
 * Background schedule.
 *
 * Guarded by ENABLE_JOBS because these jobs write to shared state: two dev
 * instances against the same database would each raise the same alerts and
 * each escalate the same markdown, and `nodemon` restarting on every file save
 * would re-run them constantly. Off unless asked for.
 */

const TIMEZONE = process.env.JOBS_TIMEZONE || 'Asia/Kolkata';

/** Never let a job's failure take the API process down with it. */
function guard(name, fn) {
  return async () => {
    const startedAt = Date.now();
    try {
      const summary = await fn();
      console.log(`[jobs] ${name}`, summary, `(${Date.now() - startedAt}ms)`);
    } catch (err) {
      console.error(`[jobs] ${name} failed:`, err.message);
    }
  };
}

const SCHEDULE = [
  // Hourly, on the hour.
  { name: 'replenishment', spec: '0 * * * *', run: runReplenishmentScan },
  // Every 30 minutes through the markdown ramp (15:00–21:00).
  { name: 'markdown-sweep', spec: '*/30 15-21 * * *', run: runMarkdownSweep },
  // Just after midnight, back to the owner's own pricing.
  { name: 'markdown-reset', spec: '5 0 * * *', run: runMarkdownReset },
];

function startJobs() {
  if (process.env.ENABLE_JOBS !== 'true') {
    console.log('[jobs] disabled (set ENABLE_JOBS=true to enable)');
    return [];
  }

  const tasks = SCHEDULE.map(({ name, spec, run }) =>
    cron.schedule(spec, guard(name, run), { timezone: TIMEZONE })
  );

  console.log(
    `[jobs] started ${tasks.length} scheduled jobs (${TIMEZONE}):`,
    SCHEDULE.map((j) => `${j.name} @ ${j.spec}`).join(', ')
  );
  return tasks;
}

module.exports = { startJobs, runReplenishmentScan, runMarkdownSweep, runMarkdownReset };
