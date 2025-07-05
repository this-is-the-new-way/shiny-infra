const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const winston = require('winston');

// Configure logger
const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  transports: [
    new winston.transports.Console()
  ]
});

const app = express();
const port = process.env.PORT || 3000;

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));
app.use(morgan('combined', {
  stream: {
    write: (message) => logger.info(message.trim())
  }
}));

// Health check endpoint
app.get('/health', (req, res) => {
  const health = {
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: process.env.NODE_ENV || 'development',
    version: process.env.npm_package_version || '1.0.0'
  };
  
  logger.info('Health check requested', { health });
  res.status(200).json(health);
});

// Ready check endpoint
app.get('/ready', (req, res) => {
  const ready = {
    status: 'ready',
    timestamp: new Date().toISOString(),
    checks: {
      database: 'ok', // Add actual database check here
      redis: 'ok',     // Add actual redis check here
      external_apis: 'ok' // Add external API checks here
    }
  };
  
  logger.info('Readiness check requested', { ready });
  res.status(200).json(ready);
});

// Root endpoint
app.get('/', (req, res) => {
  const response = {
    message: 'Welcome to My App!',
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'development',
    version: process.env.npm_package_version || '1.0.0'
  };
  
  logger.info('Root endpoint accessed', { response });
  res.json(response);
});

// API endpoint
app.get('/api/info', (req, res) => {
  const info = {
    application: 'my-app',
    version: process.env.npm_package_version || '1.0.0',
    environment: process.env.NODE_ENV || 'development',
    node_version: process.version,
    uptime: process.uptime(),
    memory: process.memoryUsage(),
    cpu: process.cpuUsage()
  };
  
  logger.info('Info endpoint accessed', { info });
  res.json(info);
});

// Sample API endpoint with error handling
app.post('/api/echo', (req, res) => {
  try {
    const { message } = req.body;
    
    if (!message) {
      return res.status(400).json({
        error: 'Bad Request',
        message: 'Message is required'
      });
    }
    
    const response = {
      echo: message,
      timestamp: new Date().toISOString(),
      length: message.length
    };
    
    logger.info('Echo endpoint accessed', { request: message, response });
    res.json(response);
  } catch (error) {
    logger.error('Error in echo endpoint', { error: error.message, stack: error.stack });
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'An unexpected error occurred'
    });
  }
});

// Error handling middleware
app.use((error, req, res, next) => {
  logger.error('Unhandled error', {
    error: error.message,
    stack: error.stack,
    url: req.url,
    method: req.method
  });
  
  res.status(500).json({
    error: 'Internal Server Error',
    message: 'An unexpected error occurred'
  });
});

// 404 handler
app.use((req, res) => {
  logger.warn('404 - Not Found', {
    url: req.url,
    method: req.method,
    ip: req.ip
  });
  
  res.status(404).json({
    error: 'Not Found',
    message: 'The requested resource was not found'
  });
});

// Graceful shutdown
process.on('SIGTERM', () => {
  logger.info('SIGTERM received, shutting down gracefully');
  
  server.close(() => {
    logger.info('Process terminated');
    process.exit(0);
  });
  
  // Force close after 30 seconds
  setTimeout(() => {
    logger.error('Forced shutdown after timeout');
    process.exit(1);
  }, 30000);
});

process.on('SIGINT', () => {
  logger.info('SIGINT received, shutting down gracefully');
  
  server.close(() => {
    logger.info('Process terminated');
    process.exit(0);
  });
});

// Start server
const server = app.listen(port, '0.0.0.0', () => {
  logger.info(`Server started on port ${port}`, {
    port,
    environment: process.env.NODE_ENV || 'development',
    pid: process.pid
  });
});

module.exports = app;
