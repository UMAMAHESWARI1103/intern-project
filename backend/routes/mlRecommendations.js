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
// IMPORT EXISTING MODELS — avoids OverwriteModelError
// ─────────────────────────────────────────────────────────────────────────────
const Temple   = require('../models/temple');
const Donation = require('../models/Donation');

// DarshanBooking / HomamBooking / MarriageBooking are registered in booking.js
// getModel safely reuses already-compiled models
function getModel(name) {
  return mongoose.models[name] || mongoose.model(name,
    new mongoose.Schema({
      userId: mongoose.Schema.Types.ObjectId,
      userEmail: String, templeName: String, templeId: String,
      totalAmount: Number,
    }, { strict: false, timestamps: true })
  );
}
const DarshanBooking  = getModel('DarshanBooking');
const HomamBooking    = getModel('HomamBooking');
const MarriageBooking = getModel('MarriageBooking');

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
// ALGORITHM HELPERS
// ─────────────────────────────────────────────────────────────────────────────

// Recency weight: recent activity scores higher (exponential decay over 30 days)
function recencyWeight(createdAt) {
  const days = (Date.now() - new Date(createdAt).getTime()) / (1000 * 60 * 60 * 24);
  return Math.exp(-days / 30);
}

// Map deity string to category
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

    // 1. Load all temples
    const allTemples = await Temple.find({}).lean();
    if (!allTemples.length) {
      return res.json({ success: true, type: 'popular', forYou: [], popular: [], temples: [] });
    }

    // 2. Load user's own activity
    const userQuery = { $or: [{ userEmail }, { userEmail: userEmail.toLowerCase() }] };
    const [myDarshans, myHomams, myMarriages, myDonations] = await Promise.all([
      DarshanBooking.find(userQuery).lean(),
      HomamBooking.find(userQuery).lean(),
      MarriageBooking.find(userQuery).lean(),
      Donation.find(userQuery).lean(),
    ]);

    const myActivity = [...myDarshans, ...myHomams, ...myMarriages, ...myDonations];
    const hasHistory = myActivity.length > 0;

    // 3. Load ALL bookings for collaborative + popularity
    const [allDarshans, allHomams, allMarriages, allDonations] = await Promise.all([
      DarshanBooking.find({}).lean(),
      HomamBooking.find({}).lean(),
      MarriageBooking.find({}).lean(),
      Donation.find({}).lean(),
    ]);
    const allActivity = [...allDarshans, ...allHomams, ...allMarriages, ...allDonations];

    // 4. POPULARITY SCORE — count bookings per temple
    const popularityMap = {};
    for (const a of allActivity) {
      const key = (a.templeName || '').trim().toLowerCase();
      if (!key) continue;
      popularityMap[key] = (popularityMap[key] || 0) + 1
        + (a.totalAmount || a.amount || 0) * 0.001;
    }
    const maxPop = Math.max(...Object.values(popularityMap), 1);
    for (const k in popularityMap) popularityMap[k] = (popularityMap[k] / maxPop) * 100;

    // 5. CONTENT-BASED SCORE — user's preferred deity
    const myTempleNames  = new Set();
    const myDeityWeights = {};

    for (const a of myActivity) {
      const tName = (a.templeName || '').trim().toLowerCase();
      if (tName) myTempleNames.add(tName);
      const temple = allTemples.find(t => (t.name || '').trim().toLowerCase() === tName);
      if (temple) {
        const cat = deityCategory(temple.deity || '');
        const w   = recencyWeight(a.createdAt) * (1 + (a.totalAmount || a.amount || 0) * 0.001);
        myDeityWeights[cat] = (myDeityWeights[cat] || 0) + w;
      }
    }
    const maxDeity = Math.max(...Object.values(myDeityWeights), 1);
    for (const k in myDeityWeights) myDeityWeights[k] = (myDeityWeights[k] / maxDeity) * 100;

    // 6. COLLABORATIVE SCORE — similar users
    const similarUserEmails = new Set();
    for (const a of allActivity) {
      const tName = (a.templeName || '').trim().toLowerCase();
      if (myTempleNames.has(tName) && a.userEmail && a.userEmail !== userEmail) {
        similarUserEmails.add(a.userEmail);
      }
    }
    const collaborativeMap = {};
    for (const a of allActivity) {
      if (!similarUserEmails.has(a.userEmail)) continue;
      const key = (a.templeName || '').trim().toLowerCase();
      if (!key) continue;
      collaborativeMap[key] = (collaborativeMap[key] || 0) + recencyWeight(a.createdAt);
    }
    const maxCollab = Math.max(...Object.values(collaborativeMap), 1);
    for (const k in collaborativeMap) collaborativeMap[k] = (collaborativeMap[k] / maxCollab) * 100;

    // 7. FINAL WEIGHTED SCORE
    const scored = allTemples.map(temple => {
      const key  = (temple.name || '').trim().toLowerCase();
      const cat  = deityCategory(temple.deity || '');

      const popScore     = popularityMap[key]   || 0;
      const contentScore = myDeityWeights[cat]  || 0;
      const collabScore  = collaborativeMap[key] || 0;

      const visitCount     = myActivity.filter(a =>
        (a.templeName || '').trim().toLowerCase() === key).length;
      const noveltyPenalty = Math.min(visitCount * 10, 40);

      // Weights: popularity 40%, content-based 35%, collaborative 25%
      const finalScore = hasHistory
        ? popScore * 0.40 + contentScore * 0.35 + collabScore * 0.25 - noveltyPenalty
        : popScore;

      return { ...temple, _score: finalScore, _visitCount: visitCount };
    });

    scored.sort((a, b) => b._score - a._score);

    // 8. SPLIT into forYou vs popular
    let forYou  = [];
    let popular = [];

    if (hasHistory) {
      forYou = scored
        .filter(t => {
          const cat = deityCategory(t.deity || '');
          return (myDeityWeights[cat] || 0) > 20 && t._visitCount < 3;
        })
        .slice(0, 4);

      const forYouNames = new Set(forYou.map(t => t.name));
      popular = scored.filter(t => !forYouNames.has(t.name)).slice(0, 6);
    } else {
      popular = scored.slice(0, 8);
    }

    const cleanTemple = (t) => {
      const cleaned = { ...t };
      delete cleaned._score;
      delete cleaned._visitCount;
      delete cleaned.__v;
      return cleaned;
    };

    console.log(`🧠 ML for ${userEmail}: forYou=${forYou.length} popular=${popular.length} similarUsers=${similarUserEmails.size} hasHistory=${hasHistory}`);

    return res.json({
      success:   true,
      type:      hasHistory ? 'personalized' : 'popular',
      typeLabel: hasHistory ? 'Based on your temple activity' : 'Popular temples',
      forYou:    forYou.map(cleanTemple),
      popular:   popular.map(cleanTemple),
      temples:   [...forYou, ...popular].map(cleanTemple),
      count:     forYou.length + popular.length,
      algorithm: {
        hasHistory,
        myTempleCount:    myTempleNames.size,
        similarUserCount: similarUserEmails.size,
        topDeity: Object.entries(myDeityWeights).sort((a, b) => b[1] - a[1])[0]?.[0] || 'none',
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