const mongoose = require('mongoose');

const templeSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    trim: true,
  },
  location: {
    type: String,
    trim: true,
  },
  distance: {
    type: Number,
    default: 0,
  },
  openTime: {
    type: String,
    trim: true,
  },
  closeTime: {
    type: String,
    trim: true,
  },
  deity: {
    type: String,
    trim: true,
  },
  description: {
    type: String,
    trim: true,
  },
  festivals: {
    type: [String],
    default: [],
  },
  icon: {
    type: String,
    default: '🛕',
  },
  imageUrl: {
    type: String,
    trim: true,
    default: '',
  },
  isOpen: {
    type: Boolean,
    default: true,
  },
  lat: {
  type: Number,
  default: 0,
},
lon: {
  type: Number,
  default: 0,
},
}, { timestamps: true });

module.exports = mongoose.model('Temple', templeSchema);