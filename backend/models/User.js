const mongoose = require('mongoose');

const userSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Please add a name'],
      trim: true
    },
    companyName: {
      type: String,
      default: 'VEXA Style Hub',
      trim: true
    },
    email: {
      type: String,
      required: [true, 'Please add an email'],
      unique: true,
      lowercase: true,
      trim: true
    },
    phone: {
      type: String,
      trim: true
    },
    password: {
      type: String,
      required: [true, 'Please add a password'],
      minlength: 6,
      select: false
    },
    role: {
      type: String,
      enum: ['user', 'admin'],
      default: 'user'
    },
    resetPasswordToken: String,
    resetPasswordExpire: Date,
    resetPasswordCode: String,
    resetPasswordCodeExpire: Date,
    phoneOtpCode: String,
    phoneOtpExpire: Date,
    fcmToken: {
      type: String,
      default: ''
    },
    fcmTokens: [
      {
        type: String
      }
    ]
  },
  {
    timestamps: true
  }
);

// Enforce unique phone number when provided (skip null / undefined / empty string)
userSchema.index(
  { phone: 1 },
  {
    unique: true,
    partialFilterExpression: { phone: { $type: 'string', $gt: '' } }
  }
);

module.exports = mongoose.model('User', userSchema);
