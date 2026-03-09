// backend/routes/mlRecommendations.js
const express = require('express');
const router  = express.Router();
const axios   = require('axios');

const ML_SERVER = 'http://localhost:5001';

// GET /api/ml-recommendations/:userEmail
router.get('/:userEmail', async (req, res) => {
  try {
    const { userEmail } = req.params;

    const mlRes = await axios.get(
      `${ML_SERVER}/recommend/${encodeURIComponent(userEmail)}`,
      { timeout: 8000 }
    );

    const { suggestions, type, typeLabel, count } = mlRes.data;

    return res.json({
      success:   true,
      type,
      typeLabel,
      count,
      temples:   suggestions,
    });

  } catch (err) {
    console.error('[ML Route] Error:', err.message);
    return res.status(500).json({
      success: false,
      message: 'ML server unavailable. Is python app.py running?',
      error:   err.message,
    });
  }
});

module.exports = router;