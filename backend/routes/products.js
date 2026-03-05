// backend/routes/products.js
// User-facing: GET active products only
const express = require('express');
const router  = express.Router();
const Product = require('../models/Product');

// GET /api/products — public, active products only
router.get('/', async (req, res) => {
  try {
    const filter = { isActive: true };
    if (req.query.category && req.query.category !== 'all') {
      filter.category = req.query.category;
    }
    if (req.query.search) {
      filter.$or = [
        { name:     { $regex: req.query.search, $options: 'i' } },
        { category: { $regex: req.query.search, $options: 'i' } },
        { tags:     { $in: [new RegExp(req.query.search, 'i')] } },
      ];
    }
    const products = await Product.find(filter).sort({ createdAt: -1 });
    res.status(200).json(products);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;