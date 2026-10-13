const mongoose = require('mongoose');

const paymentSchema = new mongoose.Schema(
  {
    paymentId: {
      type: String,
      required: true,
      index: true
    },
    orderId: {
      type: String,
      default: '',
      index: true
    },
    userEmail: {
      type: String,
      required: [true, 'Please add user email'],
      index: true
    },
    userName: {
      type: String,
      default: 'Customer'
    },
    amount: {
      type: Number,
      required: [true, 'Please provide payment amount']
    },
    currency: {
      type: String,
      default: 'INR'
    },
    status: {
      type: String,
      enum: ['Success', 'Pending', 'Failed', 'Refunded'],
      default: 'Success'
    },
    paymentMethod: {
      type: String,
      default: 'Razorpay Online Payment'
    },
    razorpayOrderId: {
      type: String,
      default: ''
    },
    razorpayPaymentId: {
      type: String,
      default: ''
    },
    razorpaySignature: {
      type: String,
      default: ''
    },
    metadata: {
      type: Object,
      default: {}
    }
  },
  {
    timestamps: true
  }
);

module.exports = mongoose.model('Payment', paymentSchema);
