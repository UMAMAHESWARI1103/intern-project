const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const Priest = require('../models/Priest');

// ─────────────────────────────────────────
// SIGN UP
// POST /api/auth/signup
// ─────────────────────────────────────────
router.post('/signup', async (req, res) => {
  try {
    const { name, email, phone, password } = req.body;

    // Check if user already exists
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({ message: 'Email already registered' });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Create user (role defaults to 'user')
    const user = new User({
      name,
      email,
      phone,
      password: hashedPassword,
      role: 'user',
    });

    await user.save();

    res.status(201).json({ message: 'Account created successfully!' });
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// ─────────────────────────────────────────
// LOGIN
// POST /api/auth/login
// Checks: User collection first, then Priest collection
// ─────────────────────────────────────────
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    // ── 1. Check User collection ─────────────────────────────
    const user = await User.findOne({ email });
    if (user) {
      // Check if blocked
      if (user.isBlocked) {
        return res.status(403).json({
          message: 'Your account has been blocked. Contact support.',
        });
      }

      // Check password
      const isMatch = await bcrypt.compare(password, user.password);
      if (!isMatch) {
        return res.status(401).json({ message: 'Incorrect password' });
      }

      // Generate JWT
      const token = jwt.sign(
        { id: user._id, email: user.email, role: user.role },
        process.env.JWT_SECRET,
        { expiresIn: '7d' }
      );

      return res.status(200).json({
        message: 'Login successful!',
        token,
        role: user.role, // 'user' or 'admin'
        user: {
          id:    user._id,
          name:  user.name,
          email: user.email,
          phone: user.phone,
          role:  user.role,
        },
      });
    }

    // ── 2. Check Priest collection ───────────────────────────
    const priest = await Priest.findOne({ email });
    if (priest) {
      // Not yet approved by admin
      if (!priest.isApproved) {
        return res.status(403).json({
          message: 'Your priest account is pending admin approval. Please wait.',
        });
      }

      // Check password
      const isMatch = await bcrypt.compare(password, priest.password);
      if (!isMatch) {
        return res.status(401).json({ message: 'Incorrect password' });
      }

      // Generate JWT with role: 'priest'
      const token = jwt.sign(
        { id: priest._id, email: priest.email, role: 'priest' },
        process.env.JWT_SECRET,
        { expiresIn: '7d' }
      );

      return res.status(200).json({
        message: 'Login successful!',
        token,
        role: 'priest',
        priest: {
          id:              priest._id,
          name:            priest.name,
          email:           priest.email,
          phone:           priest.phone,
          location:        priest.location,
          specializations: priest.specializations,
          languages:       priest.languages,
          experience:      priest.experience,
          rating:          priest.rating,
          isAvailable:     priest.isAvailable,
          role:            'priest',
        },
      });
    }

    // ── 3. Not found in either collection ───────────────────
    return res.status(404).json({
      message: 'No account found with this email',
    });

  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

module.exports = router;