const express = require('express');
const router  = express.Router();
const Prayer  = require('../models/Prayer');

// ─── HARDCODED SEED PRAYERS (always shown, merged with DB) ───────────────────
const SEED_PRAYERS = [
  {
    _id: 'seed_p1', title: 'Gayatri Mantra', category: 'Morning', language: 'Sanskrit',
    durationMinutes: 5, deity: 'Surya',
    lyrics: 'Om Bhur Bhuvaḥ Swaḥ\nTat-savitur Vareñyaṃ\nBhargo Devasya Dhīmahi\nDhiyo Yo Naḥ Prachodayāt',
    meaning: 'We meditate on the glory of the Creator who has created the Universe, who is worthy of worship, who is the embodiment of knowledge and light, who removes all sins and ignorance. May he enlighten our intellect.',
    audioUrl: '', imageUrl: '', isSeed: true,
  },
  {
    _id: 'seed_p2', title: 'Hanuman Chalisa', category: 'Morning', language: 'Hindi',
    durationMinutes: 15, deity: 'Hanuman',
    lyrics: 'Shri Guru Charan Saroj Raj\nNij Man Mukur Sudhar\nBarnau Raghuvar Bimal Jasu\nJo Dayaku Phal Char',
    meaning: 'Cleaning the mirror of my mind with the pollen dust of holy Guru\'s lotus feet, I narrate the pure glory of the best among Raghus (Shri Ram), which bestows the four fruits of life.',
    audioUrl: '', imageUrl: '', isSeed: true,
  },
  {
    _id: 'seed_p3', title: 'Om Namah Shivaya', category: 'Mantra', language: 'Sanskrit',
    durationMinutes: 3, deity: 'Shiva',
    lyrics: 'Om Namah Shivaya\nOm Namah Shivaya\nOm Namah Shivaya',
    meaning: 'I bow to Shiva. Shiva is the supreme reality, the inner Self. It is the name given to consciousness that dwells in all.',
    audioUrl: '', imageUrl: '', isSeed: true,
  },
  {
    _id: 'seed_p4', title: 'Venkatesa Suprabhatam', category: 'Morning', language: 'Sanskrit',
    durationMinutes: 10, deity: 'Lord Vishnu',
    lyrics: 'Kausalya Supraja Rama\nPurva Sandhya Pravartate\nUtthishtha Narasardula\nKartavyam Daivam Ahnikam',
    meaning: 'O Rama, beloved son of Kaushalya! The dawn is approaching. O Tiger among men! Arise and attend to your daily divine duties.',
    audioUrl: '', imageUrl: '', isSeed: true,
  },
  {
    _id: 'seed_p5', title: 'Evening Aarti', category: 'Evening', language: 'Hindi',
    durationMinutes: 8, deity: 'All Gods',
    lyrics: 'Om Jai Jagdish Hare\nSwami Jai Jagdish Hare\nBhakt Jano Ke Sankat\nDas Jano Ke Sankat\nKshan Mein Door Kare',
    meaning: 'Victory to the Lord of the Universe! O Lord, you remove the sufferings of your devotees and servants in an instant.',
    audioUrl: '', imageUrl: '', isSeed: true,
  },
  {
    _id: 'seed_p6', title: 'Maha Mrityunjaya Mantra', category: 'Mantra', language: 'Sanskrit',
    durationMinutes: 5, deity: 'Shiva',
    lyrics: 'Om Tryambakam Yajamahe\nSugandhim Pushti-Vardhanam\nUrvarukamiva Bandhanan\nMrityor Mukshiya Maamritat',
    meaning: 'We worship the three-eyed one (Lord Shiva) who is fragrant and who nourishes all beings. May he liberate us from death for the sake of immortality, just as the cucumber is severed from its vine.',
    audioUrl: '', imageUrl: '', isSeed: true,
  },
  {
    _id: 'seed_p7', title: 'Shree Suktam', category: 'Morning', language: 'Sanskrit',
    durationMinutes: 12, deity: 'Lakshmi',
    lyrics: 'Hiranya Varnaam Harinim\nSuvarna Rajata Srajam\nChandraam Hiranya Mayim\nLakshmim Jaatavedo Maavaha',
    meaning: 'O Agni, invoke for me the Goddess Lakshmi, who shines like gold, who is as radiant as the moon, and who bestows wealth and prosperity.',
    audioUrl: '', imageUrl: '', isSeed: true,
  },
  {
    _id: 'seed_p8', title: 'Vishnu Sahasranamam', category: 'Evening', language: 'Sanskrit',
    durationMinutes: 25, deity: 'Vishnu',
    lyrics: 'Vishvam Vishnur Vashatkaro\nBhuta Bhavya Bhavat Prabhuh\nBhutakrit Bhutabhrid Bhaavo\nBhutatma Bhutabhavanah',
    meaning: 'He who is the universe itself, the Lord of all that was, is, and will be. He who creates, sustains, and shelters all beings. He is the very soul of all existence.',
    audioUrl: '', imageUrl: '', isSeed: true,
  },
];

const formatPrayer = (p) => ({
  id:               p._id,
  title:            p.title            || '',
  category:         p.category         || 'General',
  language:         p.language         || 'Sanskrit',
  duration_minutes: p.durationMinutes  || p.duration_minutes || 5,
  deity:            p.deity            || '',
  lyrics:           p.lyrics           || '',
  meaning:          p.meaning          || '',
  audio_url:        p.audioUrl         || p.audio_url || '',
  image_url:        p.imageUrl         || p.image_url || '',
  isSeed:           p.isSeed           ?? false,
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/prayers  — returns SEED prayers + DB prayers merged
// ─────────────────────────────────────────────────────────────────────────────
router.get('/', async (req, res) => {
  try {
    const { category } = req.query;

    // Always start with seed prayers
    let seedFiltered = category
      ? SEED_PRAYERS.filter(p => p.category === category)
      : SEED_PRAYERS;

    // Also fetch DB prayers
    let dbFormatted = [];
    try {
      const query = category ? { category } : {};
      const dbPrayers = await Prayer.find(query).sort({ createdAt: -1 });
      dbFormatted = dbPrayers.map(formatPrayer);
    } catch (_) {
      // DB error — still return seed prayers
    }

    // Merge: DB prayers first (admin-added shown on top), then seed prayers
    const merged = [...dbFormatted, ...seedFiltered.map(formatPrayer)];

    res.status(200).json(merged);
  } catch (err) {
    console.error('❌ GET /prayers error:', err);
    // Return seed prayers even on total failure
    const { category } = req.query;
    const seed = category
      ? SEED_PRAYERS.filter(p => p.category === category)
      : SEED_PRAYERS;
    res.status(200).json(seed.map(formatPrayer));
  }
});

module.exports = router;