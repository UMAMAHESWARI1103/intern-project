// routes/priests.js
const express = require('express');
const router  = express.Router();
const Priest  = require('../models/Priest');

// GET all approved + available priests (optionally filter by homam type)
router.get('/', async (req, res) => {
  try {
    const filter = {};
    if (req.query.homamType) {
      filter.specializations = { $in: [req.query.homamType] };
    }
    const priests = await Priest.find(filter).sort({ rating: -1 });
    res.json({ success: true, priests });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// GET single priest
router.get('/:id', async (req, res) => {
  try {
    const priest = await Priest.findById(req.params.id);
    if (!priest) {
      return res.status(404).json({ success: false, message: 'Priest not found' });
    }
    res.json({ success: true, priest });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// PUT update priest (availability, profile etc.)
router.put('/:id', async (req, res) => {
  try {
    const priest = await Priest.findByIdAndUpdate(req.params.id, req.body, { new: true });
    res.json({ success: true, priest });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// PATCH availability toggle
router.patch('/:id/availability', async (req, res) => {
  try {
    const priest = await Priest.findByIdAndUpdate(
      req.params.id,
      { isAvailable: req.body.isAvailable },
      { new: true }
    );
    if (!priest) {
      return res.status(404).json({ success: false, message: 'Priest not found' });
    }
    res.json({ success: true, priest });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// DELETE priest
router.delete('/:id', async (req, res) => {
  try {
    await Priest.findByIdAndDelete(req.params.id);
    res.json({ success: true, message: 'Priest deleted' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;