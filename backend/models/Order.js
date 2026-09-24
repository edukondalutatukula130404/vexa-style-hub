const mongoose = require('mongoose');

const orderSchema = new mongoose.Schema(
  {
    id: {
      type: String,
      default: ''
    },
    userEmail: {
      type: String,
      required: [true, 'Please add user email']
    },
    userName: {
      type: String,
      required: [true, 'Please add user name']
    },
    items: [
      {
        id: String,
        name: String,
        price: Number,
        size: String,
        color: String,
        quantity: Number,
        image: String
      }
    ],
    totalAmount: {
      type: Number,
      required: true
    },
    status: {
      type: String,
      enum: ['Processing', 'Shipped', 'Delivered', 'Cancelled'],
      default: 'Processing'
    },
    cancelReason: {
      type: String,
      default: ''
    },
    paymentMethod: {
      type: String,
      default: 'Cash on Delivery'
    },
    shippingAddress: {
      type: String,
      default: 'Indiranagar 100ft Road, Bengaluru'
    }
  },
  {
    timestamps: true
  }
);

module.exports = mongoose.model('Order', orderSchema);
