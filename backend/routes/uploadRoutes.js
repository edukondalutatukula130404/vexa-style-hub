const express = require('express');
const router = express.Router();
const upload = require('../middlewares/upload');
const { uploadImage } = require('../controllers/uploadController');

// POST /api/upload - Accepts single file field 'image' or 'file', or base64 JSON payload
router.post('/', upload.single('image'), uploadImage);

module.exports = router;
