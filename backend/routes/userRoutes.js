const express = require('express');
const router = express.Router();
const {
  getUsers,
  registerUser,
  loginUser,
  forgotPassword,
  resetPassword,
  updateFcmToken,
  sendMobileOtp,
  verifyMobileOtp
} = require('../controllers/userController');

router.post('/register', registerUser);
router.post('/login', loginUser);
router.post('/send-mobile-otp', sendMobileOtp);
router.post('/verify-mobile-otp', verifyMobileOtp);
router.post('/forgot-password', forgotPassword);
router.post('/reset-password', resetPassword);
router.post('/fcm-token', updateFcmToken);

router.route('/')
  .get(getUsers)
  .post(registerUser);

module.exports = router;
