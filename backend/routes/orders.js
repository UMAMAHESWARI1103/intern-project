// backend/routes/orders.js
const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const jwt = require('jsonwebtoken');

// ─── AUTH MIDDLEWARE ──────────────────────────────────────────────────────────
const auth = (req, res, next) => {
  const token = req.headers.authorization?.split(' ')[1];
  if (!token) return res.status(401).json({ success: false, message: 'No token' });
  try {
    req.user = jwt.verify(token, process.env.JWT_SECRET);
    next();
  } catch {
    res.status(401).json({ success: false, message: 'Invalid token' });
  }
};

// ─── ORDER SCHEMA ─────────────────────────────────────────────────────────────
const orderSchema = new mongoose.Schema({
  userId:          { type: String, required: true },
  userName:        { type: String, default: '' },
  userEmail:       { type: String, default: '' },
  userPhone:       { type: String, default: '' },
  deliveryAddress: { type: String, default: '' },
  items: [{
    productId: { type: String },
    name:      { type: String },
    price:     { type: Number },
    quantity:  { type: Number },
    imageUrl:  { type: String, default: '' },
  }],
  totalAmount:       { type: Number, required: true },
  razorpayPaymentId: { type: String, default: '' },
  razorpayOrderId:   { type: String, default: '' },
  razorpaySignature: { type: String, default: '' },
  paymentStatus: {
    type: String,
    enum: ['paid', 'pending', 'failed'],
    default: 'pending',
  },
  status: {
    type: String,
    enum: ['pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled'],
    default: 'pending',
  },
  cancelReason: { type: String, default: '' },
}, { timestamps: true });

const Order = mongoose.models.Order || mongoose.model('Order', orderSchema, 'orders');

// ─── CREATE ORDER ─────────────────────────────────────────────────────────────
router.post('/', auth, async (req, res) => {
  try {
    const order = new Order({
      ...req.body,
      userId: req.user.id || req.user._id,
    });
    await order.save();
    res.json({ success: true, order });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─── GET USER'S OWN ORDERS ────────────────────────────────────────────────────
router.get('/my-orders', auth, async (req, res) => {
  try {
    const userId = req.user.id || req.user._id;
    const orders = await Order.find({ userId }).sort({ createdAt: -1 });
    res.json({ success: true, orders });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─── GET ALL ORDERS (ADMIN) — supports ?status= and ?search= ─────────────────
router.get('/admin/all', auth, async (req, res) => {
  try {
    const { status, search } = req.query;

    // Build filter
    const filter = {};

    // Filter by status (if provided and not 'all')
    if (status && status !== 'all') {
      filter.status = status;
    }

    // Filter by search — matches userName, userEmail, or _id
    if (search && search.trim() !== '') {
      const s = search.trim();
      filter.$or = [
        { userName:  { $regex: s, $options: 'i' } },
        { userEmail: { $regex: s, $options: 'i' } },
        { userPhone: { $regex: s, $options: 'i' } },
        // Match last 8 chars of order ID
        ...(s.length >= 4
          ? [{ $expr: { $regexMatch: { input: { $toString: '$_id' }, regex: s, options: 'i' } } }]
          : []),
      ];
    }

    const orders = await Order.find(filter).sort({ createdAt: -1 });
    res.json({ success: true, orders });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─── GET SINGLE ORDER ─────────────────────────────────────────────────────────
router.get('/:id', auth, async (req, res) => {
  try {
    const order = await Order.findById(req.params.id);
    if (!order) return res.status(404).json({ success: false, message: 'Order not found' });
    res.json({ success: true, order });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─── USER CANCEL ORDER ────────────────────────────────────────────────────────
router.patch('/:id/cancel', auth, async (req, res) => {
  try {
    const userId = req.user.id || req.user._id;
    const order  = await Order.findById(req.params.id);

    if (!order) {
      return res.status(404).json({ success: false, message: 'Order not found' });
    }
    if (order.userId.toString() !== userId.toString()) {
      return res.status(403).json({ success: false, message: 'Not your order' });
    }
    if (['shipped', 'delivered', 'cancelled'].includes(order.status)) {
      return res.status(400).json({
        success: false,
        message: `Cannot cancel order with status: ${order.status}`,
      });
    }

    order.status       = 'cancelled';
    order.cancelReason = req.body.reason || 'Cancelled by user';
    await order.save();

    res.json({ success: true, order });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─── ADMIN UPDATE ORDER STATUS ────────────────────────────────────────────────
router.patch('/:id/status', auth, async (req, res) => {
  try {
    const { status, cancelReason, trackingId } = req.body;
    const update = { status };
    if (cancelReason) update.cancelReason = cancelReason;
    if (trackingId)   update.trackingId   = trackingId;

    const order = await Order.findByIdAndUpdate(
      req.params.id,
      update,
      { new: true },
    );
    if (!order) {
      return res.status(404).json({ success: false, message: 'Order not found' });
    }
    res.json({ success: true, order });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;