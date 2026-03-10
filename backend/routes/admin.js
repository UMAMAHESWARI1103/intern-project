// backend/routes/admin.js
const express  = require('express');
const router   = express.Router();
const mongoose = require('mongoose');
const jwt      = require('jsonwebtoken');

// ─────────────────────────────────────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────────────────────────────────────
const User     = require('../models/User');
const Temple   = require('../models/temple');
const Event    = require('../models/Event');
const Donation = require('../models/Donation');
const Priest   = require('../models/Priest');

// Product model (inline-safe: won't crash if file doesn't exist yet)
let Product;
try {
  Product = require('../models/Product');
} catch (_) {
  const productSchema = new mongoose.Schema({
    name:          { type: String, required: true, trim: true },
    description:   { type: String, default: '' },
    category:      { type: String, required: true },
    price:         { type: Number, required: true, min: 0 },
    originalPrice: { type: Number, default: 0 },
    imageUrl:      { type: String, default: '' },
    stock:         { type: Number, default: 0, min: 0 },
    tags:          [String],
    isBestseller:  { type: Boolean, default: false },
    isActive:      { type: Boolean, default: true },
    rating:        { type: Number, default: 4.5 },
    reviews:       { type: Number, default: 0 },
  }, { timestamps: true });
  Product = mongoose.models.Product || mongoose.model('Product', productSchema);
}

// Booking sub-models
const darshanSchema  = new mongoose.Schema({}, { strict: false, collection: 'darshanBookings'  });
const homamSchema    = new mongoose.Schema({}, { strict: false, collection: 'homamBookings'    });
const marriageSchema = new mongoose.Schema({}, { strict: false, collection: 'marriageBookings' });
const prasadamSchema = new mongoose.Schema({}, { strict: false, collection: 'prasadamOrders'   });
const orderSchema    = new mongoose.Schema({}, { strict: false, collection: 'orders'           });

const _DarshanBooking  = mongoose.models.DarshanBooking  || mongoose.model('DarshanBooking',  darshanSchema);
const _HomamBooking    = mongoose.models.HomamBooking    || mongoose.model('HomamBooking',    homamSchema);
const _MarriageBooking = mongoose.models.MarriageBooking || mongoose.model('MarriageBooking', marriageSchema);
const _PrasadamOrder   = mongoose.models.PrasadamOrder   || mongoose.model('PrasadamOrder',   prasadamSchema);
const Order            = mongoose.models.Order           || mongoose.model('Order',           orderSchema);

// ─────────────────────────────────────────────────────────────────────────────
// AUTH MIDDLEWARE
// ─────────────────────────────────────────────────────────────────────────────
const adminAuth = (req, res, next) => {
  const authHeader = req.headers['authorization'] || '';
  const token = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : null;
  if (!token) return res.status(401).json({ success: false, message: 'No token' });
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'secret');
    if (decoded.role !== 'admin') throw new Error('Not admin');
    req.admin = decoded;
    next();
  } catch {
    return res.status(403).json({ success: false, message: 'Forbidden' });
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// STATS
// ─────────────────────────────────────────────────────────────────────────────
router.get('/stats', async (req, res) => {
  try {
    let EventRegistration;
    try {
      EventRegistration = mongoose.models.EventRegistration ||
        mongoose.model('EventRegistration',
          new mongoose.Schema({}, { strict: false, collection: 'eventregistrations' }));
    } catch(e) {
      EventRegistration = mongoose.models.EventRegistration;
    }

    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const [
      totalUsers, totalTemples, totalEvents, totalProducts,
      totalDonationsAgg, darshanCount, homamCount,
      marriageCount, prasadamCount, totalOrders,
      totalEventReg, totalPriests, todayRevenueAgg,
    ] = await Promise.all([
      User.countDocuments(),
      Temple.countDocuments(),
      Event.countDocuments(),
      Product.countDocuments({ isActive: true }),
      Donation.aggregate([
        { $match: { paymentStatus: 'paid' } },
        { $group: { _id: null, total: { $sum: '$amount' } } }
      ]),
      _DarshanBooking.countDocuments(),
      _HomamBooking.countDocuments(),
      _MarriageBooking.countDocuments(),
      _PrasadamOrder.countDocuments(),
      Order.countDocuments(),
      EventRegistration ? EventRegistration.countDocuments() : Promise.resolve(0),
      Priest.countDocuments(),
      Promise.all([
        _DarshanBooking.aggregate([{ $match: { createdAt: { $gte: today } } }, { $group: { _id: null, t: { $sum: '$totalAmount' } } }]),
        _HomamBooking.aggregate([{ $match: { createdAt: { $gte: today } } }, { $group: { _id: null, t: { $sum: '$totalAmount' } } }]),
        _MarriageBooking.aggregate([{ $match: { createdAt: { $gte: today } } }, { $group: { _id: null, t: { $sum: '$totalAmount' } } }]),
        _PrasadamOrder.aggregate([{ $match: { createdAt: { $gte: today } } }, { $group: { _id: null, t: { $sum: '$totalAmount' } } }]),
        Order.aggregate([{ $match: { createdAt: { $gte: today } } }, { $group: { _id: null, t: { $sum: '$totalAmount' } } }]),
        Donation.aggregate([{ $match: { createdAt: { $gte: today }, paymentStatus: 'paid' } }, { $group: { _id: null, t: { $sum: '$amount' } } }]),
      ]).then(results => results.reduce((s, r) => s + (r[0]?.t || 0), 0)),
    ]);

    res.json({
      success: true,
      stats: {
        totalUsers, totalTemples, totalEvents, totalProducts,
        totalDonations:   totalDonationsAgg[0]?.total || 0,
        totalBookings:    darshanCount + homamCount + marriageCount + prasadamCount,
        totalOrders, totalEventReg, totalPriests,
        todayRevenue:     todayRevenueAgg || 0,
        bookingBreakdown: { darshan: darshanCount, homam: homamCount, marriage: marriageCount, prasadam: prasadamCount },
      }
    });
  } catch (err) {
    console.error('❌ Admin stats error:', err);
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// USERS
// ─────────────────────────────────────────────────────────────────────────────
router.get('/users', async (req, res) => {
  try {
    const users = await User.find({}, '-password').sort({ createdAt: -1 }).lean();

    const donationAgg = await Donation.aggregate([
      { $group: { _id: { $toLower: '$donorEmail' }, count: { $sum: 1 } } },
    ]);
    const donationMap = {};
    donationAgg.forEach(d => { if (d._id) donationMap[d._id] = d.count; });

    const bookingColls = [_DarshanBooking, _HomamBooking, _MarriageBooking, _PrasadamOrder];
    const bookingMap   = {};

    await Promise.all(
      bookingColls.map(async (Model) => {
        const agg = await Model.aggregate([
          { $group: { _id: '$userId', count: { $sum: 1 } } },
        ]);
        agg.forEach(b => {
          if (!b._id) return;
          const key = b._id.toString();
          bookingMap[key] = (bookingMap[key] || 0) + b.count;
        });
      })
    );

    const enriched = users.map(u => ({
      ...u,
      bookingsCount:  bookingMap[u._id?.toString()] ?? 0,
      donationsCount: donationMap[u.email?.toLowerCase()] ?? 0,
    }));

    res.json({ success: true, users: enriched });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.patch('/users/:id/toggle-block', async (req, res) => {
  try {
    const user = await User.findById(req.params.id);
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });
    user.isBlocked = !user.isBlocked;
    await user.save();
    res.json({ success: true, isBlocked: user.isBlocked });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.patch('/users/:id/role', async (req, res) => {
  try {
    const user = await User.findByIdAndUpdate(req.params.id, { role: req.body.role }, { new: true });
    res.json({ success: true, user });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.delete('/users/:id', async (req, res) => {
  try {
    await User.findByIdAndDelete(req.params.id);
    res.json({ success: true, message: 'User deleted' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// BOOKINGS
// ─────────────────────────────────────────────────────────────────────────────
router.get('/bookings', async (req, res) => {
  try {
    const [darshan, homam, marriage, prasadam] = await Promise.all([
      _DarshanBooking.find().sort({ createdAt: -1 }).lean(),
      _HomamBooking.find().sort({ createdAt: -1 }).lean(),
      _MarriageBooking.find().sort({ createdAt: -1 }).lean(),
      _PrasadamOrder.find().sort({ createdAt: -1 }).lean(),
    ]);
    const tag = (arr, type) => arr.map(b => ({ ...b, bookingType: type }));
    const all = [
      ...tag(darshan, 'darshan'), ...tag(homam, 'homam'),
      ...tag(marriage, 'marriage'), ...tag(prasadam, 'prasadam'),
    ].sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
    res.json({ success: true, bookings: all });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.patch('/bookings/:id/status', async (req, res) => {
  try {
    const { type, status } = req.body;
    const modelMap = {
      darshan: _DarshanBooking, homam: _HomamBooking,
      marriage: _MarriageBooking, prasadam: _PrasadamOrder,
    };
    const Model = modelMap[type];
    if (!Model) return res.status(400).json({ success: false, message: 'Invalid type' });
    await Model.findByIdAndUpdate(req.params.id, { status });
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// DONATIONS
// ─────────────────────────────────────────────────────────────────────────────
router.get('/donations', async (req, res) => {
  try {
    const donations = await Donation.find().sort({ createdAt: -1 }).lean();
    res.json({
      success: true,
      donations,
      total: donations.length,
      totalAmount: donations.reduce((s, d) => s + (d.amount || 0), 0),
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.patch('/donations/:id/status', async (req, res) => {
  try {
    await Donation.findByIdAndUpdate(req.params.id, { paymentStatus: req.body.status });
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// REPORTS
// ─────────────────────────────────────────────────────────────────────────────
router.get('/reports', async (req, res) => {
  try {
    const { period = 'month' } = req.query;
    const now = new Date();
    const periodStart = new Date();
    if      (period === 'today') { periodStart.setHours(0, 0, 0, 0); }
    else if (period === 'week')  { periodStart.setDate(now.getDate() - 7); }
    else if (period === 'year')  { periodStart.setFullYear(now.getFullYear() - 1); }
    else                         { periodStart.setMonth(now.getMonth() - 1); }

    const dateFilter = { createdAt: { $gte: periodStart } };

    const [bookingRevenue, donationRevenue, orderRevenue, allDonations, temples] =
      await Promise.all([
        Promise.all([
          _DarshanBooking.aggregate([{ $match: { ...dateFilter, status: { $ne: 'cancelled' } } }, { $group: { _id: null, total: { $sum: '$totalAmount' } } }]),
          _HomamBooking.aggregate([{ $match: { ...dateFilter, status: { $ne: 'cancelled' } } }, { $group: { _id: null, total: { $sum: '$totalAmount' } } }]),
          _MarriageBooking.aggregate([{ $match: { ...dateFilter, status: { $ne: 'cancelled' } } }, { $group: { _id: null, total: { $sum: '$totalAmount' } } }]),
          _PrasadamOrder.aggregate([{ $match: { ...dateFilter, status: { $ne: 'cancelled' } } }, { $group: { _id: null, total: { $sum: '$totalAmount' } } }]),
        ]).then(results => results.reduce((sum, r) => sum + (r[0]?.total || 0), 0)),
        Donation.aggregate([{ $match: { ...dateFilter, paymentStatus: 'paid' } }, { $group: { _id: null, total: { $sum: '$amount' } } }]).then(r => r[0]?.total || 0),
        Order.aggregate([{ $match: { ...dateFilter, status: { $nin: ['cancelled'] } } }, { $group: { _id: null, total: { $sum: '$totalAmount' } } }]).then(r => r[0]?.total || 0),
        Donation.find({ paymentStatus: 'paid' }).lean(),
        Temple.find().lean(),
      ]);

    const totalRevenue = bookingRevenue + donationRevenue + orderRevenue;

    const donationCategoryMap = {};
    const totalDonations = allDonations.reduce((s, d) => s + (d.amount || 0), 0);
    for (const d of allDonations) {
      const cat = d.category || 'General';
      donationCategoryMap[cat] = (donationCategoryMap[cat] || 0) + (d.amount || 0);
    }
    const donationsByCategory = Object.entries(donationCategoryMap)
      .map(([category, amount]) => ({ category, amount, percent: totalDonations > 0 ? Math.round((amount / totalDonations) * 100) : 0 }))
      .sort((a, b) => b.amount - a.amount).slice(0, 6);

    const [darshanCounts, homamCounts, marriageCounts, prasadamCounts] = await Promise.all([
      _DarshanBooking.aggregate([{ $group: { _id: '$templeName', count: { $sum: 1 }, revenue: { $sum: '$totalAmount' } } }]),
      _HomamBooking.aggregate([{ $group: { _id: '$templeName', count: { $sum: 1 }, revenue: { $sum: '$totalAmount' } } }]),
      _MarriageBooking.aggregate([{ $group: { _id: '$templeName', count: { $sum: 1 }, revenue: { $sum: '$totalAmount' } } }]),
      _PrasadamOrder.aggregate([{ $group: { _id: '$templeName', count: { $sum: 1 }, revenue: { $sum: '$totalAmount' } } }]),
    ]);
    const templeMap = {};
    const addToMap = (arr) => { for (const item of arr) { if (!item._id) continue; if (!templeMap[item._id]) templeMap[item._id] = { bookings: 0, revenue: 0 }; templeMap[item._id].bookings += item.count || 0; templeMap[item._id].revenue += item.revenue || 0; } };
    addToMap(darshanCounts); addToMap(homamCounts); addToMap(marriageCounts); addToMap(prasadamCounts);
    const donationsByTemple = await Donation.aggregate([{ $group: { _id: '$templeName', donations: { $sum: '$amount' } } }]);
    for (const d of donationsByTemple) { if (!d._id) continue; if (!templeMap[d._id]) templeMap[d._id] = { bookings: 0, revenue: 0 }; templeMap[d._id].revenue += d.donations || 0; }
    const topTemples = Object.entries(templeMap)
      .map(([name, data]) => { const t = temples.find(t => t.name?.toLowerCase() === name.toLowerCase()); return { name, bookings: data.bookings, donations: data.revenue, rating: t?.rating ?? 0 }; })
      .filter(t => t.name && t.name !== 'undefined').sort((a, b) => b.bookings - a.bookings).slice(0, 5);

    const monthNames = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    const monthlyTrend = [];
    for (let i = 5; i >= 0; i--) {
      const d = new Date(); d.setMonth(d.getMonth() - i);
      const start = new Date(d.getFullYear(), d.getMonth(), 1);
      const end   = new Date(d.getFullYear(), d.getMonth() + 1, 1);
      const [dc, hc, mc, pc] = await Promise.all([
        _DarshanBooking.countDocuments({ createdAt: { $gte: start, $lt: end } }),
        _HomamBooking.countDocuments({ createdAt: { $gte: start, $lt: end } }),
        _MarriageBooking.countDocuments({ createdAt: { $gte: start, $lt: end } }),
        _PrasadamOrder.countDocuments({ createdAt: { $gte: start, $lt: end } }),
      ]);
      monthlyTrend.push({ month: monthNames[d.getMonth()], darshan: dc, homam: hc, marriage: mc, prasadam: pc, total: dc+hc+mc+pc });
    }

    res.json({ success: true, reports: { bookingsRevenue: bookingRevenue, donationsRevenue: donationRevenue, ecommerceRevenue: Math.round(orderRevenue * 0.6), ordersRevenue: orderRevenue, totalRevenue, growth: '+0%', topTemples, donationsByCategory, monthlyTrend } });
  } catch (err) {
    console.error('❌ Admin reports error:', err);
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// TEMPLES
// ─────────────────────────────────────────────────────────────────────────────
router.get('/temples', async (req, res) => {
  try {
    const temples = await Temple.find().sort({ createdAt: -1 }).lean();
    res.json({ success: true, temples });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.post('/temples', async (req, res) => {
  try {
    const temple = await Temple.create(req.body);
    res.json({ success: true, temple });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.put('/temples/:id', async (req, res) => {
  try {
    const temple = await Temple.findByIdAndUpdate(req.params.id, req.body, { new: true });
    res.json({ success: true, temple });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.delete('/temples/:id', async (req, res) => {
  try {
    await Temple.findByIdAndDelete(req.params.id);
    res.json({ success: true, message: 'Temple deleted' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// EVENTS (admin CRUD)
// ─────────────────────────────────────────────────────────────────────────────
router.get('/events', async (req, res) => {
  try {
    const events = await Event.find().sort({ createdAt: -1 }).lean();
    res.json({ success: true, events });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.post('/events', async (req, res) => {
  try {
    const { title, date } = req.body;
    if (!title || !date) return res.status(400).json({ message: 'Title and date are required.' });
    const event = await Event.create(req.body);
    res.status(201).json({ success: true, event, id: event._id });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.put('/events/:id', async (req, res) => {
  try {
    const event = await Event.findByIdAndUpdate(req.params.id, req.body, { new: true });
    if (!event) return res.status(404).json({ message: 'Event not found.' });
    res.json({ success: true, event });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.delete('/events/:id', async (req, res) => {
  try {
    await Event.findByIdAndDelete(req.params.id);
    res.json({ success: true, message: 'Event deleted' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// EVENT REGISTRATIONS
// ─────────────────────────────────────────────────────────────────────────────
router.get('/event-registrations', async (req, res) => {
  try {
    let EventRegistration;
    try {
      EventRegistration = mongoose.models.EventRegistration ||
        mongoose.model('EventRegistration',
          new mongoose.Schema({}, { strict: false, collection: 'eventregistrations' }));
    } catch(e) { EventRegistration = mongoose.models.EventRegistration; }
    if (!EventRegistration) return res.json({ success: true, registrations: [] });
    const registrations = await EventRegistration.find().sort({ createdAt: -1 }).lean();
    res.json({ success: true, registrations });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// PRODUCTS (admin CRUD)
// ─────────────────────────────────────────────────────────────────────────────
router.get('/products', async (req, res) => {
  try {
    const filter = {};
    if (req.query.category && req.query.category !== 'all') {
      filter.category = req.query.category;
    }
    if (req.query.search) {
      filter.$or = [
        { name:     { $regex: req.query.search, $options: 'i' } },
        { category: { $regex: req.query.search, $options: 'i' } },
        { tags:     { $in: [new RegExp(req.query.search, 'i')] } },
      ];
    }
    const products = await Product.find(filter).sort({ createdAt: -1 });
    res.status(200).json(products);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.post('/products', async (req, res) => {
  try {
    const { name, category, price } = req.body;
    if (!name || !category || price === undefined) {
      return res.status(400).json({ message: 'name, category and price are required.' });
    }
    const product = await Product.create({
      name,
      description:   req.body.description   ?? '',
      category,
      price,
      originalPrice: req.body.originalPrice ?? 0,
      imageUrl:      req.body.imageUrl      ?? '',
      stock:         req.body.stock         ?? 0,
      tags:          req.body.tags          ?? [],
      isBestseller:  req.body.isBestseller  ?? false,
      isActive:      req.body.isActive      ?? true,
    });
    res.status(201).json({ message: 'Product created!', product });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.put('/products/:id', async (req, res) => {
  try {
    const updated = await Product.findByIdAndUpdate(
      req.params.id,
      { ...req.body },
      { new: true, runValidators: true }
    );
    if (!updated) return res.status(404).json({ message: 'Product not found.' });
    res.status(200).json({ message: 'Product updated!', product: updated });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.delete('/products/:id', async (req, res) => {
  try {
    await Product.findByIdAndDelete(req.params.id);
    res.status(200).json({ message: 'Product deleted.' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// PRAYERS (admin CRUD)
// ─────────────────────────────────────────────────────────────────────────────
let Prayer;
try { Prayer = require('../models/Prayer'); } catch (_) {
  const prayerSchema = new mongoose.Schema({}, { strict: false, collection: 'prayers' });
  Prayer = mongoose.models.Prayer || mongoose.model('Prayer', prayerSchema);
}

router.get('/prayers', async (req, res) => {
  try {
    const prayers = await Prayer.find().sort({ createdAt: -1 }).lean();
    res.json({ success: true, prayers });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.post('/prayers', async (req, res) => {
  try {
    const prayer = await Prayer.create(req.body);
    res.status(201).json({ success: true, prayer });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.put('/prayers/:id', async (req, res) => {
  try {
    const prayer = await Prayer.findByIdAndUpdate(req.params.id, req.body, { new: true });
    res.json({ success: true, prayer });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.delete('/prayers/:id', async (req, res) => {
  try {
    await Prayer.findByIdAndDelete(req.params.id);
    res.json({ success: true, message: 'Prayer deleted' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// PRIESTS (admin CRUD)
// ─────────────────────────────────────────────────────────────────────────────

// GET all priests (approved + pending)
router.get('/priests', async (req, res) => {
  try {
    const priests = await Priest.find().sort({ createdAt: -1 }).lean();
    res.json({ success: true, priests });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// POST add new priest (from admin form OR priest registration form)
router.post('/priests', async (req, res) => {
  try {
    const existing = await Priest.findOne({ email: req.body.email });
    if (existing) {
      return res.status(400).json({ success: false, message: 'Email already registered' });
    }
    const priest = await Priest.create(req.body);
    res.status(201).json({ success: true, priest });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// PATCH approve / revoke a priest
router.patch('/priests/:id/approve', async (req, res) => {
  try {
    const priest = await Priest.findByIdAndUpdate(
      req.params.id,
      { isApproved: req.body.isApproved },
      { new: true }
    );
    if (!priest) return res.status(404).json({ success: false, message: 'Priest not found' });
    res.json({ success: true, priest });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// DELETE a priest
router.delete('/priests/:id', async (req, res) => {
  try {
    await Priest.findByIdAndDelete(req.params.id);
    res.json({ success: true, message: 'Priest deleted' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
module.exports = router;