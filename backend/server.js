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

// Set permissive CSP and CORS headers
app.use((req, res, next) => {
  res.setHeader(
    'Content-Security-Policy',
    "default-src 'self' 'unsafe-inline' 'unsafe-eval' https: http: data: blob:; script-src 'self' 'unsafe-inline' 'unsafe-eval' https: http:; script-src-elem 'self' 'unsafe-inline' 'unsafe-eval' https: http:; script-src-attr 'self' 'unsafe-inline' 'unsafe-eval' https: http:; style-src 'self' 'unsafe-inline' https: http:; img-src 'self' data: blob: https: http:; font-src 'self' data: https: http:; connect-src 'self' https: http: ws: wss:;"
  );
  next();
});

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

const ensurePortFree = (port) => {
  try {
    if (process.platform === 'win32') {
      const output = execSync(`netstat -aon | findstr :${port} | findstr LISTENING`, { encoding: 'utf8', stdio: ['pipe', 'pipe', 'ignore'] });
      const lines = output.trim().split('\n');
      lines.forEach((line) => {
        const parts = line.trim().split(/\s+/);
        const pid = parts[parts.length - 1];
        if (pid && pid !== '0' && pid !== String(process.pid)) {
          execSync(`taskkill /F /PID ${pid}`, { stdio: 'ignore' });
        }
      });
    }
  } catch (e) {
    // Port is already free
  }
};

ensurePortFree(PORT);

const server = app.listen(PORT, () => {
  console.log(`🚀 Server running in ${process.env.NODE_ENV || 'development'} mode on port ${PORT}`);
});

// Ready: VEXA MERN Stack Server
server.on('error', (err) => {
  if (err.code === 'EADDRINUSE') {
    console.warn(`⚠️ Port ${PORT} busy. Clearing stale process...`);
    ensurePortFree(PORT);
    setTimeout(() => {
      app.listen(PORT, () => {
        console.log(`🚀 Server restarted cleanly on port ${PORT}`);
      });
    }, 1000);
  } else {
    console.error('Server error:', err);
  }
});
