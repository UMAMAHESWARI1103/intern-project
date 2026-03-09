const mongoose = require('mongoose');

const priestSchema = new mongoose.Schema({
  name:         { type: String, required: true },
  phone:        { type: String, required: true },
  email:        { type: String, default: '' },
  photo:        { type: String, default: '' },
  languages:    [String],           // ['Tamil', 'Sanskrit', 'Telugu']
  specializations: [String],        // ['Ganapathi Homam', 'Navagraha Homam', ...]
  experience:   { type: Number, default: 0 },  // years
  location:     { type: String, default: '' }, // city/area
  isAvailable:  { type: Boolean, default: true },
  rating:       { type: Number, default: 5.0 },
  totalBookings:{ type: Number, default: 0 },
}, { timestamps: true });

module.exports = mongoose.models.Priest || mongoose.model('Priest', priestSchema);