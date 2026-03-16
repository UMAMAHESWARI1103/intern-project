const express = require('express');
const router = express.Router();
const Groq = require('groq-sdk');

const groq = new Groq({
  apiKey: process.env.GROQ_API_KEY,
});

async function getCityFromCoords(lat, lon) {
  try {
    const res = await fetch(
      `https://nominatim.openstreetmap.org/reverse?lat=${lat}&lon=${lon}&format=json`,
      { headers: { 'User-Agent': 'GodsConnectApp/1.0' } }
    );
    const data = await res.json();
    const addr = data.address;
    return (
      addr.city ||
      addr.town ||
      addr.village ||
      addr.county ||
      addr.state ||
      'the given location'
    );
  } catch {
    return 'the given location';
  }
}

async function fetchFromGroq(lat, lon, city, type) {
  const isStay = type === 'stay';

  const prompt = `
You are a local travel assistant. The user is currently at:
- City/Area: ${city}
- Coordinates: ${lat}, ${lon}

Return a JSON array of exactly 8 real or realistic ${isStay
  ? 'hotels, lodges, guest houses, or dharmasalas'
  : 'vegetarian restaurants, mess, canteens, or food stalls'
} that would typically exist near ${city}, India.

Each object must have these exact fields:
{
  "id": "unique string",
  "name": "place name",
  "type": "${isStay ? 'Hotel / Lodge / Guest House / Dharmasala' : 'Restaurant / Mess / Temple Canteen / Sweet Shop'}",
  ${isStay
    ? '"price": "₹XXX/night",'
    : '"timing": "X AM – X PM",'
  }
  ${isStay
    ? '"amenities": ["WiFi", "AC", "Parking"],'
    : '"speciality": "South Indian / North Indian etc",'
  }
  "rating": 4.2,
  "phone": "+91 98XXXXXXXX",
  "address": "street or area name, ${city}",
  "distance_label": "X.X km away",
  "open_now": true
}

Rules:
- Use real area/street names from ${city}
- Ratings between 3.5 and 4.8
- Phone numbers must look real (Indian format)
- Distance between 0.5 km and 10 km
- Return ONLY the raw JSON array, no explanation, no markdown, no backticks
`;

  const completion = await groq.chat.completions.create({
    model: 'llama-3.3-70b-versatile',
    messages: [{ role: 'user', content: prompt }],
    temperature: 0.7,
    max_tokens: 2000,
  });

  const text = completion.choices[0]?.message?.content ?? '[]';
  const clean = text.replace(/```json|```/gi, '').trim();

  try {
    return JSON.parse(clean);
  } catch {
    const match = clean.match(/\[[\s\S]*\]/);
    return match ? JSON.parse(match[0]) : [];
  }
}

// GET /api/facilities?lat=xx&lon=yy
router.get('/', async (req, res) => {
  const lat = parseFloat(req.query.lat);
  const lon = parseFloat(req.query.lon);

  if (isNaN(lat) || isNaN(lon)) {
    return res.status(400).json({ error: 'lat and lon are required' });
  }

  try {
    const city = await getCityFromCoords(lat, lon);
    console.log(`📍 Location: ${city} (${lat}, ${lon})`);

    const [stay, food] = await Promise.all([
      fetchFromGroq(lat, lon, city, 'stay'),
      fetchFromGroq(lat, lon, city, 'food'),
    ]);

    console.log(`🏨 Stay: ${stay.length}, 🍽 Food: ${food.length}`);
    res.status(200).json({ stay, food, city });
  } catch (err) {
    console.error('Groq error:', err.message);
    res.status(500).json({ error: 'Failed to fetch facilities' });
  }
});

// GET /api/facilities/stay?lat=xx&lon=yy
router.get('/stay', async (req, res) => {
  const lat = parseFloat(req.query.lat);
  const lon = parseFloat(req.query.lon);

  if (isNaN(lat) || isNaN(lon)) {
    return res.status(400).json({ error: 'lat and lon required' });
  }

  try {
    const city = await getCityFromCoords(lat, lon);
    const stay = await fetchFromGroq(lat, lon, city, 'stay');
    res.status(200).json(stay);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /api/facilities/food?lat=xx&lon=yy
router.get('/food', async (req, res) => {
  const lat = parseFloat(req.query.lat);
  const lon = parseFloat(req.query.lon);

  if (isNaN(lat) || isNaN(lon)) {
    return res.status(400).json({ error: 'lat and lon required' });
  }

  try {
    const city = await getCityFromCoords(lat, lon);
    const food = await fetchFromGroq(lat, lon, city, 'food');
    res.status(200).json(food);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;