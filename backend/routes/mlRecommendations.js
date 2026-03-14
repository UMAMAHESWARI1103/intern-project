// backend/routes/mlRecommendations.js
const express = require('express');
const router  = express.Router();
const Temple  = require('../models/temple');

function getHardcodedTemples() {
  return [
    { name: 'Palani Murugan Temple', location: 'Palani, Dindigul, Tamil Nadu', deity: 'Lord Murugan', festivals: ['Thaipusam', 'Skanda Shashti'], icon: '🛕' },
    { name: 'Thiruchendur Murugan Temple', location: 'Thiruchendur, Thoothukudi, Tamil Nadu', deity: 'Lord Murugan', festivals: ['Skanda Shashti', 'Thaipusam'], icon: '🛕' },
    { name: 'Swamimalai Murugan Temple', location: 'Swamimalai, Kumbakonam, Tamil Nadu', deity: 'Lord Murugan', festivals: ['Skanda Shashti', 'Thaipusam'], icon: '🛕' },
    { name: 'Tiruttani Murugan Temple', location: 'Tiruttani, Ranipet, Tamil Nadu', deity: 'Lord Murugan', festivals: ['Skanda Shashti', 'Vaikasi Visakam'], icon: '🛕' },
    { name: 'Pazhamudircholai Murugan Temple', location: 'Alagar Kovil, Madurai, Tamil Nadu', deity: 'Lord Murugan', festivals: ['Vaikasi Visakam', 'Panguni Uthiram'], icon: '🛕' },
    { name: 'Thiruparankundram Murugan Temple', location: 'Thiruparankundram, Madurai, Tamil Nadu', deity: 'Lord Murugan', festivals: ['Skanda Shashti', 'Thaipusam'], icon: '🛕' },
    { name: 'Nataraja Temple Chidambaram', location: 'Chidambaram, Cuddalore, Tamil Nadu', deity: 'Lord Nataraja', festivals: ['Natyanjali Festival', 'Maha Shivaratri'], icon: '🛕' },
    { name: 'Ekambareswarar Temple', location: 'Kanchipuram, Tamil Nadu', deity: 'Lord Shiva', festivals: ['Maha Shivaratri', 'Panguni Uthiram'], icon: '🛕' },
    { name: 'Arunachaleswarar Temple', location: 'Thiruvannamalai, Tamil Nadu', deity: 'Lord Shiva', festivals: ['Karthigai Deepam', 'Maha Shivaratri'], icon: '🛕' },
    { name: 'Jambukeswarar Temple', location: 'Thiruvanaikaval, Tiruchirappalli, Tamil Nadu', deity: 'Lord Shiva', festivals: ['Maha Shivaratri', 'Panguni Uthiram'], icon: '🛕' },
    { name: 'Brihadeeswarar Temple', location: 'Thanjavur, Tamil Nadu', deity: 'Lord Shiva', festivals: ['Maha Shivaratri', 'Karthigai Deepam'], icon: '🛕' },
    { name: 'Ramanathaswamy Temple', location: 'Rameswaram, Ramanathapuram, Tamil Nadu', deity: 'Lord Shiva', festivals: ['Maha Shivaratri', 'Brahmotsavam'], icon: '🛕' },
    { name: 'Kapaleeshwarar Temple', location: 'Mylapore, Chennai, Tamil Nadu', deity: 'Lord Shiva', festivals: ['Arubathimoovar Festival', 'Navarathri'], icon: '🛕' },
    { name: 'Nellaiappar Temple', location: 'Tirunelveli, Tamil Nadu', deity: 'Lord Shiva', festivals: ['Maha Shivaratri', 'Navarathri'], icon: '🛕' },
    { name: 'Vaitheeswaran Koil', location: 'Vaitheeswaran Koil, Nagapattinam, Tamil Nadu', deity: 'Lord Shiva', festivals: ['Maha Shivaratri', 'Skanda Shashti'], icon: '🛕' },
    { name: 'Airavatheeswarar Temple', location: 'Darasuram, Kumbakonam, Tamil Nadu', deity: 'Lord Shiva', festivals: ['Maha Shivaratri', 'Karthigai Deepam'], icon: '🛕' },
    { name: 'Gangaikonda Cholapuram Temple', location: 'Gangaikonda Cholapuram, Ariyalur, Tamil Nadu', deity: 'Lord Shiva', festivals: ['Maha Shivaratri'], icon: '🛕' },
    { name: 'Kasi Viswanathar Temple Tenkasi', location: 'Tenkasi, Tirunelveli, Tamil Nadu', deity: 'Lord Shiva', festivals: ['Maha Shivaratri', 'Karthigai Deepam'], icon: '🛕' },
    { name: 'Kanchi Kailasanathar Temple', location: 'Kanchipuram, Tamil Nadu', deity: 'Lord Shiva', festivals: ['Maha Shivaratri', 'Karthigai Deepam'], icon: '🛕' },
    { name: 'Kumbeswarar Temple', location: 'Kumbakonam, Tamil Nadu', deity: 'Lord Shiva', festivals: ['Maha Shivaratri', 'Mahamaham'], icon: '🛕' },
    { name: 'Thirunageswaram Rahu Temple', location: 'Thirunageswaram, Kumbakonam, Tamil Nadu', deity: 'Lord Shiva', festivals: ['Aadi Krithigai', 'Rahu Ketu Peyarchi'], icon: '🛕' },
    { name: 'Ranganathaswamy Temple Srirangam', location: 'Srirangam, Tiruchirappalli, Tamil Nadu', deity: 'Lord Vishnu', festivals: ['Vaikunta Ekadasi', 'Brahmotsavam'], icon: '🛕' },
    { name: 'Varadaraja Perumal Temple', location: 'Kanchipuram, Tamil Nadu', deity: 'Lord Vishnu', festivals: ['Brahmotsavam', 'Vaikunta Ekadasi'], icon: '🛕' },
    { name: 'Parthasarathy Temple', location: 'Triplicane, Chennai, Tamil Nadu', deity: 'Lord Vishnu', festivals: ['Brahmotsavam', 'Krishna Jayanthi'], icon: '🛕' },
    { name: 'Oppiliappan Temple', location: 'Thirunageswaram, Kumbakonam, Tamil Nadu', deity: 'Lord Vishnu', festivals: ['Vaikunta Ekadasi', 'Brahmotsavam'], icon: '🛕' },
    { name: 'Sarangapani Temple', location: 'Kumbakonam, Tamil Nadu', deity: 'Lord Vishnu', festivals: ['Vaikunta Ekadasi', 'Brahmotsavam'], icon: '🛕' },
    { name: 'Rajagopalaswamy Temple Mannargudi', location: 'Mannargudi, Tiruvarur, Tamil Nadu', deity: 'Lord Vishnu', festivals: ['Brahmotsavam', 'Vaikunta Ekadasi'], icon: '🛕' },
    { name: 'Meenakshi Amman Temple', location: 'Madurai, Tamil Nadu', deity: 'Goddess Meenakshi', festivals: ['Meenakshi Thirukalyanam', 'Navarathri'], icon: '🛕' },
    { name: 'Kamakshi Amman Temple', location: 'Kanchipuram, Tamil Nadu', deity: 'Goddess Kamakshi', festivals: ['Navarathri', 'Panguni Uthiram'], icon: '🛕' },
    { name: 'Mariamman Temple Samayapuram', location: 'Samayapuram, Tiruchirappalli, Tamil Nadu', deity: 'Goddess Mariamman', festivals: ['Panguni Uthiram', 'Navarathri'], icon: '🛕' },
    { name: 'Kanyakumari Bhagavathy Amman Temple', location: 'Kanyakumari, Tamil Nadu', deity: 'Goddess Kanyakumari', festivals: ['Navarathri', 'Vaikasi Visakam'], icon: '🛕' },
    { name: 'Ashtalakshmi Temple', location: 'Besant Nagar, Chennai, Tamil Nadu', deity: 'Goddess Lakshmi', festivals: ['Navarathri', 'Varalakshmi Vratam'], icon: '🛕' },
    { name: 'Uchipillaiyar Temple Rock Fort', location: 'Tiruchirappalli, Tamil Nadu', deity: 'Lord Ganesha', festivals: ['Ganesh Chaturthi', 'Karthigai Deepam'], icon: '🛕' },
    { name: 'Karpaga Vinayagar Temple', location: 'Pillayarpatti, Sivaganga, Tamil Nadu', deity: 'Lord Ganesha', festivals: ['Ganesh Chaturthi'], icon: '🛕' },
    { name: 'Shore Temple Mahabalipuram', location: 'Mahabalipuram, Chengalpattu, Tamil Nadu', deity: 'Lord Shiva', festivals: ['Maha Shivaratri', 'Dance Festival'], icon: '🛕' },
    { name: 'Suchindram Thanumalayan Temple', location: 'Suchindram, Kanyakumari, Tamil Nadu', deity: 'Lord Shiva Vishnu Brahma', festivals: ['Maha Shivaratri', 'Vaikunta Ekadasi'], icon: '🛕' },
  ];
}

// GET /api/ml-recommendations/:userEmail
router.get('/:userEmail', async (req, res) => {
  try {
    const { userEmail } = req.params;

    // Get DB temples
    const dbTemples = await Temple.find({}).lean();
    const dbFormatted = dbTemples.map(t => ({
      name:      t.name      || 'Temple',
      location:  t.location  || '',
      deity:     t.deity     || '',
      festivals: t.festivals || [],
      icon:      t.icon      || '🛕',
    }));

    // Combine DB + hardcoded, DB first
    const allTemples = [...dbFormatted, ...getHardcodedTemples()];

    // Remove duplicates by name
    const seen   = new Set();
    const unique = allTemples.filter(t => {
      const key = (t.name || '').toLowerCase().trim();
      if (seen.has(key)) return false;
      seen.add(key);
      return true;
    });

    const popular = unique.slice(0, 8);

    console.log(`🧠 ML for ${userEmail}: returning ${popular.length} temples (db:${dbFormatted.length} hardcoded:${getHardcodedTemples().length})`);

    return res.json({
      success:   true,
      type:      'popular',
      typeLabel: 'Popular Temples',
      forYou:    [],
      popular,
      temples:   popular,
      count:     popular.length,
    });

  } catch (err) {
    console.error('[ML Route] Error:', err.message, err.stack);
    return res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;