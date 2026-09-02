const express = require('express');
const cors = require('cors');
const swaggerUi = require('swagger-ui-express');
const swaggerSpec = require('./config/swagger');
const authenticate = require('./middleware/auth');
const errorHandler = require('./middleware/errorHandler');

// Route imports
const adminRoutes = require('./routes/adminRoutes');
const customerRoutes = require('./routes/customerRoutes');
const shopRoutes = require('./routes/shopRoutes');
const commonRoutes = require('./routes/commonRoutes');
const healthRoutes = require('./routes/healthRoutes');

const app = express();


app.use(cors({
  origin: function (origin, callback) {
    // Allow all origins (matching the Java allowedOriginPatterns("*") + allowCredentials)
    callback(null, true);
  },
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
  allowedHeaders: ['*'],
  credentials: true,
}));

// Parse JSON and text bodies
app.use(express.json());
app.use(express.text());

// JWT authentication on all routes
app.use(authenticate);

// Swagger UI
app.use('/swagger-ui', swaggerUi.serve, swaggerUi.setup(swaggerSpec));
app.get('/swagger.html', (req, res) => res.redirect('/swagger-ui'));
app.get('/v3/api-docs', (req, res) => res.json(swaggerSpec));

// Mount routes
app.use('/admin', adminRoutes);
app.use('/customer', customerRoutes);
app.use('/shop', shopRoutes);
app.use('/user', commonRoutes);
app.use('/health', healthRoutes);

// Global error handler
app.use(errorHandler);

module.exports = app;
