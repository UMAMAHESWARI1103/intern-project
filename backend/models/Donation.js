const mongoose = require('mongoose');

const donationSchema = new mongoose.Schema({
  templeId: {
    type: String,
    default: '',
  },
  templeName: {
    type: String,
    required: true,
    trim: true,
  },
  amount: {
    type: Number,
    required: true,
  },
  donorName: {
    type: String,
    required: true,
    trim: true,
  },
  donorEmail: {
    type: String,
    required: true,
    trim: true,
    lowercase: true,
  },
  donorPhone: {
    type: String,
    trim: true,
  },
  message: {
    type: String,
    default: '',
  },
  razorpayPaymentId: {
    type: String,
    default: '',
  },
  razorpayOrderId: {
    type: String,
    default: '',
  },
  razorpaySignature: {
    type: String,
    default: '',
  },
  paymentStatus: {
    type: String,
    enum: ['paid', 'pending', 'failed'],
    default: 'pending',
  },
}, { timestamps: true });

module.exports = mongoose.models.Donation || mongoose.model('Donation', donationSchema);