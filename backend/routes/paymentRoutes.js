const express = require('express');
const router = express.Router();
const {
  createOrder,
  verifyPayment,
  recordPayment,
  getAllPayments,
  getUserPayments,
  getRazorpayKey
} = require('../controllers/paymentController');

// @route   GET /api/payment/key
router.get('/key', getRazorpayKey);

// @route   POST /api/payment/create-order
router.post('/create-order', createOrder);

// @route   POST /api/payment/verify-payment
router.post('/verify-payment', verifyPayment);

// @route   POST /api/payment/record
router.post('/record', recordPayment);

// @route   GET /api/payment/all (Admin / Reporting)
router.get('/all', getAllPayments);

// @route   GET /api/payment/my-payments
router.get('/my-payments', getUserPayments);

module.exports = router;

