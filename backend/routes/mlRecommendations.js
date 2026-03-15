// backend/routes/mlRecommendations.js
// ══════════════════════════════════════════════════════════════════
// HYBRID ML RECOMMENDATION ENGINE
// Algorithm 1: Content-Based Filtering  (deity preference)
// Algorithm 2: Collaborative Filtering  (ALS-inspired user similarity)
// Final Score:  40% Collaborative + 35% Content + 25% Popularity
// ══════════════════════════════════════════════════════════════════

const express  = require('express');
const router   = express.Router();
const mongoose = require('mongoose');
const Temple   = require('../models/temple');
const Donation = require('../models/Donation');

function getModel(name) {
  return mongoose.models[name] || mongoose.model(name,
    new mongoose.Schema(
      { userEmail: String, templeName: String, totalAmount: Number },
      { strict: false, timestamps: true }
    )
  );
}
const DarshanBooking  = getModel('DarshanBooking');
const HomamBooking    = getModel('HomamBooking');
const MarriageBooking = getModel('MarriageBooking');

// ── Deity category ───────────────────────────────────────────────
function deityCategory(deity = '') {
  const d = deity.toLowerCase();
  if (d.includes('murugan') || d.includes('kartikeya') || d.includes('subramanya') || d.includes('senthil') || d.includes('dandayutha')) return 'murugan';
  if (d.includes('shiva')   || d.includes('siva')      || d.includes('nataraja')   || d.includes('lingam')  || d.includes('kailasa') || d.includes('ekambara') || d.includes('arunachala') || d.includes('brihadeeswara')) return 'shiva';
  if (d.includes('vishnu')  || d.includes('perumal')   || d.includes('ranganatha') || d.includes('varadaraja') || d.includes('parthasarathy') || d.includes('oppiliappan') || d.includes('sarangapani')) return 'vishnu';
  if (d.includes('devi')    || d.includes('amman')     || d.includes('durga')      || d.includes('lakshmi') || d.includes('meenakshi') || d.includes('kamakshi') || d.includes('mariamman') || d.includes('kanyakumari') || d.includes('kali')) return 'devi';
  if (d.includes('ganesh')  || d.includes('ganesha')   || d.includes('vinayaka')   || d.includes('pillayar') || d.includes('vinayagar')) return 'ganesh';
  return 'other';
}

// ── Recency weight — recent bookings count more ──────────────────
function recencyWeight(createdAt) {
  const days = (Date.now() - new Date(createdAt).getTime()) / (1000 * 60 * 60 * 24);
  return Math.exp(-days / 30); // exponential decay over 30 days
}

// ── Hardcoded temples ────────────────────────────────────────────
function getHardcodedTemples() {
  return [
    { name: 'Palani Murugan Temple',              location: 'Palani, Dindigul, Tamil Nadu',                 deity: 'Lord Murugan',              festivals: ['Thaipusam', 'Skanda Shashti'],           icon: '🛕' },
    { name: 'Thiruchendur Murugan Temple',         location: 'Thiruchendur, Thoothukudi, Tamil Nadu',        deity: 'Lord Murugan',              festivals: ['Skanda Shashti', 'Thaipusam'],           icon: '🛕' },
    { name: 'Swamimalai Murugan Temple',           location: 'Swamimalai, Kumbakonam, Tamil Nadu',           deity: 'Lord Murugan',              festivals: ['Skanda Shashti', 'Thaipusam'],           icon: '🛕' },
    { name: 'Tiruttani Murugan Temple',            location: 'Tiruttani, Ranipet, Tamil Nadu',               deity: 'Lord Murugan',              festivals: ['Skanda Shashti', 'Vaikasi Visakam'],    icon: '🛕' },
    { name: 'Pazhamudircholai Murugan Temple',     location: 'Alagar Kovil, Madurai, Tamil Nadu',            deity: 'Lord Murugan',              festivals: ['Vaikasi Visakam', 'Panguni Uthiram'],   icon: '🛕' },
    { name: 'Thiruparankundram Murugan Temple',    location: 'Thiruparankundram, Madurai, Tamil Nadu',       deity: 'Lord Murugan',              festivals: ['Skanda Shashti', 'Thaipusam'],           icon: '🛕' },
    { name: 'Nataraja Temple Chidambaram',         location: 'Chidambaram, Cuddalore, Tamil Nadu',           deity: 'Lord Nataraja (Shiva)',      festivals: ['Natyanjali', 'Maha Shivaratri'],         icon: '🛕' },
    { name: 'Ekambareswarar Temple',               location: 'Kanchipuram, Tamil Nadu',                      deity: 'Lord Shiva',                festivals: ['Maha Shivaratri'],                       icon: '🛕' },
    { name: 'Arunachaleswarar Temple',             location: 'Thiruvannamalai, Tamil Nadu',                  deity: 'Lord Shiva',                festivals: ['Karthigai Deepam', 'Maha Shivaratri'],  icon: '🛕' },
    { name: 'Jambukeswarar Temple',                location: 'Thiruvanaikaval, Tiruchirappalli, Tamil Nadu', deity: 'Lord Shiva',                festivals: ['Maha Shivaratri'],                       icon: '🛕' },
    { name: 'Brihadeeswarar Temple',               location: 'Thanjavur, Tamil Nadu',                        deity: 'Lord Shiva',                festivals: ['Maha Shivaratri', 'Karthigai Deepam'],  icon: '🛕' },
    { name: 'Ramanathaswamy Temple',               location: 'Rameswaram, Ramanathapuram, Tamil Nadu',       deity: 'Lord Shiva',                festivals: ['Maha Shivaratri', 'Brahmotsavam'],       icon: '🛕' },
    { name: 'Kapaleeshwarar Temple',               location: 'Mylapore, Chennai, Tamil Nadu',                deity: 'Lord Shiva',                festivals: ['Arubathimoovar Festival'],               icon: '🛕' },
    { name: 'Nellaiappar Temple',                  location: 'Tirunelveli, Tamil Nadu',                      deity: 'Lord Shiva',                festivals: ['Maha Shivaratri', 'Navarathri'],         icon: '🛕' },
    { name: 'Vaitheeswaran Koil',                  location: 'Vaitheeswaran Koil, Nagapattinam, Tamil Nadu', deity: 'Lord Shiva',                festivals: ['Maha Shivaratri', 'Skanda Shashti'],    icon: '🛕' },
    { name: 'Airavatheeswarar Temple',             location: 'Darasuram, Kumbakonam, Tamil Nadu',            deity: 'Lord Shiva',                festivals: ['Maha Shivaratri'],                       icon: '🛕' },
    { name: 'Gangaikonda Cholapuram Temple',       location: 'Gangaikonda Cholapuram, Ariyalur, Tamil Nadu', deity: 'Lord Shiva',                festivals: ['Maha Shivaratri'],                       icon: '🛕' },
    { name: 'Kumbeswarar Temple',                  location: 'Kumbakonam, Tamil Nadu',                       deity: 'Lord Shiva',                festivals: ['Maha Shivaratri', 'Mahamaham'],          icon: '🛕' },
    { name: 'Kanchi Kailasanathar Temple',         location: 'Kanchipuram, Tamil Nadu',                      deity: 'Lord Shiva',                festivals: ['Maha Shivaratri'],                       icon: '🛕' },
    { name: 'Thirunageswaram Rahu Temple',         location: 'Thirunageswaram, Kumbakonam, Tamil Nadu',      deity: 'Lord Shiva (Naganatha)',     festivals: ['Aadi Krithigai'],                        icon: '🛕' },
    { name: 'Kasi Viswanathar Temple Tenkasi',     location: 'Tenkasi, Tirunelveli, Tamil Nadu',             deity: 'Lord Shiva',                festivals: ['Maha Shivaratri'],                       icon: '🛕' },
    { name: 'Ranganathaswamy Temple Srirangam',    location: 'Srirangam, Tiruchirappalli, Tamil Nadu',       deity: 'Lord Vishnu (Ranganatha)',   festivals: ['Vaikunta Ekadasi', 'Brahmotsavam'],      icon: '🛕' },
    { name: 'Varadaraja Perumal Temple',           location: 'Kanchipuram, Tamil Nadu',                      deity: 'Lord Vishnu',               festivals: ['Brahmotsavam', 'Vaikunta Ekadasi'],      icon: '🛕' },
    { name: 'Parthasarathy Temple',                location: 'Triplicane, Chennai, Tamil Nadu',              deity: 'Lord Vishnu (Krishna)',      festivals: ['Krishna Jayanthi', 'Vaikunta Ekadasi'],  icon: '🛕' },
    { name: 'Oppiliappan Temple',                  location: 'Thirunageswaram, Kumbakonam, Tamil Nadu',      deity: 'Lord Vishnu',               festivals: ['Vaikunta Ekadasi'],                      icon: '🛕' },
    { name: 'Sarangapani Temple',                  location: 'Kumbakonam, Tamil Nadu',                       deity: 'Lord Vishnu',               festivals: ['Vaikunta Ekadasi', 'Brahmotsavam'],      icon: '🛕' },
    { name: 'Rajagopalaswamy Temple Mannargudi',   location: 'Mannargudi, Tiruvarur, Tamil Nadu',            deity: 'Lord Vishnu (Krishna)',      festivals: ['Brahmotsavam', 'Vaikunta Ekadasi'],      icon: '🛕' },
    { name: 'Meenakshi Amman Temple',              location: 'Madurai, Tamil Nadu',                          deity: 'Goddess Meenakshi (Devi)',   festivals: ['Meenakshi Thirukalyanam', 'Navarathri'], icon: '🛕' },
    { name: 'Kamakshi Amman Temple',               location: 'Kanchipuram, Tamil Nadu',                      deity: 'Goddess Kamakshi (Devi)',    festivals: ['Navarathri', 'Panguni Uthiram'],         icon: '🛕' },
    { name: 'Mariamman Temple Samayapuram',        location: 'Samayapuram, Tiruchirappalli, Tamil Nadu',     deity: 'Goddess Mariamman (Devi)',   festivals: ['Panguni Uthiram', 'Navarathri'],         icon: '🛕' },
    { name: 'Kanyakumari Bhagavathy Amman Temple', location: 'Kanyakumari, Tamil Nadu',                      deity: 'Goddess Kanyakumari (Devi)', festivals: ['Navarathri', 'Vaikasi Visakam'],         icon: '🛕' },
    { name: 'Ashtalakshmi Temple',                 location: 'Besant Nagar, Chennai, Tamil Nadu',            deity: 'Goddess Lakshmi (Devi)',     festivals: ['Navarathri', 'Varalakshmi Vratam'],      icon: '🛕' },
    { name: 'Uchipillaiyar Temple Rock Fort',      location: 'Tiruchirappalli, Tamil Nadu',                  deity: 'Lord Ganesha',              festivals: ['Ganesh Chaturthi'],                      icon: '🛕' },
    { name: 'Karpaga Vinayagar Temple',            location: 'Pillayarpatti, Sivaganga, Tamil Nadu',         deity: 'Lord Ganesha',              festivals: ['Ganesh Chaturthi'],                      icon: '🛕' },
    { name: 'Shore Temple Mahabalipuram',          location: 'Mahabalipuram, Chengalpattu, Tamil Nadu',      deity: 'Lord Shiva',                festivals: ['Maha Shivaratri', 'Dance Festival'],     icon: '🛕' },
    { name: 'Suchindram Thanumalayan Temple',      location: 'Suchindram, Kanyakumari, Tamil Nadu',          deity: 'Lord Shiva Vishnu Brahma',  festivals: ['Maha Shivaratri', 'Vaikunta Ekadasi'],   icon: '🛕' },
  ];
}

// ════════════════════════════════════════════════════════════════
// ALS-INSPIRED COLLABORATIVE FILTERING
// Pure JS implementation — no Python needed
//
// Real ALS decomposes a User×Item matrix into two lower-rank
// matrices U and V using alternating least squares.
// Here we simulate the same effect:
//   - Build a User×Temple visit matrix from all bookings
//   - Find users similar to the current user (cosine similarity)
//   - Score temples by how much similar users visited them
//   - Weight by recency
// ════════════════════════════════════════════════════════════════
function computeCollaborativeScores(userEmail, allActivity, allTemples) {
  const emailLower = userEmail.toLowerCase();

  // Build user → temple visit map (with recency weights)
  // userVisitMap[email][templeName] = total recency-weighted visits
  const userVisitMap = {};
  for (const a of allActivity) {
    const email  = (a.userEmail || a.donorEmail || '').toLowerCase().trim();
    const temple = (a.templeName || '').toLowerCase().trim();
    if (!email || !temple) continue;
    if (!userVisitMap[email]) userVisitMap[email] = {};
    userVisitMap[email][temple] = (userVisitMap[email][temple] || 0) + recencyWeight(a.createdAt);
  }

  const currentUserVec = userVisitMap[emailLower] || {};
  const myTemples      = Object.keys(currentUserVec);

  if (myTemples.length === 0) return {}; // no history

  // ── Cosine Similarity ─────────────────────────────────────────
  // sim(A, B) = (A·B) / (|A| × |B|)
  // Find users who share at least one temple with current user
  const similarityMap = {};
  for (const [otherEmail, otherVec] of Object.entries(userVisitMap)) {
    if (otherEmail === emailLower) continue;

    // Dot product
    let dot = 0, magA = 0, magB = 0;
    const allKeys = new Set([...Object.keys(currentUserVec), ...Object.keys(otherVec)]);
    for (const key of allKeys) {
      const a = currentUserVec[key] || 0;
      const b = otherVec[key]       || 0;
      dot  += a * b;
      magA += a * a;
      magB += b * b;
    }
    const sim = (magA > 0 && magB > 0) ? dot / (Math.sqrt(magA) * Math.sqrt(magB)) : 0;
    if (sim > 0) similarityMap[otherEmail] = sim;
  }

  // ── ALS-inspired temple scoring ───────────────────────────────
  // Score(temple) = Σ similarity(otherUser) × visits(otherUser, temple)
  // This is equivalent to the predicted rating in ALS matrix factorization
  const templeScores = {};
  for (const [otherEmail, sim] of Object.entries(similarityMap)) {
    const otherVec = userVisitMap[otherEmail];
    for (const [temple, visits] of Object.entries(otherVec)) {
      templeScores[temple] = (templeScores[temple] || 0) + sim * visits;
    }
  }

  // Normalize to 0-100
  const maxScore = Math.max(...Object.values(templeScores), 1);
  for (const k in templeScores) templeScores[k] = (templeScores[k] / maxScore) * 100;

  return templeScores;
}

// GET /api/ml-recommendations/:userEmail
router.get('/:userEmail', async (req, res) => {
  try {
    const { userEmail } = req.params;
    const emailLower    = userEmail.toLowerCase();

    // ── 1. Build temple list (DB + hardcoded) ─────────────────
    const dbTemples   = await Temple.find({}).lean();
    const dbFormatted = dbTemples.map(t => ({
      name: t.name || 'Temple', location: t.location || '',
      deity: t.deity || '', festivals: t.festivals || [], icon: t.icon || '🛕',
    }));
    const allRaw = [...dbFormatted, ...getHardcodedTemples()];
    const seen   = new Set();
    const allTemples = allRaw.filter(t => {
      const key = (t.name || '').toLowerCase().trim();
      if (seen.has(key)) return false;
      seen.add(key);
      return true;
    });

    // ── 2. Fetch ALL users' activity for collaborative ─────────
    const [allDarshans, allHomams, allMarriages, allDonations] = await Promise.all([
      DarshanBooking.find({}).lean(),
      HomamBooking.find({}).lean(),
      MarriageBooking.find({}).lean(),
      Donation.find({}).lean(),
    ]);
    const allNormDonations = allDonations.map(d => ({ ...d, userEmail: d.donorEmail }));
    const allActivity      = [...allDarshans, ...allHomams, ...allMarriages, ...allNormDonations];

    // ── 3. Fetch CURRENT user's activity ──────────────────────
    const myActivity = allActivity.filter(a =>
      (a.userEmail || '').toLowerCase() === emailLower
    );
    const hasHistory = myActivity.length > 0;

    // ── 4. CONTENT-BASED: deity preference score ──────────────
    const deityCount = {};
    for (const a of myActivity) {
      const tName  = (a.templeName || '').toLowerCase().trim();
      const found  = allTemples.find(t => (t.name || '').toLowerCase().trim() === tName);
      const cat    = deityCategory(found?.deity || tName);
      const weight = recencyWeight(a.createdAt);
      deityCount[cat] = (deityCount[cat] || 0) + weight;
    }
    const maxDeity = Math.max(...Object.values(deityCount), 1);
    for (const k in deityCount) deityCount[k] = (deityCount[k] / maxDeity) * 100;

    // ── 5. COLLABORATIVE ALS: similar user scores ─────────────
    const collabScores = computeCollaborativeScores(userEmail, allActivity, allTemples);

    // ── 6. POPULARITY: how many total visits per temple ────────
    const popularityMap = {};
    for (const a of allActivity) {
      const key = (a.templeName || '').toLowerCase().trim();
      if (!key) continue;
      popularityMap[key] = (popularityMap[key] || 0) + 1;
    }
    const maxPop = Math.max(...Object.values(popularityMap), 1);
    for (const k in popularityMap) popularityMap[k] = (popularityMap[k] / maxPop) * 100;

    // ── 7. HYBRID SCORE: weighted combination ─────────────────
    // Weight: 40% Collaborative + 35% Content-Based + 25% Popularity
    const visitedNames = new Set(myActivity.map(a => (a.templeName || '').toLowerCase().trim()));

    const scored = allTemples.map(temple => {
      const key         = (temple.name || '').toLowerCase().trim();
      const cat         = deityCategory(temple.deity || '');
      const contentScore = deityCount[cat]     || 0;  // 35%
      const collabScore  = collabScores[key]   || 0;  // 40%
      const popScore     = popularityMap[key]  || 0;  // 25%
      const alreadyVisited = visitedNames.has(key);

      // Novelty penalty — temples visited many times score lower
      const visitCount   = myActivity.filter(a => (a.templeName || '').toLowerCase().trim() === key).length;
      const noveltyBonus = alreadyVisited ? Math.max(0, 20 - visitCount * 10) : 20;

      const finalScore = hasHistory
        ? collabScore * 0.40 + contentScore * 0.35 + popScore * 0.25 + noveltyBonus
        : popScore;

      return { ...temple, _score: finalScore, _visited: alreadyVisited, _cat: cat };
    });

    scored.sort((a, b) => b._score - a._score);

    // ── 8. Split into forYou and popular ──────────────────────
    let forYou  = [];
    let popular = [];

    if (hasHistory) {
      // forYou = top scored unvisited temples
      forYou = scored.filter(t => !t._visited).slice(0, 4);
      // If not enough unvisited, fill from all
      if (forYou.length < 2) forYou = scored.slice(0, 4);

      const forYouNames = new Set(forYou.map(t => (t.name || '').toLowerCase()));
      popular = scored.filter(t => !forYouNames.has((t.name || '').toLowerCase())).slice(0, 6);
    } else {
      // Cold start — no history, show all as popular
      popular = scored.slice(0, 8);
    }

    // Clean internal fields
    const clean = t => {
      const c = { ...t };
      delete c._score; delete c._visited; delete c._cat;
      return c;
    };

    // Top deity for label
    const topDeity = Object.entries(deityCount).sort((a, b) => b[1] - a[1])[0]?.[0];
    const similarUserCount = Object.keys(
      allActivity.reduce((acc, a) => {
        const e = (a.userEmail || '').toLowerCase();
        if (e && e !== emailLower) acc[e] = true;
        return acc;
      }, {})
    ).length;

    console.log(`🧠 Hybrid ML for ${userEmail}: hasHistory=${hasHistory} topDeity=${topDeity} collab_users=${similarUserCount} forYou=${forYou.length} popular=${popular.length}`);

    return res.json({
      success:   true,
      type:      hasHistory ? 'personalized' : 'popular',
      typeLabel: hasHistory && topDeity
        ? `Based on your ${topDeity} temple visits`
        : 'Popular Temples',
      forYou:    forYou.map(clean),
      popular:   popular.map(clean),
      temples:   [...forYou, ...popular].map(clean),
      count:     forYou.length + popular.length,
      algorithm: {
        type:              'Hybrid (Content-Based + Collaborative ALS)',
        hasHistory,
        topDeity:          topDeity || 'none',
        similarUserCount,
        weights:           { collaborative: '40%', contentBased: '35%', popularity: '25%' },
      },
    });

  } catch (err) {
    console.error('[ML Route] Error:', err.message, err.stack);
    return res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;