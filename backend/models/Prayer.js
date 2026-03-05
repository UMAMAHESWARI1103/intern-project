const mongoose = require('mongoose');

const prayerSchema = new mongoose.Schema({
  title: {
    type: String,
    required: true,
    trim: true,
  },
  category: {
    type: String,
    enum: ['Morning', 'Evening', 'Mantra', 'Other'],
    default: 'Other',
  },
  language: {
    type: String,
    default: 'Sanskrit',
  },
  lyrics: {
    type: String,
    default: '',
  },
  meaning: {
    type: String,
    default: '',
  },
  durationMinutes: {
    type: Number,
    default: 5,
  },
  audioUrl: {
    type: String,
    default: '',
  },
  deity: {
    type: String,
    default: '',
  },
  imageUrl: {
    type: String,
    default: '',
  },
}, { timestamps: true });

module.exports = mongoose.model('Prayer', prayerSchema);