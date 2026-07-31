const mongoose = require('mongoose');

const itemSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Please add an item name'],
      trim: true
    },
    description: {
      type: String,
      default: ''
    },
    price: {
      type: Number,
      required: [true, 'Please add a price'],
      default: 0
    },
    category: {
      type: String,
      default: 'General'
    },
    collectionType: {
      type: String,
      default: 'Explore Collections'
    },
    image: {
      type: String,
      default: ''
    },
    inStock: {
      type: Boolean,
      default: true
    }
  },
  {
    timestamps: true
  }
);

module.exports = mongoose.model('Item', itemSchema);
