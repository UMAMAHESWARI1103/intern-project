const express  = require('express');
const router   = express.Router();
const mongoose = require('mongoose');
const jwt      = require('jsonwebtoken');

// ─────────────────────────────────────────────────────────────────────────────
// 🔍 DUPLICATE COLLECTION CHECKER — runs on startup
// ─────────────────────────────────────────────────────────────────────────────
async function checkDuplicateCollections() {
  try {
    const db = mongoose.connection.db;
    const collections = await db.listCollections().toArray();
    const names = collections.map(c => c.name);

    console.log('\n📦 Collections in DB:', names);

    const expectedCorrect = [
      'darshanbookings',
      'homambookings',
      'marriagebookings',
      'prasadamorders',
    ];

    const wrongNames = [
      'darshanBookings',
      'homamBookings',
      'marriageBookings',
      'prasadamOrders',
    ];

    console.log('\n🔍 Checking for duplicate/wrong collections...');

    wrongNames.forEach(wrong => {
      if (names.includes(wrong)) {
        console.warn(`⚠️  WRONG COLLECTION FOUND: "${wrong}" — should be "${wrong.toLowerCase()}"`);
        console.warn(`   ➡️  Run: db.${wrong}.drop() in MongoDB Shell`);
      }
    });

    expectedCorrect.forEach(correct => {
      if (names.includes(correct)) {
        console.log(`✅ Correct collection exists: "${correct}"`);
      } else {
        console.log(`ℹ️  Collection not yet created: "${correct}" (will be created on first insert)`);
      }
    });

    console.log(''); // empty line for readability
  } catch (err) {
    console.error('❌ Error checking collections:', err.message);
  }
}

// Run checker when DB is ready
mongoose.connection.once('open', () => {
  checkDuplicateCollections();
});

// ─────────────────────────────────────────────────────────────────────────────
// OPTIONAL AUTH
// ─────────────────────────────────────────────────────────────────────────────
function optionalAuth(req, res, next) {
  try {
    const header = req.headers['authorization'] || '';
    const token  = header.startsWith('Bearer ') ? header.slice(7) : null;
    if (token) {
      req.user = jwt.verify(token, process.env.JWT_SECRET || 'secret');
    }
  } catch (_) {}
  next();
}

router.use(optionalAuth);

// ─────────────────────────────────────────────────────────────────────────────
// SCHEMAS — base fields shared across all booking types
// ─────────────────────────────────────────────────────────────────────────────
const baseFields = {
  userId:            { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
  userEmail:         { type: String, default: '' },
  userName:          { type: String, default: '' },
  userPhone:         { type: String, default: '' },
  razorpayPaymentId: { type: String, default: '' },
  razorpayOrderId:   { type: String, default: '' },
  razorpaySignature: { type: String, default: '' },
  totalAmount:       { type: Number, default: 0 },
  status:            { type: String, default: 'confirmed',
                       enum: ['pending','confirmed','completed','cancelled'] },
};

// ─────────────────────────────────────────────────────────────────────────────
// MODELS
// ✅ 3rd argument forces exact collection name — prevents duplicates
// ─────────────────────────────────────────────────────────────────────────────

const DarshanBooking = mongoose.models.DarshanBooking || mongoose.model(
  'DarshanBooking',
  new mongoose.Schema({
    ...baseFields,
    templeName:      { type: String, default: '' },
    templeId:        { type: String, default: '' },
    darshanType:     { type: String, default: 'Normal' },
    date:            { type: String, default: '' },
    timeSlot:        { type: String, default: '' },
    numberOfPersons: { type: Number, default: 1 },
  }, { timestamps: true }),
  'darshanbookings'   // ✅ forced collection name — no duplicates
);

const PrasadamOrder = mongoose.models.PrasadamOrder || mongoose.model(
  'PrasadamOrder',
  new mongoose.Schema({
    ...baseFields,
    templeName: { type: String, default: '' },
    items:      { type: Array,  default: [] },
  }, { timestamps: true }),
  'prasadamorders'    // ✅ forced collection name — no duplicates
);

const HomamBooking = mongoose.models.HomamBooking || mongoose.model(
  'HomamBooking',
  new mongoose.Schema({
    ...baseFields,
    templeName:  { type: String, default: '' },
    templeId:    { type: String, default: '' },
    homamType:   { type: String, default: '' },
    date:        { type: String, default: '' },
    timeSlot:    { type: String, default: '' },
    iyer:        { type: String, default: 'To be assigned' },
    specialNote: { type: String, default: '' },
  }, { timestamps: true }),
  'homambookings'     // ✅ forced collection name — no duplicates
);

const MarriageBooking = mongoose.models.MarriageBooking || mongoose.model(
  'MarriageBooking',
  new mongoose.Schema({
    ...baseFields,
    templeName:  { type: String, default: '' },
    templeId:    { type: String, default: '' },
    groomName:   { type: String, default: '' },
    brideName:   { type: String, default: '' },
    weddingDate: { type: String, default: '' },
    timeSlot:    { type: String, default: '' },
    guestCount:  { type: Number, default: 0 },
    specialNote: { type: String, default: '' },
  }, { timestamps: true }),
  'marriagebookings'  // ✅ forced collection name — no duplicates
);

// ─────────────────────────────────────────────────────────────────────────────
// HELPER — converts JWT string id to proper ObjectId
// ─────────────────────────────────────────────────────────────────────────────
function getAuthInfo(req) {
  const rawId = req.user?._id || req.user?.id || req.body.userId || null;
  const userId = rawId && mongoose.Types.ObjectId.isValid(rawId)
    ? new mongoose.Types.ObjectId(rawId.toString())
    : null;
  const userEmail = req.user?.email || req.body.userEmail || '';
  return { userId, userEmail };
}

// ─────────────────────────────────────────────────────────────────────────────
// POST /api/bookings/darshan
// ─────────────────────────────────────────────────────────────────────────────
router.post('/darshan', async (req, res) => {
  try {
    const { userId, userEmail } = getAuthInfo(req);
    const booking = new DarshanBooking({
      ...req.body,
      userId,
      userEmail,
      totalAmount:     Number(req.body.totalAmount)     || 0,
      numberOfPersons: Number(req.body.numberOfPersons) || 1,
    });
    await booking.save();
    console.log(`✅ Darshan saved to "darshanbookings": ${booking._id}`);
    res.status(201).json({ success: true, message: 'Darshan booking confirmed!', booking });
  } catch (err) {
    console.error('❌ Darshan error:', err.message);
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// POST /api/bookings/prasadam
// ─────────────────────────────────────────────────────────────────────────────
router.post('/prasadam', async (req, res) => {
  try {
    const { userId, userEmail } = getAuthInfo(req);
    const order = new PrasadamOrder({
      ...req.body,
      userId,
      userEmail,
      totalAmount: Number(req.body.totalAmount) || 0,
    });
    await order.save();
    console.log(`✅ Prasadam saved to "prasadamorders": ${order._id}`);
    res.status(201).json({ success: true, message: 'Prasadam order confirmed!', order });
  } catch (err) {
    console.error('❌ Prasadam error:', err.message);
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// POST /api/bookings/homam
// ─────────────────────────────────────────────────────────────────────────────
router.post('/homam', async (req, res) => {
  try {
    const { userId, userEmail } = getAuthInfo(req);
    const booking = new HomamBooking({
      ...req.body,
      userId,
      userEmail,
      totalAmount: Number(req.body.totalAmount) || 0,
    });
    await booking.save();
    console.log(`✅ Homam saved to "homambookings": ${booking._id}`);
    res.status(201).json({ success: true, message: 'Homam booking confirmed!', booking });
  } catch (err) {
    console.error('❌ Homam error:', err.message);
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// POST /api/bookings/marriage
// ─────────────────────────────────────────────────────────────────────────────
router.post('/marriage', async (req, res) => {
  try {
    const { userId, userEmail } = getAuthInfo(req);
    const booking = new MarriageBooking({
      ...req.body,
      userId,
      userEmail,
      totalAmount: Number(req.body.totalAmount) || 0,
      guestCount:  Number(req.body.guestCount)  || 0,
    });
    await booking.save();
    console.log(`✅ Marriage saved to "marriagebookings": ${booking._id}`);
    res.status(201).json({ success: true, message: 'Marriage booking confirmed!', booking });
  } catch (err) {
    console.error('❌ Marriage error:', err.message);
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/bookings/my-bookings
// ─────────────────────────────────────────────────────────────────────────────
router.get('/my-bookings', async (req, res) => {
  try {
    const rawId     = req.user?._id || req.user?.id || null;
    const userId    = rawId && mongoose.Types.ObjectId.isValid(rawId)
      ? new mongoose.Types.ObjectId(rawId.toString())
      : null;
    const userEmail = req.user?.email || req.query.email || null;

    if (!userId && !userEmail) {
      return res.status(401).json({ success: false, message: 'Authentication required.' });
    }

    let query;
    if (userId && userEmail) {
      query = { $or: [{ userId }, { userEmail }] };
    } else if (userId) {
      query = { userId };
    } else {
      query = { userEmail };
    }

    console.log(`📋 my-bookings — userId:${userId} email:${userEmail}`);

    const [darshans, prasadams, homams, marriages] = await Promise.all([
      DarshanBooking.find(query).sort({ createdAt: -1 }).lean(),
      PrasadamOrder.find(query).sort({ createdAt: -1 }).lean(),
      HomamBooking.find(query).sort({ createdAt: -1 }).lean(),
      MarriageBooking.find(query).sort({ createdAt: -1 }).lean(),
    ]);

    console.log(`📋 Found — darshan:${darshans.length} prasadam:${prasadams.length} homam:${homams.length} marriage:${marriages.length}`);

    const tagged = [
      ...darshans.map(d  => ({ ...d, type: 'darshan',  amount: d.totalAmount })),
      ...prasadams.map(p => ({ ...p, type: 'prasadam', amount: p.totalAmount })),
      ...homams.map(h    => ({ ...h, type: 'homam',    amount: h.totalAmount })),
      ...marriages.map(m => ({ ...m, type: 'marriage', amount: m.totalAmount })),
    ].sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));

    res.status(200).json({ success: true, bookings: tagged });
  } catch (err) {
    console.error('❌ my-bookings error:', err);
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// ADMIN — get all bookings by type
// ─────────────────────────────────────────────────────────────────────────────
router.get('/darshan',  async (req, res) => {
  try { res.json(await DarshanBooking.find().sort({ createdAt: -1 })); }
  catch (err) { res.status(500).json({ message: err.message }); }
});
router.get('/prasadam', async (req, res) => {
  try { res.json(await PrasadamOrder.find().sort({ createdAt: -1 })); }
  catch (err) { res.status(500).json({ message: err.message }); }
});
router.get('/homam',    async (req, res) => {
  try { res.json(await HomamBooking.find().sort({ createdAt: -1 })); }
  catch (err) { res.status(500).json({ message: err.message }); }
});
router.get('/marriage', async (req, res) => {
  try { res.json(await MarriageBooking.find().sort({ createdAt: -1 })); }
  catch (err) { res.status(500).json({ message: err.message }); }
});

module.exports = router;