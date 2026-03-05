// backend/models/Product.js
const mongoose = require('mongoose');

const productSchema = new mongoose.Schema({
  name:          { type: String, required: true, trim: true },
  description:   { type: String, default: '' },
  category:      { type: String, required: true },
  price:         { type: Number, required: true, min: 0 },
  originalPrice: { type: Number, default: 0 },
  imageUrl:      { type: String, default: '' },
  stock:         { type: Number, default: 0, min: 0 },
  tags:          [String],
  isBestseller:  { type: Boolean, default: false },
  isActive:      { type: Boolean, default: true },
  rating:        { type: Number, default: 4.5 },
  reviews:       { type: Number, default: 0 },
}, { timestamps: true });

module.exports = mongoose.model('Product', productSchema);