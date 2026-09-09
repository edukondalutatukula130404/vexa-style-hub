const express = require('express');
const router = express.Router();
const {
  createOrder,
  verifyPayment,
  getRazorpayKey
} = require('../controllers/paymentController');

// @route   GET /api/payment/key
router.get('/key', getRazorpayKey);

// @route   POST /api/payment/create-order
router.post('/create-order', createOrder);

// @route   POST /api/payment/verify-payment
router.post('/verify-payment', verifyPayment);

module.exports = router;
