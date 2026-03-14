// backend/routes/mlRecommendations.js
// ✅ ML Algorithm:
// 1. Load user's booking history (darshan, homam, marriage, donations)
// 2. Find which deity they visit most (Murugan / Shiva / Vishnu / Devi / Ganesha)
// 3. Recommend temples matching their top deity → "For You"
// 4. Show remaining popular temples → "Popular Today"
// 5. If no history → show all as popular

const express  = require('express');
const router   = express.Router();
const mongoose = require('mongoose');
const Temple   = require('../models/temple');
const Donation = require('../models/Donation');

function getModel(name) {
  return mongoose.models[name] || mongoose.model(name,
    new mongoose.Schema({ userEmail: String, templeName: String, totalAmount: Number }, { strict: false, timestamps: true })
  );
}
const DarshanBooking  = getModel('DarshanBooking');
const HomamBooking    = getModel('HomamBooking');
const MarriageBooking = getModel('MarriageBooking');

// ── Deity category detector ──────────────────────────────────────
function deityCategory(deity = '') {
  const d = deity.toLowerCase();
  if (d.includes('murugan') || d.includes('kartikeya') || d.includes('subramanya') || d.includes('senthil') || d.includes('dandayutha')) return 'murugan';
  if (d.includes('shiva') || d.includes('siva') || d.includes('nataraja') || d.includes('lingam') || d.includes('kailasa') || d.includes('ekambara') || d.includes('arunachala') || d.includes('ramanathaswamy') || d.includes('brihadeeswara')) return 'shiva';
  if (d.includes('vishnu') || d.includes('perumal') || d.includes('venkatesh') || d.includes('ranganatha') || d.includes('varadaraja') || d.includes('parthasarathy') || d.includes('oppiliappan') || d.includes('sarangapani')) return 'vishnu';
  if (d.includes('devi') || d.includes('amman') || d.includes('durga') || d.includes('lakshmi') || d.includes('meenakshi') || d.includes('kamakshi') || d.includes('mariamman') || d.includes('kanyakumari') || d.includes('kali')) return 'devi';
  if (d.includes('ganesh') || d.includes('ganesha') || d.includes('vinayaka') || d.includes('pillayar') || d.includes('vinayagar')) return 'ganesh';
  return 'other';
}

// ── All hardcoded temples ────────────────────────────────────────
function getHardcodedTemples() {
  return [
    { name: 'Palani Murugan Temple',              location: 'Palani, Dindigul, Tamil Nadu',              deity: 'Lord Murugan',              festivals: ['Thaipusam', 'Skanda Shashti'],          icon: '🛕' },
    { name: 'Thiruchendur Murugan Temple',         location: 'Thiruchendur, Thoothukudi, Tamil Nadu',     deity: 'Lord Murugan',              festivals: ['Skanda Shashti', 'Thaipusam'],          icon: '🛕' },
    { name: 'Swamimalai Murugan Temple',           location: 'Swamimalai, Kumbakonam, Tamil Nadu',        deity: 'Lord Murugan',              festivals: ['Skanda Shashti', 'Thaipusam'],          icon: '🛕' },
    { name: 'Tiruttani Murugan Temple',            location: 'Tiruttani, Ranipet, Tamil Nadu',            deity: 'Lord Murugan',              festivals: ['Skanda Shashti', 'Vaikasi Visakam'],   icon: '🛕' },
    { name: 'Pazhamudircholai Murugan Temple',     location: 'Alagar Kovil, Madurai, Tamil Nadu',         deity: 'Lord Murugan',              festivals: ['Vaikasi Visakam', 'Panguni Uthiram'],  icon: '🛕' },
    { name: 'Thiruparankundram Murugan Temple',    location: 'Thiruparankundram, Madurai, Tamil Nadu',    deity: 'Lord Murugan',              festivals: ['Skanda Shashti', 'Thaipusam'],          icon: '🛕' },
    { name: 'Nataraja Temple Chidambaram',         location: 'Chidambaram, Cuddalore, Tamil Nadu',        deity: 'Lord Nataraja (Shiva)',      festivals: ['Natyanjali', 'Maha Shivaratri'],        icon: '🛕' },
    { name: 'Ekambareswarar Temple',               location: 'Kanchipuram, Tamil Nadu',                   deity: 'Lord Shiva',                festivals: ['Maha Shivaratri'],                      icon: '🛕' },
    { name: 'Arunachaleswarar Temple',             location: 'Thiruvannamalai, Tamil Nadu',               deity: 'Lord Shiva',                festivals: ['Karthigai Deepam', 'Maha Shivaratri'], icon: '🛕' },
    { name: 'Jambukeswarar Temple',                location: 'Thiruvanaikaval, Tiruchirappalli, Tamil Nadu', deity: 'Lord Shiva',             festivals: ['Maha Shivaratri'],                      icon: '🛕' },
    { name: 'Brihadeeswarar Temple',               location: 'Thanjavur, Tamil Nadu',                     deity: 'Lord Shiva',                festivals: ['Maha Shivaratri', 'Karthigai Deepam'], icon: '🛕' },
    { name: 'Ramanathaswamy Temple',               location: 'Rameswaram, Ramanathapuram, Tamil Nadu',    deity: 'Lord Shiva',                festivals: ['Maha Shivaratri', 'Brahmotsavam'],      icon: '🛕' },
    { name: 'Kapaleeshwarar Temple',               location: 'Mylapore, Chennai, Tamil Nadu',             deity: 'Lord Shiva',                festivals: ['Arubathimoovar Festival'],              icon: '🛕' },
    { name: 'Nellaiappar Temple',                  location: 'Tirunelveli, Tamil Nadu',                   deity: 'Lord Shiva',                festivals: ['Maha Shivaratri', 'Navarathri'],        icon: '🛕' },
    { name: 'Vaitheeswaran Koil',                  location: 'Vaitheeswaran Koil, Nagapattinam, Tamil Nadu', deity: 'Lord Shiva',             festivals: ['Maha Shivaratri', 'Skanda Shashti'],   icon: '🛕' },
    { name: 'Airavatheeswarar Temple',             location: 'Darasuram, Kumbakonam, Tamil Nadu',         deity: 'Lord Shiva',                festivals: ['Maha Shivaratri'],                      icon: '🛕' },
    { name: 'Gangaikonda Cholapuram Temple',       location: 'Gangaikonda Cholapuram, Ariyalur, Tamil Nadu', deity: 'Lord Shiva',             festivals: ['Maha Shivaratri'],                      icon: '🛕' },
    { name: 'Kumbeswarar Temple',                  location: 'Kumbakonam, Tamil Nadu',                    deity: 'Lord Shiva',                festivals: ['Maha Shivaratri', 'Mahamaham'],         icon: '🛕' },
    { name: 'Kanchi Kailasanathar Temple',         location: 'Kanchipuram, Tamil Nadu',                   deity: 'Lord Shiva',                festivals: ['Maha Shivaratri'],                      icon: '🛕' },
    { name: 'Ranganathaswamy Temple Srirangam',    location: 'Srirangam, Tiruchirappalli, Tamil Nadu',    deity: 'Lord Vishnu (Ranganatha)',   festivals: ['Vaikunta Ekadasi', 'Brahmotsavam'],     icon: '🛕' },
    { name: 'Varadaraja Perumal Temple',           location: 'Kanchipuram, Tamil Nadu',                   deity: 'Lord Vishnu',               festivals: ['Brahmotsavam', 'Vaikunta Ekadasi'],     icon: '🛕' },
    { name: 'Parthasarathy Temple',                location: 'Triplicane, Chennai, Tamil Nadu',           deity: 'Lord Vishnu (Krishna)',      festivals: ['Krishna Jayanthi', 'Vaikunta Ekadasi'], icon: '🛕' },
    { name: 'Oppiliappan Temple',                  location: 'Thirunageswaram, Kumbakonam, Tamil Nadu',   deity: 'Lord Vishnu',               festivals: ['Vaikunta Ekadasi'],                     icon: '🛕' },
    { name: 'Sarangapani Temple',                  location: 'Kumbakonam, Tamil Nadu',                    deity: 'Lord Vishnu',               festivals: ['Vaikunta Ekadasi', 'Brahmotsavam'],     icon: '🛕' },
    { name: 'Rajagopalaswamy Temple Mannargudi',   location: 'Mannargudi, Tiruvarur, Tamil Nadu',         deity: 'Lord Vishnu (Krishna)',      festivals: ['Brahmotsavam', 'Vaikunta Ekadasi'],     icon: '🛕' },
    { name: 'Meenakshi Amman Temple',              location: 'Madurai, Tamil Nadu',                       deity: 'Goddess Meenakshi (Devi)',   festivals: ['Meenakshi Thirukalyanam', 'Navarathri'],icon: '🛕' },
    { name: 'Kamakshi Amman Temple',               location: 'Kanchipuram, Tamil Nadu',                   deity: 'Goddess Kamakshi (Devi)',    festivals: ['Navarathri', 'Panguni Uthiram'],        icon: '🛕' },
    { name: 'Mariamman Temple Samayapuram',        location: 'Samayapuram, Tiruchirappalli, Tamil Nadu',  deity: 'Goddess Mariamman (Devi)',   festivals: ['Panguni Uthiram', 'Navarathri'],        icon: '🛕' },
    { name: 'Kanyakumari Bhagavathy Amman Temple', location: 'Kanyakumari, Tamil Nadu',                   deity: 'Goddess Kanyakumari (Devi)', festivals: ['Navarathri', 'Vaikasi Visakam'],        icon: '🛕' },
    { name: 'Ashtalakshmi Temple',                 location: 'Besant Nagar, Chennai, Tamil Nadu',         deity: 'Goddess Lakshmi (Devi)',     festivals: ['Navarathri', 'Varalakshmi Vratam'],     icon: '🛕' },
    { name: 'Uchipillaiyar Temple Rock Fort',      location: 'Tiruchirappalli, Tamil Nadu',               deity: 'Lord Ganesha',              festivals: ['Ganesh Chaturthi'],                     icon: '🛕' },
    { name: 'Karpaga Vinayagar Temple',            location: 'Pillayarpatti, Sivaganga, Tamil Nadu',      deity: 'Lord Ganesha',              festivals: ['Ganesh Chaturthi'],                     icon: '🛕' },
    { name: 'Shore Temple Mahabalipuram',          location: 'Mahabalipuram, Chengalpattu, Tamil Nadu',   deity: 'Lord Shiva',                festivals: ['Maha Shivaratri', 'Dance Festival'],    icon: '🛕' },
    { name: 'Suchindram Thanumalayan Temple',      location: 'Suchindram, Kanyakumari, Tamil Nadu',       deity: 'Lord Shiva Vishnu Brahma',  festivals: ['Maha Shivaratri', 'Vaikunta Ekadasi'],  icon: '🛕' },
    { name: 'Thirunageswaram Rahu Temple',         location: 'Thirunageswaram, Kumbakonam, Tamil Nadu',   deity: 'Lord Shiva (Naganatha)',     festivals: ['Aadi Krithigai'],                       icon: '🛕' },
    { name: 'Kasi Viswanathar Temple Tenkasi',     location: 'Tenkasi, Tirunelveli, Tamil Nadu',          deity: 'Lord Shiva',                festivals: ['Maha Shivaratri'],                      icon: '🛕' },
  ];
}

// GET /api/ml-recommendations/:userEmail
router.get('/:userEmail', async (req, res) => {
  try {
    const { userEmail } = req.params;
    const emailLower    = userEmail.toLowerCase();

    // ── 1. Load all temples (DB + hardcoded) ──────────────────
    const dbTemples = await Temple.find({}).lean();
    const dbFormatted = dbTemples.map(t => ({
      name: t.name || 'Temple', location: t.location || '',
      deity: t.deity || '', festivals: t.festivals || [], icon: t.icon || '🛕',
    }));
    const allRaw = [...dbFormatted, ...getHardcodedTemples()];

    // Remove duplicates by name
    const seen   = new Set();
    const allTemples = allRaw.filter(t => {
      const key = (t.name || '').toLowerCase().trim();
      if (seen.has(key)) return false;
      seen.add(key);
      return true;
    });

    // ── 2. Load user's booking history ────────────────────────
    const q = { $or: [{ userEmail }, { userEmail: emailLower }] };
    const [darshans, homams, marriages, donations] = await Promise.all([
      DarshanBooking.find(q).lean(),
      HomamBooking.find(q).lean(),
      MarriageBooking.find(q).lean(),
      Donation.find({ $or: [{ donorEmail: userEmail }, { donorEmail: emailLower }] }).lean(),
    ]);

    const allActivity = [
      ...darshans,
      ...homams,
      ...marriages,
      ...donations.map(d => ({ ...d, templeName: d.templeName })),
    ];

    const hasHistory = allActivity.length > 0;

    // ── 3. Find user's top deity from booking history ─────────
    const deityCount = {};
    for (const a of allActivity) {
      const tName = (a.templeName || '').toLowerCase().trim();
      // Find this temple in allTemples to get deity
      const found = allTemples.find(t => (t.name || '').toLowerCase().trim() === tName);
      const cat   = deityCategory(found?.deity || tName);
      deityCount[cat] = (deityCount[cat] || 0) + 1;
    }

    // Top deity
    const topDeity = Object.entries(deityCount)
      .sort((a, b) => b[1] - a[1])[0]?.[0] || null;

    // ── 4. Build forYou list (temples matching top deity) ─────
    let forYou  = [];
    let popular = [];

    if (hasHistory && topDeity && topDeity !== 'other') {
      // temples matching user's top deity that they haven't visited
      const visitedNames = new Set(allActivity.map(a => (a.templeName || '').toLowerCase().trim()));

      forYou = allTemples
        .filter(t => {
          const cat = deityCategory(t.deity || '');
          return cat === topDeity && !visitedNames.has((t.name || '').toLowerCase().trim());
        })
        .slice(0, 4);

      // If forYou is empty (visited all matching temples), show matching ones anyway
      if (forYou.length === 0) {
        forYou = allTemples
          .filter(t => deityCategory(t.deity || '') === topDeity)
          .slice(0, 4);
      }

      // Popular = temples NOT in forYou
      const forYouNames = new Set(forYou.map(t => (t.name || '').toLowerCase()));
      popular = allTemples
        .filter(t => !forYouNames.has((t.name || '').toLowerCase()))
        .slice(0, 6);
    } else {
      // No history — show all as popular
      popular = allTemples.slice(0, 5);
    }

    console.log(`🧠 ML for ${userEmail}: hasHistory=${hasHistory} topDeity=${topDeity} forYou=${forYou.length} popular=${popular.length}`);

    return res.json({
      success:   true,
      type:      hasHistory ? 'personalized' : 'popular',
      typeLabel: hasHistory && topDeity ? `Based on your ${topDeity} temple visits` : 'Popular Temples',
      forYou,
      popular,
      temples:   [...forYou, ...popular],
      count:     forYou.length + popular.length,
    });

  } catch (err) {
    console.error('[ML Route] Error:', err.message, err.stack);
    return res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;