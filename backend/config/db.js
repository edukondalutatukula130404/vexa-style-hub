const mongoose = require('mongoose');

// Disable Mongoose command buffering so queries don't hang when DB is disconnected
mongoose.set('bufferCommands', false);

const connectDB = async () => {
  try {
    const connUri = process.env.MONGO_URI || process.env.MONGODB_URI;
    if (!connUri) {
      console.warn('⚠️  No MONGO_URI found in environment variables.');
      return false;
    }
    const conn = await mongoose.connect(connUri, {
      serverSelectionTimeoutMS: 3000
    });
    console.log(`✅ MongoDB Connected: ${conn.connection.host}`);
    return true;
  } catch (error) {
    console.warn(`⚠️  MongoDB Connection Warning: ${error.message}`);
    console.log('💡 Backend operating with fallback mock data mode.');
    return false;
  }
};

module.exports = connectDB;


