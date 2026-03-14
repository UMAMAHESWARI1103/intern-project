// backend/routes/mlRecommendations.js
// ✅ Pure Node.js recommendation engine — no Python needed
// Algorithm:
//   1. Content-based filtering  — user's own booking/donation history
//   2. Collaborative filtering  — what similar users booked
//   3. Popularity scoring       — most booked temples get higher score
//   4. Weighted final score     — combines all three

const express  = require('express');
const router   = express.Router();
const mongoose = require('mongoose');
const jwt      = require('jsonwebtoken');

// ─────────────────────────────────────────────────────────────────────────────
// AUTH
// ─────────────────────────────────────────────────────────────────────────────
function optionalAuth(req, res, next) {
  try {
    const header = req.headers['authorization'] || '';
    const token  = header.startsWith('Bearer ') ? header.slice(7) : null;
    if (token) req.user = jwt.verify(token, process.env.JWT_SECRET || 'secret');
  } catch (_) {}
  next();
}
router.use(optionalAuth);

// ─────────────────────────────────────────────────────────────────────────────
// MODELS (reuse existing or define lightweight versions)
// ─────────────────────────────────────────────────────────────────────────────
const Temple = mongoose.models.Temple || mongoose.model('Temple',
  new mongoose.Schema({
    name: String, location: String, deity: String,
    description: String, festivals: [String],
    lat: Number, lon: Number, latitude: Number, longitude: Number,
  }, { strict: false })
);

const DarshanBooking = mongoose.models.DarshanBooking ||
  mongoose.model('DarshanBooking', new mongoose.Schema({
    userId: mongoose.Schema.Types.ObjectId,
    userEmail: String, templeName: String, templeId: String,
    darshanType: String, totalAmount: Number, createdAt: Date,
  }, { strict: false, timestamps: true }));

const HomamBooking = mongoose.models.HomamBooking ||
  mongoose.model('HomamBooking', new mongoose.Schema({
    userId: mongoose.Schema.Types.ObjectId,
    userEmail: String, templeName: String, templeId: String,
    homamType: String, totalAmount: Number, createdAt: Date,
  }, { strict: false, timestamps: true }));

const MarriageBooking = mongoose.models.MarriageBooking ||
  mongoose.model('MarriageBooking', new mongoose.Schema({
    userId: mongoose.Schema.Types.ObjectId,
    userEmail: String, templeName: String, templeId: String,
    totalAmount: Number, createdAt: Date,
  }, { strict: false, timestamps: true }));

const Donation = mongoose.models.Donation ||
  mongoose.model('Donation', new mongoose.Schema({
    userId: mongoose.Schema.Types.ObjectId,
    userEmail: String, templeName: String, templeId: String,
    amount: Number, createdAt: Date,
  }, { strict: false, timestamps: true }));

// ─────────────────────────────────────────────────────────────────────────────
// ALGORITHM HELPERS
// ─────────────────────────────────────────────────────────────────────────────

// Recency weight: bookings closer to today score higher
function recencyWeight(createdAt) {
  const days = (Date.now() - new Date(createdAt).getTime()) / (1000 * 60 * 60 * 24);
  return Math.exp(-days / 30); // exponential decay over 30 days
}

// Extract deity category from deity string
function deityCategory(deity = '') {
  const d = deity.toLowerCase();
  if (d.includes('murugan') || d.includes('kartikeya') || d.includes('subramanya')) return 'murugan';
  if (d.includes('shiva') || d.includes('siva') || d.includes('lingam') || d.includes('nataraja')) return 'shiva';
  if (d.includes('vishnu') || d.includes('perumal') || d.includes('venkatesh') || d.includes('balaji')) return 'vishnu';
  if (d.includes('devi') || d.includes('amman') || d.includes('durga') || d.includes('lakshmi') || d.includes('saraswati') || d.includes('kali')) return 'devi';
  if (d.includes('ganesh') || d.includes('ganesha') || d.includes('vinayaka') || d.includes('pillayar')) return 'ganesh';
  if (d.includes('hanuman') || d.includes('anjaneya')) return 'hanuman';
  return 'other';
}

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/ml-recommendations/:userEmail
// ─────────────────────────────────────────────────────────────────────────────
router.get('/:userEmail', async (req, res) => {
  try {
    const { userEmail } = req.params;

    // ── 1. Load all temples ───────────────────────────────────
    const allTemples = await Temple.find({}).lean();
    if (!allTemples.length) {
      return res.json({ success: true, type: 'popular', temples: [], message: 'No temples found' });
    }

    // ── 2. Load user's own activity ───────────────────────────
    const userQuery = { $or: [{ userEmail }, { userEmail: userEmail.toLowerCase() }] };
    const [myDarshans, myHomams, myMarriages, myDonations] = await Promise.all([
      DarshanBooking.find(userQuery).lean(),
      HomamBooking.find(userQuery).lean(),
      MarriageBooking.find(userQuery).lean(),
      Donation.find(userQuery).lean(),
    ]);

    const myActivity = [...myDarshans, ...myHomams, ...myMarriages, ...myDonations];
    const hasHistory = myActivity.length > 0;

    // ── 3. Load ALL bookings for collaborative filtering ──────
    const [allDarshans, allHomams, allMarriages, allDonations] = await Promise.all([
      DarshanBooking.find({}).lean(),
      HomamBooking.find({}).lean(),
      MarriageBooking.find({}).lean(),
      Donation.find({}).lean(),
    ]);
    const allActivity = [...allDarshans, ...allHomams, ...allMarriages, ...allDonations];

    // ── 4. POPULARITY SCORE — count bookings per temple ──────
    const popularityMap = {};
    for (const a of allActivity) {
      const key = (a.templeName || '').trim().toLowerCase();
      if (!key) continue;
      popularityMap[key] = (popularityMap[key] || 0) + 1 + (a.totalAmount || a.amount || 0) * 0.001;
    }

    // Normalize popularity to 0–100
    const maxPop = Math.max(...Object.values(popularityMap), 1);
    for (const k in popularityMap) popularityMap[k] = (popularityMap[k] / maxPop) * 100;

    // ── 5. CONTENT-BASED SCORE — user's preferred deity/temple
    const myTempleNames  = new Set();
    const myDeityWeights = {};

    for (const a of myActivity) {
      const tName = (a.templeName || '').trim().toLowerCase();
      if (tName) myTempleNames.add(tName);

      // Find this temple's deity
      const temple = allTemples.find(t =>
        (t.name || '').trim().toLowerCase() === tName);
      if (temple) {
        const cat = deityCategory(temple.deity || '');
        const w   = recencyWeight(a.createdAt) * (1 + (a.totalAmount || a.amount || 0) * 0.001);
        myDeityWeights[cat] = (myDeityWeights[cat] || 0) + w;
      }
    }

    // Normalize deity weights to 0–100
    const maxDeity = Math.max(...Object.values(myDeityWeights), 1);
    for (const k in myDeityWeights) myDeityWeights[k] = (myDeityWeights[k] / maxDeity) * 100;

    // ── 6. COLLABORATIVE SCORE — find similar users ──────────
    // Users who visited same temples as current user
    const similarUserEmails = new Set();
    for (const a of allActivity) {
      const tName = (a.templeName || '').trim().toLowerCase();
      if (myTempleNames.has(tName) && a.userEmail && a.userEmail !== userEmail) {
        similarUserEmails.add(a.userEmail);
      }
    }

    // What did similar users visit?
    const collaborativeMap = {};
    for (const a of allActivity) {
      if (!similarUserEmails.has(a.userEmail)) continue;
      const key = (a.templeName || '').trim().toLowerCase();
      if (!key) continue;
      collaborativeMap[key] = (collaborativeMap[key] || 0) + recencyWeight(a.createdAt);
    }

    // Normalize collaborative to 0–100
    const maxCollab = Math.max(...Object.values(collaborativeMap), 1);
    for (const k in collaborativeMap) collaborativeMap[k] = (collaborativeMap[k] / maxCollab) * 100;

    // ── 7. COMPUTE FINAL SCORE for each temple ────────────────
    const scored = allTemples.map(temple => {
      const key    = (temple.name || '').trim().toLowerCase();
      const cat    = deityCategory(temple.deity || '');

      // Weights: popularity 40%, content 35%, collaborative 25%
      const popScore    = popularityMap[key]    || 0;
      const contentScore = myDeityWeights[cat]  || 0;
      const collabScore  = collaborativeMap[key] || 0;

      // Penalize temples user already visited a lot
      const visitCount = myActivity.filter(a =>
        (a.templeName || '').trim().toLowerCase() === key).length;
      const noveltyPenalty = Math.min(visitCount * 10, 40);

      const finalScore = hasHistory
        ? popScore * 0.40 + contentScore * 0.35 + collabScore * 0.25 - noveltyPenalty
        : popScore; // if no history, just use popularity

      return { ...temple, _score: finalScore, _visitCount: visitCount };
    });

    // Sort by score descending
    scored.sort((a, b) => b._score - a._score);

    // ── 8. SPLIT into "For You" vs "Popular" ─────────────────
    // "For You" = temples matching user's deity preference (but not over-visited)
    // "Popular"  = top by pure popularity

    let forYou  = [];
    let popular = [];

    if (hasHistory) {
      // For You: content + collab score high, not over-visited
      forYou = scored
        .filter(t => {
          const cat = deityCategory(t.deity || '');
          return (myDeityWeights[cat] || 0) > 20 && t._visitCount < 3;
        })
        .slice(0, 4);

      // Popular: top overall, exclude "For You" temples
      const forYouNames = new Set(forYou.map(t => t.name));
      popular = scored
        .filter(t => !forYouNames.has(t.name))
        .slice(0, 6);
    } else {
      // No history — show all as popular
      popular = scored.slice(0, 8);
    }

    // Clean up internal scoring fields before sending
    const cleanTemple = t => {
      const { _score, _visitCount, __v, ...rest } = t;
      return rest;
    };

    console.log(`🧠 ML Recommendations for ${userEmail}: forYou=${forYou.length} popular=${popular.length} similarUsers=${similarUserEmails.size}`);

    return res.json({
      success:   true,
      type:      hasHistory ? 'personalized' : 'popular',
      typeLabel: hasHistory ? 'Based on your temple activity' : 'Popular temples',
      forYou:    forYou.map(cleanTemple),
      popular:   popular.map(cleanTemple),
      temples:   [...forYou, ...popular].map(cleanTemple), // combined for backward compat
      count:     forYou.length + popular.length,
      algorithm: {
        hasHistory,
        myTempleCount:    myTempleNames.size,
        similarUserCount: similarUserEmails.size,
        topDeity:         Object.entries(myDeityWeights).sort((a,b) => b[1]-a[1])[0]?.[0] || 'none',
      },
    });

  } catch (err) {
    console.error('[ML Route] Error:', err.message);
    return res.status(500).json({
      success: false,
      message: 'Recommendation engine error',
      error:   err.message,
    });
  }
});

module.exports = router;