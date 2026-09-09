const express = require('express');
const dotenv = require('dotenv');
const cors = require('cors');
const morgan = require('morgan');
const connectDB = require('./config/db');
const errorHandler = require('./middlewares/errorHandler');
const { seedAdmin } = require('./controllers/userController');
const { seedItems } = require('./controllers/itemController');

// Load environment variables
dotenv.config();

// Connect to MongoDB Database and Seed Admin User & Items
connectDB().then((isConnected) => {
  if (isConnected) {
    seedAdmin();
    seedItems();
  } else {
    console.warn('⚠️  Skipping database seeding because MongoDB connection is not active.');
  }
});


const app = express();

// Enable CORS
app.use(cors());

// Body Parser Middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ limit: '10mb', extended: true }));

// HTTP Request Logger
if (process.env.NODE_ENV === 'development' || !process.env.NODE_ENV) {
  app.use(morgan('dev'));
}

// Health Check API Route
app.get('/api/health', (req, res) => {
  res.status(200).json({
    status: 'OK',
    message: 'VEXA MERN Stack Backend server is running smoothly',
    timestamp: new Date()
  });
});

// API Routes
app.use('/api/users', require('./routes/userRoutes'));
app.use('/api/items', require('./routes/itemRoutes'));
app.use('/api/orders', require('./routes/orderRoutes'));
app.use('/api/upload', require('./routes/uploadRoutes'));
app.use('/api/payment', require('./routes/paymentRoutes'));


// Central Error Handler Middleware
app.use(errorHandler);

const { execSync } = require('child_process');
const PORT = process.env.PORT || 5000;

const startServer = (portToUse) => {
  const server = app.listen(portToUse, () => {
    console.log(`🚀 Server running in ${process.env.NODE_ENV || 'development'} mode on port ${portToUse}`);
  });

  server.on('error', (err) => {
    if (err.code === 'EADDRINUSE') {
      console.warn(`⚠️ Port ${portToUse} busy. Clearing stale process on port ${portToUse}...`);
      try {
        if (process.platform === 'win32') {
          execSync(`npx -y kill-port ${portToUse}`, { stdio: 'ignore' });
        }
      } catch (e) {}
      setTimeout(() => {
        app.listen(portToUse, () => {
          console.log(`🚀 Server restarted cleanly on port ${portToUse}`);
        });
      }, 1000);
    } else {
      console.error('Server error:', err);
    }
  });
};

startServer(PORT);
