const express = require('express');
const router = express.Router();
const Donation = require('../models/Donation');

// ─────────────────────────────────────────
// POST /api/donations  — save after payment
// ─────────────────────────────────────────
router.post('/', async (req, res) => {
  try {
    const {
      temple_id,
      temple_name,
      amount,
      donor_name,
      donor_email,
      donor_phone,
      message,
      razorpay_payment_id,
      razorpay_order_id,
      razorpay_signature,
    } = req.body;

    if (!temple_name || !amount || !donor_name || !donor_email) {
      return res.status(400).json({ message: 'Required fields missing' });
    }

    const donation = new Donation({
      templeId:          temple_id || '',
      templeName:        temple_name,
      amount:            amount,
      donorName:         donor_name,
      donorEmail:        donor_email,
      donorPhone:        donor_phone || '',
      message:           message || '',
      razorpayPaymentId: razorpay_payment_id || '',
      razorpayOrderId:   razorpay_order_id || '',
      razorpaySignature: razorpay_signature || '',
      paymentStatus:     razorpay_payment_id ? 'paid' : 'pending',
    });

    await donation.save();
    res.status(200).json({ message: 'Donation saved successfully', id: donation._id });
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

module.exports = router;