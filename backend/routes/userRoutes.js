const express = require('express');
const router = express.Router();
const { getUsers, registerUser, loginUser, forgotPassword, resetPassword } = require('../controllers/userController');

router.post('/register', registerUser);
router.post('/login', loginUser);
router.post('/forgot-password', forgotPassword);
router.post('/reset-password', resetPassword);

router.route('/')
  .get(getUsers)
  .post(registerUser);

module.exports = router;
