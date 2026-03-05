const mongoose = require('mongoose');

const eventSchema = new mongoose.Schema({
  title: {
    type: String,
    required: true,
    trim: true,
  },
  description: {
    type: String,
    trim: true,
    default: '',
  },
  templeId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Temple',
    default: null,
  },
  templeName: {
    type: String,
    trim: true,
    default: '',
  },
  date: {
    type: String,   // e.g. "2026-03-01"
    required: true,
  },
  time: {
    type: String,   // e.g. "6:00 AM"
    default: '',
  },
  location: {
    type: String,   // ✅ ADDED: was missing from original schema
    default: '',
  },
  category: {
    type: String,   // ✅ ADDED: was missing from original schema
    default: 'Other',
    enum: ['Festival', 'Pooja', 'Special', 'Cultural', 'Other'],
  },
  registrationFee: {
    type: Number,
    default: 0,
  },
  isFree: {
    type: Boolean,
    default: true,
  },
  imageUrl: {
    type: String,
    default: '',
  },
  maxParticipants: {
    type: Number,
    default: 500,
  },
  registeredCount: {
    type: Number,
    default: 0,
  },
  isActive: {
    type: Boolean,
    default: true,
  },
}, { timestamps: true });

module.exports = mongoose.model('Event', eventSchema);