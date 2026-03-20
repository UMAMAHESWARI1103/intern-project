const express    = require('express');
const mongoose   = require('mongoose');
const cors       = require('cors');
const facilitiesRoutes = require('./routes/facilities');
const recommendations = require('./routes/recommendations');
const mlRec = require('./routes/mlRecommendations')
const priestRoutes = require('./routes/priests');
require('dotenv').config();

const app = express();

app.use(cors());
app.use(express.json());

// ─── ROUTES ──────────────────────────────────────────────────────────────────
app.use('/api/auth',          require('./routes/auth'));
app.use('/api/temples',       require('./routes/temples'));
app.use('/api/admin',         require('./routes/admin'));
app.use('/api/events',        require('./routes/events'));
app.use('/api/products',      require('./routes/products'));
app.use('/api/donations',     require('./routes/donations'));
app.use('/api/prayers',       require('./routes/prayers'));
app.use('/api/payments',      require('./routes/payment'));
app.use('/api/facilities',    facilitiesRoutes);
app.use('/api/bookings',      require('./routes/booking'));
app.use('/api/users',         require('./routes/users'));
app.use('/api/orders',        require('./routes/orders'));
app.use('/api/recommendations',    recommendations);
app.use('/api/ml-recommendations', mlRec);
app.use('/api/priests',       priestRoutes); // ✅ user-facing: only available priests
app.use('/api/admin/priests', priestRoutes); // ✅ admin-facing: all priests

app.get('/', (req, res) => {
  res.json({ message: '🛕 GodsConnect Backend is running!' });
});

// ─── MONGODB ──────────────────────────────────────────────────────────────────
mongoose.connect(process.env.MONGO_URI)
  .then(() => console.log('✅ MongoDB Connected'))
  .catch((err) => console.log('❌ MongoDB Error:', err.message));

// ─── START ────────────────────────────────────────────────────────────────────
const PORT = process.env.PORT || 5000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Server running on http://localhost:${PORT}`);
});