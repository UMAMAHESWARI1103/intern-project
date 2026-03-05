const express           = require('express');
const router            = express.Router();
const mongoose          = require('mongoose');
const Event             = require('../models/Event');
const EventRegistration = require('../models/EventRegistration');
const jwt               = require('jsonwebtoken');
const User              = require('../models/User');

// ─── HARDCODED SEED EVENTS (always shown, merged with DB events) ──────────────
const SEED_EVENTS = [
  {
    _id: 'seed_s1',
    title: 'Maha Shivaratri Celebrations',
    description: 'Grand celebration with special abhishekam, bhajans, and night-long pooja. All devotees are welcome to participate.',
    templeName: 'Sri Venkateswara Temple',
    templeId: 'seed',
    date: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000),
    time: '6:00 AM – 6:00 AM (Next day)',
    location: 'Tirupati, Andhra Pradesh',
    category: 'Festival',
    registrationFee: 0,
    isFree: true,
    maxParticipants: 500,
    registeredCount: 0,
    imageUrl: '',
    isActive: true,
    isSeed: true,
  },
  {
    _id: 'seed_s2',
    title: 'Brahmotsavam Special Darshan',
    description: 'Annual Brahmotsavam festival with special processions, cultural programs, and divine darshan.',
    templeName: 'Meenakshi Temple',
    templeId: 'seed',
    date: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
    time: '5:00 AM – 9:00 PM',
    location: 'Madurai, Tamil Nadu',
    category: 'Festival',
    registrationFee: 150,
    isFree: false,
    maxParticipants: 300,
    registeredCount: 0,
    imageUrl: '',
    isActive: true,
    isSeed: true,
  },
  {
    _id: 'seed_s3',
    title: 'Karthigai Deepam Pooja',
    description: 'Special Karthigai Deepam with thousands of lamps illuminating the temple.',
    templeName: 'Brihadeeswarar Temple',
    templeId: 'seed',
    date: new Date(Date.now() + 10 * 24 * 60 * 60 * 1000),
    time: '7:00 PM – 10:00 PM',
    location: 'Thanjavur, Tamil Nadu',
    category: 'Special',
    registrationFee: 0,
    isFree: true,
    maxParticipants: 200,
    registeredCount: 0,
    imageUrl: '',
    isActive: true,
    isSeed: true,
  },
  {
    _id: 'seed_s4',
    title: 'Satabhishekam Homam',
    description: 'Powerful homam ceremony for long life and prosperity.',
    templeName: 'Sri Venkateswara Temple',
    templeId: 'seed',
    date: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000),
    time: '8:00 AM – 12:00 PM',
    location: 'Tirupati, Andhra Pradesh',
    category: 'Pooja',
    registrationFee: 500,
    isFree: false,
    maxParticipants: 50,
    registeredCount: 0,
    imageUrl: '',
    isActive: true,
    isSeed: true,
  },
  {
    _id: 'seed_s5',
    title: 'Navratri Dance Festival',
    description: 'Nine nights of classical dance performances celebrating the divine feminine.',
    templeName: 'Meenakshi Temple',
    templeId: 'seed',
    date: new Date(Date.now() + 21 * 24 * 60 * 60 * 1000),
    time: '6:30 PM – 9:30 PM',
    location: 'Madurai, Tamil Nadu',
    category: 'Cultural',
    registrationFee: 0,
    isFree: true,
    maxParticipants: 400,
    registeredCount: 0,
    imageUrl: '',
    isActive: true,
    isSeed: true,
  },
];

const formatEvent = (e) => ({
  id:              e._id,
  title:           e.title,
  description:     e.description     || '',
  templeId:        e.templeId        || '',
  templeName:      e.templeName      || '',
  date:            e.date,
  time:            e.time            || '',
  location:        e.location        || '',
  category:        e.category        || 'Other',
  price:           e.registrationFee ?? 0,
  isFree:          e.isFree          ?? true,
  maxCapacity:     e.maxParticipants  ?? 100,
  registeredCount: e.registeredCount  ?? 0,
  imageUrl:        e.imageUrl         || '',
  isSeed:          e.isSeed           ?? false,
});

// ─── MIDDLEWARE ───────────────────────────────────────────────────────────────
const optionalAuth = async (req, res, next) => {
  try {
    const header = req.headers['authorization'] || '';
    const token  = header.startsWith('Bearer ') ? header.slice(7) : null;
    if (token) {
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      req.user = await User.findById(decoded.id).select('-password');
    }
  } catch (_) { req.user = null; }
  next();
};

const requireAuth = async (req, res, next) => {
  try {
    const header = req.headers['authorization'] || '';
    const token  = header.startsWith('Bearer ') ? header.slice(7) : null;
    if (!token) return res.status(401).json({ message: 'Authentication required.' });
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = await User.findById(decoded.id).select('-password');
    if (!req.user) return res.status(401).json({ message: 'User not found.' });
    next();
  } catch (err) {
    return res.status(401).json({ message: 'Invalid or expired token.' });
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/events  — returns SEED events + DB events merged
// ─────────────────────────────────────────────────────────────────────────────
router.get('/', async (req, res) => {
  try {
    // Always include seed events
    const seedFormatted = SEED_EVENTS.map(formatEvent);

    // Also fetch DB events (admin-added)
    let dbFormatted = [];
    try {
      const dbEvents = await Event.find({ isActive: true }).sort({ date: 1 });
      dbFormatted = dbEvents.map(formatEvent);
    } catch (_) {
      // DB fetch failed — still return seed events
    }

    // Merge: DB events first (newest admin additions), then seed events
    const merged = [...dbFormatted, ...seedFormatted];

    res.status(200).json(merged);
  } catch (err) {
    console.error('❌ GET /events error:', err);
    // Even on error, return seed events so app never shows empty
    res.status(200).json(SEED_EVENTS.map(formatEvent));
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/events/my-registrations
// ─────────────────────────────────────────────────────────────────────────────
router.get('/my-registrations', requireAuth, async (req, res) => {
  try {
    const registrations = await EventRegistration
      .find({ userId: req.user._id })
      .sort({ createdAt: -1 })
      .lean();
    const tagged = registrations.map(r => ({
      ...r,
      type:       'event',
      eventTitle: r.eventTitle || 'Event Registration',
      amount:     r.registrationFee || 0,
      status:     r.status || 'confirmed',
      date:       r.createdAt,
    }));
    res.status(200).json({ success: true, registrations: tagged });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// POST /api/events/sample-register
// ─────────────────────────────────────────────────────────────────────────────
router.post('/sample-register', optionalAuth, async (req, res) => {
  try {
    const { user_name, user_email, user_phone, eventId, eventTitle, templeName, eventDate } = req.body;
    if (!user_name || !user_email) {
      return res.status(400).json({ message: 'Name and email are required.' });
    }
    const existing = await EventRegistration.findOne({ sampleEventId: eventId, userEmail: user_email });
    if (existing) {
      return res.status(409).json({ message: 'You are already registered for this event.' });
    }
    const registration = new EventRegistration({
      eventId:       new mongoose.Types.ObjectId(),
      eventTitle:    eventTitle || 'Sample Event',
      templeName:    templeName || '',
      eventDate:     eventDate  || '',
      userId:        req.user?._id || null,
      userName:      user_name,
      userEmail:     user_email,
      userPhone:     user_phone || '',
      paymentStatus: 'free',
      status:        'confirmed',
      sampleEventId: eventId,
      isSampleEvent: true,
    });
    await registration.save();
    res.status(201).json({
      success: true,
      message: 'Registration saved!',
      registration: {
        id: registration._id, eventTitle: registration.eventTitle,
        userName: registration.userName, userEmail: registration.userEmail,
        status: registration.status,
      },
    });
  } catch (err) {
    if (err.code === 11000) return res.status(409).json({ message: 'Already registered.' });
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/events/:id
// ─────────────────────────────────────────────────────────────────────────────
router.get('/:id', async (req, res) => {
  try {
    // Check if it's a seed event
    const seedEvent = SEED_EVENTS.find(e => e._id === req.params.id);
    if (seedEvent) return res.status(200).json(formatEvent(seedEvent));

    const event = await Event.findById(req.params.id);
    if (!event) return res.status(404).json({ message: 'Event not found' });
    res.status(200).json(formatEvent(event));
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// POST /api/events/:eventId/register
// ─────────────────────────────────────────────────────────────────────────────
router.post('/:eventId/register', optionalAuth, async (req, res) => {
  try {
    const eventId = req.params.eventId;
    const { user_name, user_email, user_phone, razorpay_payment_id, razorpay_order_id, razorpay_signature } = req.body;
    if (!user_name || !user_email) {
      return res.status(400).json({ message: 'Name and email are required.' });
    }

    // Handle seed event registrations
    if (eventId.startsWith('seed_')) {
      const seedEvent = SEED_EVENTS.find(e => e._id === eventId);
      if (!seedEvent) return res.status(404).json({ message: 'Event not found.' });

      const existing = await EventRegistration.findOne({ sampleEventId: eventId, userEmail: user_email });
      if (existing) return res.status(409).json({ message: 'Already registered.' });

      const registration = new EventRegistration({
        eventId:       new mongoose.Types.ObjectId(),
        eventTitle:    seedEvent.title,
        templeName:    seedEvent.templeName,
        eventDate:     seedEvent.date,
        userId:        req.user?._id || null,
        userName:      user_name,
        userEmail:     user_email,
        userPhone:     user_phone || '',
        razorpayPaymentId: razorpay_payment_id || '',
        paymentStatus: razorpay_payment_id ? 'paid' : 'free',
        status:        'confirmed',
        sampleEventId: eventId,
        isSampleEvent: true,
      });
      await registration.save();
      return res.status(200).json({ success: true, message: 'Registration successful!', registration });
    }

    // Handle real DB event
    const event = await Event.findById(eventId);
    if (!event) return res.status(404).json({ message: 'Event not found.' });
    if (event.maxParticipants && event.registeredCount >= event.maxParticipants) {
      return res.status(400).json({ message: 'Event is full.' });
    }
    const existing = await EventRegistration.findOne({ eventId, userEmail: user_email });
    if (existing) return res.status(400).json({ message: 'Already registered.' });

    const registration = new EventRegistration({
      eventId,
      eventTitle:        event.title,
      templeName:        event.templeName      || '',
      eventDate:         event.date            || '',
      userId:            req.user?._id         || null,
      userName:          user_name,
      userEmail:         user_email,
      userPhone:         user_phone            || '',
      razorpayPaymentId: razorpay_payment_id   || '',
      razorpayOrderId:   razorpay_order_id     || '',
      razorpaySignature: razorpay_signature    || '',
      registrationFee:   event.registrationFee ?? 0,
      paymentStatus:     razorpay_payment_id   ? 'paid' : 'free',
      status:            'confirmed',
    });
    await registration.save();
    await Event.findByIdAndUpdate(eventId, { $inc: { registeredCount: 1 } });
    res.status(200).json({ success: true, message: 'Registration successful!', registration });
  } catch (err) {
    if (err.code === 11000) return res.status(400).json({ message: 'Already registered.' });
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

module.exports = router;