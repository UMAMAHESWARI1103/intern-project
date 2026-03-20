// routes/priests.js
const express = require('express');
const router  = express.Router();
const Priest  = require('../models/Priest');

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/priests        → USER: only available priests
// GET /api/admin/priests  → ADMIN: all priests (same route, different mount)
// ─────────────────────────────────────────────────────────────────────────────
router.get('/', async (req, res) => {
  try {
    const isAdminRoute = req.baseUrl.includes('/admin');

    // ✅ Admin sees ALL priests, users only see available ones
    const filter = isAdminRoute ? {} : { isAvailable: true };

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

// POST — add new priest (admin only)
router.post('/', async (req, res) => {
  try {
    const priest = new Priest({
      ...req.body,
      isApproved:  req.body.isApproved  ?? true,
      isAvailable: req.body.isAvailable ?? true,
    });
    await priest.save();
    res.status(201).json({ success: true, priest });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// PUT — update priest profile
router.put('/:id', async (req, res) => {
  try {
    const priest = await Priest.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true }
    );
    res.json({ success: true, priest });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// PATCH — toggle availability ✅
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
    console.log(`✅ Priest ${priest.name} availability set to: ${priest.isAvailable}`);
    res.json({ success: true, priest });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// DELETE — remove priest
router.delete('/:id', async (req, res) => {
  try {
    await Priest.findByIdAndDelete(req.params.id);
    res.json({ success: true, message: 'Priest deleted' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;