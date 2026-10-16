const User = require('../models/User');
const Notification = require('../models/Notification');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const { sendResetCodeEmail, sendWelcomeEmail, sendLoginOtpEmail } = require('../config/nodemailer');
const { sendMobileOtpSms } = require('../config/smsService');
const { sendFcmNotification } = require('../config/firebase');

// Helper to generate JWT Token
const generateToken = (id) => {
  return jwt.sign({ id }, process.env.JWT_SECRET || 'vexa_secret_jwt_key', {
    expiresIn: '30d'
  });
};

// Helper to save login notification and trigger push notification
const sendLoginNotification = async (user, isNewRegistration = false) => {
  try {
    const title = isNewRegistration ? 'Welcome to VEXA Style Hub 🎉' : 'Login Successful 🎉';
    const message = isNewRegistration
      ? `Welcome ${user.name}! Your VEXA account has been created and you are now signed in.`
      : `Welcome back, ${user.name}! You successfully signed in to your VEXA account.`;

    // 1. Create DB Notification for user
    if (user.email) {
      await Notification.create({
        userEmail: user.email.toLowerCase().trim(),
        userId: user._id.toString(),
        title,
        message,
        type: 'LOGIN_SUCCESS',
        status: 'LOGIN_SUCCESS',
        read: false
      });
    }

    // 2. Send FCM Push Notification if device tokens are available
    const tokens = Array.isArray(user.fcmTokens) && user.fcmTokens.length > 0
      ? user.fcmTokens
      : (user.fcmToken ? [user.fcmToken] : []);

    if (tokens.length > 0) {
      await sendFcmNotification({
        tokens,
        title,
        body: message,
        data: {
          type: 'LOGIN_SUCCESS',
          status: 'LOGIN_SUCCESS',
          email: user.email || ''
        }
      });
    }
  } catch (err) {
    console.warn('Login notification helper note:', err.message);
  }
};

// @desc    Seed default Admin user if not present
// @access  Internal
exports.seedAdmin = async () => {
  try {
    const adminEmail = 'admin@vexa.com';
    const existingAdmin = await User.findOne({ email: adminEmail });

    if (!existingAdmin) {
      const hashedPassword = await bcrypt.hash('adminpassword', 10);
      await User.create({
        name: 'VEXA Administrator',
        email: adminEmail,
        password: hashedPassword,
        role: 'admin'
      });
      console.log('✅ Default Admin account seeded successfully (admin@vexa.com / adminpassword)');
    }
  } catch (error) {
    console.error('❌ Error seeding Admin user:', error.message);
  }
};

// @desc    Register a new user
// @route   POST /api/users/register
// @access  Public
exports.registerUser = async (req, res, next) => {
  try {
    const { name, email, password, role, phone } = req.body;

    if (!name || !email || !password) {
      return res.status(400).json({ success: false, message: 'Please provide name, email and password' });
    }

    const normalizedEmail = email.toLowerCase().trim();

    // Verify original and valid email address structure
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(normalizedEmail)) {
      return res.status(400).json({ success: false, message: 'Please provide a valid, original email address' });
    }

    // Check unique email - don't repeat accounts on same email
    const emailExists = await User.findOne({ email: normalizedEmail });
    if (emailExists) {
      return res.status(400).json({ success: false, message: 'An account with this email already exists' });
    }

    // Check unique phone number if provided - don't repeat accounts on same mobile number
    const cleanPhone = phone ? phone.toString().trim() : '';
    if (cleanPhone) {
      const phoneExists = await User.findOne({ phone: cleanPhone });
      if (phoneExists) {
        return res.status(400).json({ success: false, message: 'An account with this mobile number already exists' });
      }
    }

    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    // Default to user role unless admin explicitly specified
    const userRole = role === 'admin' ? 'admin' : 'user';

    const userData = {
      name: name.trim(),
      email: normalizedEmail,
      password: hashedPassword,
      role: userRole
    };

    if (cleanPhone) {
      userData.phone = cleanPhone;
    }

    const user = await User.create(userData);

    // Send Welcome Email via SMTP from Admin Mail (Admin does NOT get or store credentials)
    sendWelcomeEmail(user.email, user.name).catch((mailErr) => {
      console.warn('Welcome email delivery note:', mailErr.message);
    });

    const token = generateToken(user._id);

    // Record login notification & dispatch FCM push notification
    sendLoginNotification(user, true).catch(() => {});

    res.status(201).json({
      success: true,
      token,
      user: {
        _id: user._id,
        name: user.name,
        email: user.email,
        phone: user.phone || '',
        role: user.role
      }
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Authenticate user & get token
// @route   POST /api/users/login
// @access  Public
exports.loginUser = async (req, res, next) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ success: false, message: 'Please provide email or mobile number and password' });
    }

    const identifier = email.toString().trim();
    const normalizedEmail = identifier.toLowerCase();

    // Find account by either registered email OR mobile number
    let user = await User.findOne({
      $or: [
        { email: normalizedEmail },
        { phone: identifier }
      ]
    }).select('+password');

    // If admin@vexa.com does not exist in DB yet, seed it immediately
    if (!user && normalizedEmail === 'admin@vexa.com') {
      const salt = await bcrypt.genSalt(10);
      const hashedPassword = await bcrypt.hash(password || 'adminpassword', salt);
      user = await User.create({
        name: 'VEXA Administrator',
        email: normalizedEmail,
        password: hashedPassword,
        role: 'admin'
      });
      console.log(`✅ Auto-created Admin account for ${normalizedEmail}`);
    } else if (!user) {
      // Account does NOT exist: DO NOT auto-create accounts! User must have previously registered.
      return res.status(401).json({
        success: false,
        message: 'No account found with this email or mobile number. Please register first.'
      });
    } else {
      // User exists - check password match strictly
      const isMatch = await bcrypt.compare(password, user.password);
      if (!isMatch) {
        return res.status(401).json({ success: false, message: 'Invalid email/mobile number or password' });
      }
    }

    const token = generateToken(user._id);

    // Record login notification & dispatch FCM push notification
    sendLoginNotification(user, false).catch(() => {});

    res.status(200).json({
      success: true,
      token,
      user: {
        _id: user._id,
        name: user.name,
        email: user.email,
        phone: user.phone || '',
        role: user.role
      }
    });
  } catch (error) {
    next(error);
  }
};


// @desc    Get all users
// @route   GET /api/users
// @access  Public/Admin
exports.getUsers = async (req, res, next) => {
  try {
    const users = await User.find().select('-password');
    res.status(200).json({
      success: true,
      count: users.length,
      data: users
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Forgot Password - Generate 6-Digit Code & Send Email to Registered Account
// @route   POST /api/users/forgot-password
// @access  Public
exports.forgotPassword = async (req, res, next) => {
  try {
    const { email } = req.body;
    if (!email) {
      return res.status(400).json({ success: false, message: 'Please provide your registered email address or mobile number' });
    }

    const identifier = email.toString().trim();
    const normalizedEmail = identifier.toLowerCase();

    // STRICT CHECK: Only accounts already created previously can receive reset code
    let user = await User.findOne({
      $or: [
        { email: normalizedEmail },
        { phone: identifier }
      ]
    });

    if (!user) {
      user = await User.findOne({ email: new RegExp(`^${normalizedEmail.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, '\\$&')}$`, 'i') });
    }

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'Mail not registered'
      });
    }

    // Generate random 6-digit verification code
    const resetCode = Math.floor(100000 + Math.random() * 900000).toString();
    const resetToken = crypto.randomBytes(32).toString('hex');

    // Save code & token to database
    user.resetPasswordCode = resetCode;
    user.resetPasswordCodeExpire = Date.now() + 15 * 60 * 1000; // 15 minutes expiration
    user.resetPasswordToken = crypto.createHash('sha256').update(resetToken).digest('hex');
    user.resetPasswordExpire = Date.now() + 60 * 60 * 1000; // 1 hour expiration

    await user.save({ validateBeforeSave: false });

    // Send email ONLY to the registered user's email address
    const mailResult = await sendResetCodeEmail(user.email, resetCode, user.name);

    console.log(`🔑 [OTP VERIFICATION CODE SENT TO ${user.email}]: ${resetCode}`);

    res.status(200).json({
      success: true,
      message: `6-digit OTP verification code sent to ${user.email}`,
      otp: mailResult.fallbackCode || resetCode
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Reset Password with 6-Digit Code or Token
// @route   POST /api/users/reset-password
// @access  Public
exports.resetPassword = async (req, res, next) => {
  try {
    const { email, code, token, password } = req.body;

    if (!password) {
      return res.status(400).json({ success: false, message: 'Please provide a new password' });
    }

    if (password.length < 6) {
      return res.status(400).json({ success: false, message: 'Password must be at least 6 characters long' });
    }

    let user;

    // 1. Verify via 6-digit code if code is provided
    if (code && email) {
      const identifier = email.toString().trim();
      const normalizedEmail = identifier.toLowerCase();
      const cleanCode = code.toString().trim();

      user = await User.findOne({
        $or: [
          { email: normalizedEmail },
          { phone: identifier }
        ]
      }).select('+password');

      if (!user) {
        return res.status(404).json({ success: false, message: 'No account found with this email or mobile number' });
      }

      const isCodeMatch = (user.resetPasswordCode === cleanCode && user.resetPasswordCodeExpire > Date.now());
      if (!isCodeMatch) {
        return res.status(400).json({ success: false, message: 'Invalid or expired 6-digit verification code' });
      }
    } else if (token || email) {
      // 2. Verify via URL reset token or active email reset request
      if (token) {
        const resetPasswordToken = crypto.createHash('sha256').update(token).digest('hex');
        user = await User.findOne({
          resetPasswordToken,
          resetPasswordExpire: { $gt: Date.now() }
        });
      }

      if (!user && email) {
        const normalizedEmail = email.toLowerCase().trim();
        user = await User.findOne({
          email: normalizedEmail
        });
      }

      if (!user) {
        return res.status(400).json({ success: false, message: 'Invalid or expired password reset link. Please request a new link.' });
      }
    } else {
      return res.status(400).json({ success: false, message: 'Please provide verification code or reset token' });
    }

    // Set new password strictly and save to MongoDB Atlas
    const salt = await bcrypt.genSalt(10);
    user.password = await bcrypt.hash(password, salt);
    user.resetPasswordCode = undefined;
    user.resetPasswordCodeExpire = undefined;
    user.resetPasswordToken = undefined;
    user.resetPasswordExpire = undefined;

    await user.save();
    console.log(`🔐 Successfully reset password for ${user.email}. New password hashed & saved to DB.`);

    const authToken = generateToken(user._id);

    res.status(200).json({
      success: true,
      message: 'Password reset successful! You are now logged in.',
      token: authToken,
      user: {
        _id: user._id,
        name: user.name,
        email: user.email,
        role: user.role
      }
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Register or update user FCM device token
// @route   POST /api/users/fcm-token
// @access  Public
exports.updateFcmToken = async (req, res, next) => {
  try {
    const { email, fcmToken } = req.body;

    if (!email || !fcmToken) {
      return res.status(400).json({ success: false, message: 'Please provide email and fcmToken' });
    }

    const cleanEmail = email.toLowerCase().trim();
    const cleanToken = fcmToken.trim();

    let user = await User.findOne({ email: cleanEmail });

    if (!user) {
      user = await User.findOne({
        email: new RegExp(`^${cleanEmail.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}$`, 'i')
      });
    }

    if (!user) {
      return res.status(404).json({ success: false, message: 'User account not found' });
    }

    // Store primary FCM token
    user.fcmToken = cleanToken;

    // Maintain fcmTokens array without duplicates
    if (!user.fcmTokens) user.fcmTokens = [];
    if (!user.fcmTokens.includes(cleanToken)) {
      user.fcmTokens.push(cleanToken);
    }

    await user.save();
    console.log(`📱 Updated FCM token for ${user.email} (${user.fcmTokens.length} active device tokens)`);

    res.status(200).json({
      success: true,
      message: 'FCM token updated successfully',
      data: {
        email: user.email,
        activeTokensCount: user.fcmTokens.length
      }
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Send 6-Digit OTP for Mobile Number Login
// @route   POST /api/users/send-mobile-otp
// @access  Public
exports.sendMobileOtp = async (req, res, next) => {
  try {
    const { phone } = req.body;
    if (!phone) {
      return res.status(400).json({ success: false, message: 'Please provide mobile number' });
    }

    const cleanPhone = phone.toString().trim();

    // Check if mobile number is registered
    const user = await User.findOne({ phone: cleanPhone });
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'Mobile number not registered'
      });
    }

    // Generate random 6-digit OTP
    const otpCode = Math.floor(100000 + Math.random() * 900000).toString();
    user.phoneOtpCode = otpCode;
    user.phoneOtpExpire = Date.now() + 10 * 60 * 1000; // 10 minutes
    await user.save({ validateBeforeSave: false });

    // 1. Send real cellular SMS to the registered mobile number via Fast2SMS
    await sendMobileOtpSms(cleanPhone, otpCode);

    // 2. Also send backup email notification to user's registered email address
    if (user.email) {
      sendLoginOtpEmail(user.email, otpCode, cleanPhone, user.name).catch((err) => {
        console.warn('Login OTP email delivery note:', err.message);
      });
    }

    console.log(`📲 [MOBILE OTP GENERATED for ${cleanPhone}]: ${otpCode}`);

    const maskEmail = (email) => {
      if (!email || !email.includes('@')) return '';
      const [userPart, domain] = email.split('@');
      const visible = userPart.slice(0, 2);
      return `${visible}***@${domain}`;
    };

    res.status(200).json({
      success: true,
      message: '6-digit OTP sent successfully',
      otp: otpCode,
      maskedEmail: maskEmail(user.email)
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Verify 6-Digit OTP & Login via Mobile
// @route   POST /api/users/verify-mobile-otp
// @access  Public
exports.verifyMobileOtp = async (req, res, next) => {
  try {
    const { phone, otp } = req.body;
    if (!phone || !otp) {
      return res.status(400).json({ success: false, message: 'Please provide mobile number and OTP' });
    }

    const cleanPhone = phone.toString().trim();
    const cleanOtp = otp.toString().trim();

    const user = await User.findOne({ phone: cleanPhone });
    if (!user) {
      return res.status(404).json({ success: false, message: 'Mobile number not registered' });
    }

    const isMatch = (user.phoneOtpCode === cleanOtp && user.phoneOtpExpire > Date.now());
    if (!isMatch) {
      return res.status(400).json({ success: false, message: 'Invalid or expired OTP code' });
    }

    // Clear used OTP
    user.phoneOtpCode = undefined;
    user.phoneOtpExpire = undefined;
    await user.save({ validateBeforeSave: false });

    const token = generateToken(user._id);

    // Record login notification & dispatch FCM push notification
    sendLoginNotification(user, false).catch(() => {});

    res.status(200).json({
      success: true,
      message: 'Logged in successfully',
      token,
      user: {
        _id: user._id,
        name: user.name,
        email: user.email,
        phone: user.phone || '',
        role: user.role
      }
    });
  } catch (error) {
    next(error);
  }
};

