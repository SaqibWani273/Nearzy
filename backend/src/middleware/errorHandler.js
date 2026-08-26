/**
 * Global error handling middleware.
 * Catches all errors and returns a consistent JSON response.
 */
const errorHandler = (err, req, res, next) => {
  console.error('Error:', err);

  // Sequelize unique constraint violation
  if (err.name === 'SequelizeUniqueConstraintError') {
    return res.status(400).json({
      message: 'Duplicate Entry',
      status: 422,
      error: err.name,
    });
  }

  // Sequelize validation error
  if (err.name === 'SequelizeValidationError') {
    return res.status(400).json({
      message: err.errors.map((e) => e.message).join(', '),
      status: 400,
      error: err.name,
    });
  }

  // Sequelize database error
  if (err.name === 'SequelizeDatabaseError') {
    return res.status(400).json({
      message: err.message || 'Database Persistence Error',
      status: 422,
      error: err.name,
    });
  }

  // Default: Internal Server Error
  res.status(err.statusCode || 500).json({
    message: err.message || 'Internal Server Error',
    status: err.statusCode || 500,
    error: err.name || 'Error',
  });
};

module.exports = errorHandler;
