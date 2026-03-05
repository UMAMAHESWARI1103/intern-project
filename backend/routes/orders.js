// backend/routes/orders.js
// Handles ecommerce orders from GodsConnect Store
const express  = require('express');
const router   = express.Router();
const mongoose = require('mongoose');
const jwt      = require('jsonwebtoken');

// ─────────────────────────────────────────────────────────────────────────────
// OPTIONAL AUTH
// ─────────────────────────────────────────────────────────────────────────────
function optionalAuth(req, res, next) {
  try {
    const header = req.headers['authorization'] || '';
    const token  = header.startsWith('Bearer ') ? header.slice(7) : null;
    if (token) req.user = jwt.verify(token, process.env.JWT_SECRET || 'secret');
  } catch (_) {}
  next();
}

// ─────────────────────────────────────────────────────────────────────────────
// ORDER SCHEMA
// ─────────────────────────────────────────────────────────────────────────────
const orderSchema = new mongoose.Schema({
  userId:            { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
  userName:          { type: String, required: true },
  userEmail:         { type: String, required: true },
  userPhone:         { type: String, default: '' },
  deliveryAddress:   { type: String, default: '' },
  city:              { type: String, default: '' },
  pincode:           { type: String, default: '' },
  items:             { type: Array,  default: [] },
  totalAmount:       { type: Number, default: 0 },
  grandTotal:        { type: Number, default: 0 },
  razorpayPaymentId: { type: String, default: '' },
  razorpayOrderId:   { type: String, default: '' },
  razorpaySignature: { type: String, default: '' },
  paymentStatus:     { type: String, default: 'paid',      enum: ['pending','paid','failed'] },
  status:            { type: String, default: 'confirmed', enum: ['pending','confirmed','shipped','delivered','cancelled'] },
  trackingId:        { type: String, default: '' },
  bookingType:       { type: String, default: 'ecommerce' },
}, { timestamps: true });

const Order = mongoose.models.Order || mongoose.model('Order', orderSchema);

// ─────────────────────────────────────────────────────────────────────────────
// POST /api/orders  — save order after Razorpay payment success
// ─────────────────────────────────────────────────────────────────────────────
router.post('/', optionalAuth, async (req, res) => {
  try {
    const userId    = req.user?._id || req.user?.id || null;
    const userEmail = req.user?.email || req.body.userEmail;

    if (!userEmail) {
      return res.status(400).json({ success: false, message: 'userEmail is required' });
    }

    const order = new Order({
      ...req.body,
      userId,
      userEmail,
      totalAmount: req.body.grandTotal || req.body.totalAmount || 0,
      grandTotal:  req.body.grandTotal || req.body.totalAmount || 0,
    });

    await order.save();
    console.log(`✅ Order saved: ${order._id} | email: ${userEmail} | total: ${order.totalAmount}`);
    res.status(201).json({ success: true, message: 'Order placed successfully!', order });
  } catch (err) {
    console.error('❌ Order save error:', err.message);
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/orders/my-orders  — user's own orders
// ─────────────────────────────────────────────────────────────────────────────
router.get('/my-orders', optionalAuth, async (req, res) => {
  try {
    const userId    = req.user?._id || req.user?.id || null;
    const userEmail = req.user?.email || req.query.email || null;

    if (!userId && !userEmail) {
      return res.status(401).json({ success: false, message: 'Authentication required' });
    }

    let query;
    if (userId && userEmail) {
      query = { $or: [{ userId }, { userEmail }] };
    } else if (userId) {
      query = { userId };
    } else {
      query = { userEmail };
    }

    const orders = await Order.find(query).sort({ createdAt: -1 }).lean();
    res.json({ success: true, orders });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/orders  — admin: all orders with optional filters
// ─────────────────────────────────────────────────────────────────────────────
router.get('/', optionalAuth, async (req, res) => {
  try {
    const { status, search } = req.query;
    const filter = {};
    if (status && status !== 'all') filter.status = status;
    if (search) {
      filter.$or = [
        { userName:          { $regex: search, $options: 'i' } },
        { userEmail:         { $regex: search, $options: 'i' } },
        { razorpayPaymentId: { $regex: search, $options: 'i' } },
        { trackingId:        { $regex: search, $options: 'i' } },
      ];
    }
    const orders = await Order.find(filter).sort({ createdAt: -1 }).lean();
    res.json({ success: true, orders });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// PATCH /api/orders/:id/status  — admin: update order status
// ─────────────────────────────────────────────────────────────────────────────
router.patch('/:id/status', async (req, res) => {
  try {
    const { status, trackingId } = req.body;
    const update = { status };
    if (trackingId) update.trackingId = trackingId;
    const order = await Order.findByIdAndUpdate(req.params.id, update, { new: true });
    if (!order) return res.status(404).json({ success: false, message: 'Order not found' });
    res.json({ success: true, order });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;