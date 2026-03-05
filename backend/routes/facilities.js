const express = require('express');
const router = express.Router();

// ─────────────────────────────────────────
// HAVERSINE — calculate distance in km
// ─────────────────────────────────────────
function calculateDistance(lat1, lon1, lat2, lon2) {
  if (!lat1 || !lon1 || !lat2 || !lon2) return null;
  const R = 6371;
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
    Math.sin(dLon / 2) * Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return parseFloat((R * c).toFixed(2));
}

// ─────────────────────────────────────────
// STATIC FACILITIES DATA
// Each entry has lat/lon so distance can be calculated per user location
// ─────────────────────────────────────────
const STAY_FACILITIES = [
  {
    id: 's001', name: 'Temple Stay Guest House', type: 'Guest House',
    price: '₹800/night', rating: 4.2,
    amenities: ['WiFi', 'AC', 'Parking'], phone: '+91 9876543210',
    lat: 10.7835, lon: 79.1320,  // near Thanjavur
  },
  {
    id: 's002', name: 'Pilgrim Residency', type: 'Hotel',
    price: '₹1200/night', rating: 4.5,
    amenities: ['WiFi', 'AC', 'Restaurant', 'Parking'], phone: '+91 9876543211',
    lat: 10.7840, lon: 79.1310,
  },
  {
    id: 's003', name: 'Dharmasala Bhavan', type: 'Dharmasala',
    price: '₹200/night', rating: 3.8,
    amenities: ['Basic Rooms', 'Veg Kitchen'], phone: '+91 9876543212',
    lat: 9.9200, lon: 78.1190,  // near Madurai
  },
  {
    id: 's004', name: 'Sri Krishna Lodging', type: 'Lodge',
    price: '₹600/night', rating: 4.0,
    amenities: ['WiFi', 'Hot Water'], phone: '+91 9876543213',
    lat: 11.3990, lon: 79.6930,  // near Chidambaram
  },
  {
    id: 's005', name: 'Ananda Inn', type: 'Hotel',
    price: '₹950/night', rating: 4.3,
    amenities: ['WiFi', 'AC', 'Breakfast'], phone: '+91 9876543214',
    lat: 10.8617, lon: 78.6899,  // near Srirangam
  },
  {
    id: 's006', name: 'Rameswaram Pilgrim House', type: 'Guest House',
    price: '₹500/night', rating: 4.1,
    amenities: ['Basic Rooms', 'Hot Water', 'Parking'], phone: '+91 9876543215',
    lat: 9.2880, lon: 79.3130,  // Rameswaram
  },
  {
    id: 's007', name: 'Kanchipuram Yatri Nivas', type: 'Dharmasala',
    price: '₹300/night', rating: 3.9,
    amenities: ['Basic Rooms', 'Veg Kitchen', 'Parking'], phone: '+91 9876543216',
    lat: 12.8389, lon: 79.7003,  // Kanchipuram
  },
  {
    id: 's008', name: 'Tirupati Cottages', type: 'Hotel',
    price: '₹1100/night', rating: 4.4,
    amenities: ['WiFi', 'AC', 'Restaurant'], phone: '+91 9876543217',
    lat: 13.6288, lon: 79.4192,  // Tirupati
  },
  {
    id: 's009', name: 'Murugan Bhavan', type: 'Lodge',
    price: '₹400/night', rating: 3.7,
    amenities: ['Basic Rooms', 'Hot Water'], phone: '+91 9876543218',
    lat: 10.4461, lon: 77.5196,  // Palani
  },
  {
    id: 's010', name: 'Courtallam Stay', type: 'Hotel',
    price: '₹850/night', rating: 4.2,
    amenities: ['WiFi', 'AC', 'Parking'], phone: '+91 9876543219',
    lat: 8.9386, lon: 77.2768,  // Courtallam
  },
];

const FOOD_FACILITIES = [
  {
    id: 'f001', name: 'Annapurna Bhojanalaya', type: 'Pure Veg',
    timing: '6 AM – 9 PM', speciality: 'South Indian',
    rating: 4.6, phone: '+91 9876543220',
    lat: 10.7828, lon: 79.1318,  // near Thanjavur
  },
  {
    id: 'f002', name: 'Prasadam Canteen', type: 'Temple Canteen',
    timing: '5 AM – 8 PM', speciality: 'Traditional Meals',
    rating: 4.3, phone: '+91 9876543221',
    lat: 9.9195, lon: 78.1193,  // near Madurai
  },
  {
    id: 'f003', name: 'Saraswathi Mess', type: 'Mess',
    timing: '7 AM – 10 PM', speciality: 'North & South Indian',
    rating: 4.0, phone: '+91 9876543222',
    lat: 11.3993, lon: 79.6934,  // near Chidambaram
  },
  {
    id: 'f004', name: 'Sri Lakshmi Sweets', type: 'Sweet Shop',
    timing: '8 AM – 9 PM', speciality: 'Traditional Sweets & Snacks',
    rating: 4.5, phone: '+91 9876543223',
    lat: 10.8617, lon: 78.6899,  // near Srirangam
  },
  {
    id: 'f005', name: 'Murugan Idly Shop', type: 'Pure Veg',
    timing: '6 AM – 11 PM', speciality: 'Tiffin & Meals',
    rating: 4.7, phone: '+91 9876543224',
    lat: 9.2885, lon: 79.3129,  // Rameswaram
  },
  {
    id: 'f006', name: 'Kanchi Veg Palace', type: 'Pure Veg',
    timing: '7 AM – 10 PM', speciality: 'South Indian Thali',
    rating: 4.2, phone: '+91 9876543225',
    lat: 12.8474, lon: 79.6980,  // Kanchipuram
  },
  {
    id: 'f007', name: 'Palani Bhojana Sala', type: 'Temple Canteen',
    timing: '6 AM – 8 PM', speciality: 'Prasadam & Meals',
    rating: 4.0, phone: '+91 9876543226',
    lat: 10.4461, lon: 77.5196,  // Palani
  },
  {
    id: 'f008', name: 'Trichy Sree Vilas', type: 'Hotel',
    timing: '7 AM – 11 PM', speciality: 'Multi-cuisine Veg',
    rating: 4.3, phone: '+91 9876543227',
    lat: 10.8205, lon: 78.6897,  // Trichy
  },
];

// ─────────────────────────────────────────
// APPLY DISTANCE & SORT
// ─────────────────────────────────────────
function withDistance(items, userLat, userLon) {
  const hasLocation = !isNaN(userLat) && !isNaN(userLon);
  return items
    .map(item => ({
      ...item,
      distance: hasLocation
        ? (calculateDistance(userLat, userLon, item.lat, item.lon) ?? 9999)
        : 9999,
      distance_label: hasLocation
        ? `${calculateDistance(userLat, userLon, item.lat, item.lon) ?? '?'} km`
        : 'Distance unavailable',
    }))
    .sort((a, b) => a.distance - b.distance);
}

// ─────────────────────────────────────────
// ROUTES
// ─────────────────────────────────────────

// GET /api/facilities/stay?lat=xx&lon=yy&radius=50
router.get('/stay', (req, res) => {
  const userLat = parseFloat(req.query.lat);
  const userLon = parseFloat(req.query.lon);
  const radius  = parseFloat(req.query.radius) || 200; // default 200 km

  let results = withDistance(STAY_FACILITIES, userLat, userLon);

  if (!isNaN(userLat) && !isNaN(userLon)) {
    results = results.filter(item => item.distance <= radius);
  }

  res.status(200).json(results);
});

// GET /api/facilities/food?lat=xx&lon=yy&radius=50
router.get('/food', (req, res) => {
  const userLat = parseFloat(req.query.lat);
  const userLon = parseFloat(req.query.lon);
  const radius  = parseFloat(req.query.radius) || 200;

  let results = withDistance(FOOD_FACILITIES, userLat, userLon);

  if (!isNaN(userLat) && !isNaN(userLon)) {
    results = results.filter(item => item.distance <= radius);
  }

  res.status(200).json(results);
});

// GET /api/facilities?lat=xx&lon=yy — returns both
router.get('/', (req, res) => {
  const userLat = parseFloat(req.query.lat);
  const userLon = parseFloat(req.query.lon);
  const radius  = parseFloat(req.query.radius) || 200;

  let stay = withDistance(STAY_FACILITIES, userLat, userLon);
  let food = withDistance(FOOD_FACILITIES, userLat, userLon);

  if (!isNaN(userLat) && !isNaN(userLon)) {
    stay = stay.filter(item => item.distance <= radius);
    food = food.filter(item => item.distance <= radius);
  }

  res.status(200).json({ stay, food });
});

module.exports = router;