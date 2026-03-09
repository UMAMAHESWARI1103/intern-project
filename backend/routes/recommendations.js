// backend/routes/recommendations.js
// ✅ Add this NEW file inside your existing: backend/routes/ folder
// Then register it in server.js (see bottom of this file)

const express = require('express');
const router = express.Router();
const axios = require('axios');

/**
 * GET /api/recommendations/:donorEmail
 *
 * Calls Python ML server → returns personalized temple suggestions
 * Flutter calls: GET http://YOUR_IP:3000/api/recommendations/uma@gmail.com
 */
router.get('/:donorEmail', async (req, res) => {
  try {
    const { donorEmail } = req.params;

    // Call Python Flask ML server running on port 5001
    const mlRes = await axios.get(
      `http://localhost:5001/recommend/${encodeURIComponent(donorEmail)}`,
      { timeout: 6000 }
    );

    const { type, message, suggestions } = mlRes.data;

    return res.json({
      success: true,
      type,        // "ml_recommendation" | "popular"
      message,
      recommendations: suggestions   // [{ templeId, templeName }, ...]
    });

  } catch (err) {
    console.error('[ML Recommendations Error]', err.message);
    return res.status(500).json({
      success: false,
      message: 'Recommendation service unavailable',
      recommendations: []
    });
  }
});

module.exports = router;

/*
─────────────────────────────────────────
ADD THESE 2 LINES TO YOUR server.js:
─────────────────────────────────────────

const recommendations = require('./routes/recommendations');
app.use('/api/recommendations', recommendations);

─────────────────────────────────────────
Also run in backend folder:
  npm install axios
─────────────────────────────────────────
*/