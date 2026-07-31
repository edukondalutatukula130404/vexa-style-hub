const cloudinary = require('../config/cloudinary');
const streamifier = require('streamifier');

// @desc    Upload an image/file to Cloudinary
// @route   POST /api/upload
// @access  Public
exports.uploadImage = async (req, res, next) => {
  try {
    const folder = req.body.folder || 'vexa_uploads';

    cloudinary.config({
      cloud_name: process.env.CLOUDINARY_CLOUD_NAME || 'gqkln6vy',
      api_key: process.env.CLOUDINARY_API_KEY || '123637544328945',
      api_secret: process.env.CLOUDINARY_API_SECRET || 't91c8DbvFjYAHSNbsDzswLxUWeU'
    });

    // 1. If uploaded via Multer (multipart form file buffer)
    if (req.file) {

      const uploadFromBuffer = (fileBuffer) => {
        return new Promise((resolve, reject) => {
          const cldStream = cloudinary.uploader.upload_stream(
            {
              folder: folder,
              resource_type: 'auto'
            },
            (error, result) => {
              if (result) {
                resolve(result);
              } else {
                reject(error);
              }
            }
          );
          streamifier.createReadStream(fileBuffer).pipe(cldStream);
        });
      };

      const result = await uploadFromBuffer(req.file.buffer);

      return res.status(200).json({
        success: true,
        message: 'File uploaded successfully to Cloudinary',
        url: result.secure_url,
        public_id: result.public_id,
        format: result.format,
        bytes: result.bytes
      });
    }

    // 2. If uploaded as Base64 string in body: { image: "data:image/png;base64,..." }
    if (req.body && req.body.image) {
      const result = await cloudinary.uploader.upload(req.body.image, {
        folder: folder,
        resource_type: 'auto'
      });

      return res.status(200).json({
        success: true,
        message: 'Image uploaded successfully to Cloudinary',
        url: result.secure_url,
        public_id: result.public_id,
        format: result.format,
        bytes: result.bytes
      });
    }

    return res.status(400).json({
      success: false,
      message: 'No file or image base64 data provided'
    });
  } catch (error) {
    console.error('Cloudinary upload error:', error);
    res.status(500).json({
      success: false,
      message: error.message || 'Error uploading file to Cloudinary'
    });
  }
};
