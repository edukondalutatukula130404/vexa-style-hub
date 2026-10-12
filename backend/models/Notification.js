const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema(
  {
    userId: {
      type: String,
      default: ''
    },
    userEmail: {
      type: String,
      required: [true, 'User email is required'],
      lowercase: true,
      trim: true
    },
    orderId: {
      type: String,
      default: ''
    },
    type: {
      type: String,
      default: 'order_status_update'
    },
    title: {
      type: String,
      required: true
    },
    message: {
      type: String,
      required: true
    },
    customerEmail: {
      type: String,
      default: '',
      lowercase: true,
      trim: true
    },
    customerName: {
      type: String,
      default: ''
    },
    category: {
      type: String,
      default: ''
    },
    reply: {
      type: String,
      default: ''
    },
    status: {
      type: String,
      default: ''
    },
    associatedOrderId: {
      type: String,
      default: ''
    },
    ticketId: {
      type: String,
      default: ''
    },
    read: {
      type: Boolean,
      default: false
    }
  },
  {
    timestamps: true,
    strict: false
  }
);

module.exports = mongoose.model('Notification', notificationSchema);
