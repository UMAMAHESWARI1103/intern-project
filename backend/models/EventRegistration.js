const mongoose = require('mongoose');

const eventRegistrationSchema = new mongoose.Schema({
  // ── Event reference ───────────────────────────────────────────────────────
  eventId:           { type: mongoose.Schema.Types.ObjectId, ref: 'Event', required: true, index: true },
  eventTitle:        { type: String, default: '' },
  templeName:        { type: String, default: '' },
  eventDate:         { type: String, default: '' },
  registrationFee:   { type: Number, default: 0 },

  // ── User reference ────────────────────────────────────────────────────────
  userId:            { type: mongoose.Schema.Types.ObjectId, ref: 'User', index: true },
  userName:          { type: String, required: true },
  userEmail:         { type: String, required: true, index: true },
  userPhone:         { type: String, default: '' },

  // ── Payment ───────────────────────────────────────────────────────────────
  razorpayPaymentId: { type: String, default: '' },
  razorpayOrderId:   { type: String, default: '' },
  razorpaySignature: { type: String, default: '' },
  paymentStatus:     { type: String, default: 'free', enum: ['free', 'paid', 'failed'] },

  // ── Status ────────────────────────────────────────────────────────────────
  status: {
    type:    String,
    default: 'confirmed',
    enum:    ['pending', 'confirmed', 'cancelled'],
  },

  // ✅ Sample event fields ───────────────────────────────────────────────────
  sampleEventId: { type: String, default: null },   // stores 's1', 's2' etc.
  isSampleEvent: { type: Boolean, default: false },

}, { timestamps: true });

// Compound index to prevent duplicate registrations for REAL events
eventRegistrationSchema.index({ eventId: 1, userEmail: 1 }, { unique: true });

// Compound index to prevent duplicate registrations for SAMPLE events
eventRegistrationSchema.index(
  { sampleEventId: 1, userEmail: 1 },
  { unique: true, sparse: true }  // sparse: true so null sampleEventId rows are ignored
);

module.exports = mongoose.models.EventRegistration
  || mongoose.model('EventRegistration', eventRegistrationSchema);