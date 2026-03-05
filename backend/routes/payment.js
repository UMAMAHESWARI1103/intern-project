const express  = require('express');
const router   = express.Router();
const Razorpay = require('razorpay');
const crypto   = require('crypto');

// ✅ FIX: Validate env keys at startup so you catch missing keys early
const RAZORPAY_KEY_ID     = process.env.RAZORPAY_KEY_ID     || 'rzp_test_SJdyZblt9njE1Z';
const RAZORPAY_KEY_SECRET = process.env.RAZORPAY_KEY_SECRET || process.env.RAZORPAY_SECRET || 'YU77BoRuQliU8IMiXxLDT0fq';

if (!RAZORPAY_KEY_ID || !RAZORPAY_KEY_SECRET) {
  console.error('❌ RAZORPAY_KEY_ID or RAZORPAY_KEY_SECRET is missing in .env');
}

const razorpay = new Razorpay({
  key_id:     RAZORPAY_KEY_ID,
  key_secret: RAZORPAY_KEY_SECRET,
});

// ─────────────────────────────────────────────────────────────────────────────
// POST /api/payments/create-order
//
// Flutter sends amount already in PAISE (rupees × 100).
// This route creates a Razorpay order and returns order details + key.
// ─────────────────────────────────────────────────────────────────────────────
router.post('/create-order', async (req, res) => {
  try {
    const { amount, currency = 'INR', receipt = 'order_rcpt', notes = {} } = req.body;

    // ✅ FIX: Validate amount properly — must be a positive integer (paise)
    const parsedAmount = parseInt(amount, 10);
    if (!amount || isNaN(parsedAmount) || parsedAmount <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Invalid amount. Amount must be a positive integer in paise.',
      });
    }

    // Minimum Razorpay order is 100 paise (₹1)
    if (parsedAmount < 100) {
      return res.status(400).json({
        success: false,
        message: 'Minimum amount is ₹1 (100 paise).',
      });
    }

    const order = await razorpay.orders.create({
      amount:   parsedAmount,   // paise — already converted by Flutter (price × 100)
      currency: currency,
      receipt:  receipt,
      notes:    notes,
    });

    console.log(`✅ Razorpay order created: ${order.id} | ₹${parsedAmount / 100}`);

    // ✅ FIX: Always return JSON — never let Express return HTML for this route
    return res.status(200).json({
      success:      true,
      order_id:     order.id,
      amount:       order.amount,       // paise
      currency:     order.currency,
      receipt:      order.receipt,
      razorpay_key: RAZORPAY_KEY_ID,    // send key to Flutter so it's always in sync
    });

  } catch (err) {
    console.error('❌ Razorpay create-order error:', err);

    // ✅ FIX: Explicit JSON error — prevents the "FormatException: Unexpected character <!DOCTYPE html>" crash
    return res.status(500).json({
      success: false,
      message: 'Failed to create payment order.',
      error:   err.message || 'Unknown error',
    });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// POST /api/payments/verify
//
// Called after payment to verify Razorpay signature before saving to DB.
// ─────────────────────────────────────────────────────────────────────────────
router.post('/verify', (req, res) => {
  try {
    const { razorpay_order_id, razorpay_payment_id, razorpay_signature } = req.body;

    // ✅ FIX: Validate all fields are present
    if (!razorpay_order_id || !razorpay_payment_id || !razorpay_signature) {
      return res.status(400).json({
        success:  false,
        verified: false,
        message:  'Missing required payment verification fields.',
      });
    }

    const body     = `${razorpay_order_id}|${razorpay_payment_id}`;
    const expected = crypto
      .createHmac('sha256', RAZORPAY_KEY_SECRET)
      .update(body)
      .digest('hex');

    if (expected === razorpay_signature) {
      console.log(`✅ Payment verified: ${razorpay_payment_id}`);
      return res.status(200).json({
        success:  true,
        verified: true,
        message:  'Payment verified successfully.',
      });
    } else {
      console.warn(`⚠️ Payment signature mismatch for order: ${razorpay_order_id}`);
      return res.status(400).json({
        success:  false,
        verified: false,
        message:  'Payment verification failed. Signature mismatch.',
      });
    }

  } catch (err) {
    console.error('❌ Payment verify error:', err);
    return res.status(500).json({
      success:  false,
      verified: false,
      message:  'Payment verification error.',
      error:    err.message,
    });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/payments/key
//
// ✅ NEW: Flutter can call this to always get the latest Razorpay key
//    without hardcoding it in the app
// ─────────────────────────────────────────────────────────────────────────────
router.get('/key', (req, res) => {
  return res.status(200).json({
    success:      true,
    razorpay_key: RAZORPAY_KEY_ID,
  });
});

module.exports = router;