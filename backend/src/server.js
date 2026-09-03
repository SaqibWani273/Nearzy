require('dotenv').config();

const app = require('./app');
const { sequelize } = require('./models');
const { startJobs } = require('./jobs');

const PORT = process.env.PORT || 8080;

async function start() {
  try {
    // Test database connection
    await sequelize.authenticate();
    console.log('Database connection established successfully.');

    // Sync models (equivalent to JPA ddl-auto=update)
    //alter:true will update the tables to match the models without dropping them
    //but it is not recommended for production use, as it may lead 
    // to data loss or corruption if the models change significantly.
    await sequelize.sync({ alter: true });
    console.log('Database models synchronized.');

    // Background schedule. Off by default — see jobs/index.js.
    startJobs();

    // Start server
    app.listen(PORT, () => {
      console.log(`Welcome to Nearzy!`);
      console.log(`Server running on port ${PORT}`);
      console.log(`Swagger UI: http://localhost:${PORT}/swagger-ui`);
    });
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
}

start();
