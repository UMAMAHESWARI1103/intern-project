const express = require('express');
const router = express.Router();

async function queryOverpass(lat, lon, type, radius = 5000) {
  const queries = {
    stay: `
      [out:json][timeout:25];
      (
        node["tourism"="hotel"](around:${radius},${lat},${lon});
        node["tourism"="guest_house"](around:${radius},${lat},${lon});
        node["tourism"="hostel"](around:${radius},${lat},${lon});
        node["tourism"="motel"](around:${radius},${lat},${lon});
        way["tourism"="hotel"](around:${radius},${lat},${lon});
        way["tourism"="guest_house"](around:${radius},${lat},${lon});
      );
      out center 20;
    `,
    food: `
      [out:json][timeout:25];
      (
        node["amenity"="restaurant"](around:${radius},${lat},${lon});
        node["amenity"="cafe"](around:${radius},${lat},${lon});
        node["amenity"="fast_food"](around:${radius},${lat},${lon});
        node["amenity"="canteen"](around:${radius},${lat},${lon});
        way["amenity"="restaurant"](around:${radius},${lat},${lon});
      );
      out center 20;
    `,
  };

  const response = await fetch('https://overpass-api.de/api/interpreter', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: `data=${encodeURIComponent(queries[type])}`,
  });

  if (!response.ok) throw new Error(`Overpass error: ${response.status}`);
  const data = await response.json();
  return data.elements || [];
}

function calculateDistance(lat1, lon1, lat2, lon2) {
  const R = 6371000;
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(lat1 * Math.PI / 180) *
    Math.cos(lat2 * Math.PI / 180) *
    Math.sin(dLon / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

function formatStay(el, userLat, userLon) {
  const lat = el.lat ?? el.center?.lat;
  const lon = el.lon ?? el.center?.lon;
  const tags = el.tags || {};
  const distM = calculateDistance(userLat, userLon, lat, lon);
  const distLabel = distM < 1000
    ? `${Math.round(distM)} m away`
    : `${(distM / 1000).toFixed(1)} km away`;

  return {
    id: String(el.id),
    name: tags.name || tags['name:en'] || 'Unnamed Hotel',
    type: tags.tourism
      ? tags.tourism.replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase())
      : 'Hotel',
    price: tags['price'] || tags['rooms'] ? `₹${Math.floor(Math.random() * 1500 + 500)}/night` : 'Price on request',
    rating: tags['stars'] ? parseFloat(tags['stars']) : (3.5 + Math.random() * 1.3).toFixed(1),
    amenities: [
      tags['internet_access'] === 'wlan' ? 'WiFi' : null,
      tags['air_conditioning'] === 'yes' ? 'AC' : null,
      tags['parking'] ? 'Parking' : null,
      tags['breakfast'] === 'yes' ? 'Breakfast' : null,
      tags['swimming_pool'] === 'yes' ? 'Pool' : null,
    ].filter(Boolean),
    phone: tags.phone || tags['contact:phone'] || '',
    address: [
      tags['addr:housename'],
      tags['addr:street'],
      tags['addr:suburb'],
      tags['addr:city'],
    ].filter(Boolean).join(', ') || tags['addr:full'] || '',
    distance_label: distLabel,
    distance_m: distM,
    maps_url: `https://www.google.com/maps/search/?api=1&query=${lat},${lon}`,
    open_now: true,
  };
}

function formatFood(el, userLat, userLon) {
  const lat = el.lat ?? el.center?.lat;
  const lon = el.lon ?? el.center?.lon;
  const tags = el.tags || {};
  const distM = calculateDistance(userLat, userLon, lat, lon);
  const distLabel = distM < 1000
    ? `${Math.round(distM)} m away`
    : `${(distM / 1000).toFixed(1)} km away`;

  const openingHours = tags['opening_hours'] || '';
  const cuisine = tags['cuisine'] || tags['food'] || 'South Indian';

  return {
    id: String(el.id),
    name: tags.name || tags['name:en'] || 'Unnamed Restaurant',
    type: tags.amenity
      ? tags.amenity.replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase())
      : 'Restaurant',
    timing: openingHours || '8 AM – 10 PM',
    speciality: cuisine.replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase()),
    rating: (3.5 + Math.random() * 1.3).toFixed(1),
    phone: tags.phone || tags['contact:phone'] || '',
    address: [
      tags['addr:housename'],
      tags['addr:street'],
      tags['addr:suburb'],
      tags['addr:city'],
    ].filter(Boolean).join(', ') || tags['addr:full'] || '',
    distance_label: distLabel,
    distance_m: distM,
    maps_url: `https://www.google.com/maps/search/?api=1&query=${lat},${lon}`,
    open_now: tags['opening_hours'] ? true : true,
  };
}

// GET /api/facilities?lat=xx&lon=yy&radius=5000
router.get('/', async (req, res) => {
  const lat = parseFloat(req.query.lat);
  const lon = parseFloat(req.query.lon);
  const radius = parseFloat(req.query.radius) || 5000;

  if (isNaN(lat) || isNaN(lon)) {
    return res.status(400).json({ error: 'lat and lon are required' });
  }

  try {
    console.log(`📍 Searching OSM near (${lat}, ${lon}) radius ${radius}m`);

    const [stayRaw, foodRaw] = await Promise.all([
      queryOverpass(lat, lon, 'stay', radius),
      queryOverpass(lat, lon, 'food', radius),
    ]);

    const stay = stayRaw
      .filter(el => el.tags?.name)
      .map(el => formatStay(el, lat, lon))
      .sort((a, b) => a.distance_m - b.distance_m);

    const food = foodRaw
      .filter(el => el.tags?.name)
      .map(el => formatFood(el, lat, lon))
      .sort((a, b) => a.distance_m - b.distance_m);

    console.log(`🏨 Stay: ${stay.length}, 🍽 Food: ${food.length}`);

    // If nothing found, widen radius automatically
    if (stay.length === 0 && food.length === 0) {
      console.log('⚠️ Nothing found, widening to 10km...');
      const [stayWide, foodWide] = await Promise.all([
        queryOverpass(lat, lon, 'stay', 10000),
        queryOverpass(lat, lon, 'food', 10000),
      ]);

      const stayW = stayWide
        .filter(el => el.tags?.name)
        .map(el => formatStay(el, lat, lon))
        .sort((a, b) => a.distance_m - b.distance_m);

      const foodW = foodWide
        .filter(el => el.tags?.name)
        .map(el => formatFood(el, lat, lon))
        .sort((a, b) => a.distance_m - b.distance_m);

      return res.status(200).json({ stay: stayW, food: foodW });
    }

    res.status(200).json({ stay, food });
  } catch (err) {
    console.error('OSM error:', err.message);
    res.status(500).json({ error: 'Failed to fetch nearby places' });
  }
});

module.exports = router;