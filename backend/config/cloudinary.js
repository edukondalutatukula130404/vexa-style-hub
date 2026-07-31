const cloudinary = require('cloudinary').v2;

const configureCloudinary = () => {
  cloudinary.config({
    cloud_name: process.env.CLOUDINARY_CLOUD_NAME || 'gqkln6vy',
    api_key: process.env.CLOUDINARY_API_KEY || '123637544328945',
    api_secret: process.env.CLOUDINARY_API_SECRET || 't91c8DbvFjYAHSNbsDzswLxUWeU'
  });
  return cloudinary;
};

configureCloudinary();

module.exports = cloudinary;
