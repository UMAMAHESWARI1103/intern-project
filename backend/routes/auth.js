// routes/auth.js

const express = require('express');
const router  = express.Router();
const bcrypt  = require('bcryptjs');
const jwt     = require('jsonwebtoken');
const User    = require('../models/User');
const Priest  = require('../models/Priest');

// ─────────────────────────────────────────
// SIGN UP  —  POST /api/auth/signup
// ─────────────────────────────────────────
router.post('/signup', async (req, res) => {
  try {
    const { name, email, phone, password } = req.body;

    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({ message: 'Email already registered' });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

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
// LOGIN  —  POST /api/auth/login
// Step 1: Check users collection (user / admin)
// Step 2: Check priests collection (common priest login)
// ─────────────────────────────────────────
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    // ── STEP 1: Check users collection ───────────────────────
    const user = await User.findOne({ email });
    if (user) {
      if (user.isBlocked) {
        return res.status(403).json({
          message: 'Your account has been blocked. Contact support.',
        });
      }

      const isMatch = await bcrypt.compare(password, user.password);
      if (!isMatch) {
        return res.status(401).json({ message: 'Incorrect password' });
      }

      const token = jwt.sign(
        { id: user._id, email: user.email, role: user.role },
        process.env.JWT_SECRET,
        { expiresIn: '7d' }
      );

      return res.status(200).json({
        message: 'Login successful!',
        token,
        role: user.role,
        user: {
          id:    user._id,
          name:  user.name,
          email: user.email,
          phone: user.phone,
          role:  user.role,
        },
      });
    }

    // ── STEP 2: Check priests collection ─────────────────────
    const priest = await Priest.findOne({ email });
    if (priest) {
      if (!priest.password) {
        return res.status(500).json({
          message: 'Priest account has no password set. Contact admin.',
        });
      }

      const isMatch = await bcrypt.compare(password, priest.password);
      if (!isMatch) {
        return res.status(401).json({ message: 'Incorrect password' });
      }

      const token = jwt.sign(
        { id: priest._id, email: priest.email, role: 'priest' },
        process.env.JWT_SECRET,
        { expiresIn: '7d' }
      );

      return res.status(200).json({
        message: 'Login successful!',
        token,
        role: 'priest',
        user: {
          id:    priest._id,
          name:  priest.name,
          email: priest.email,
          phone: priest.phone || '',
          role:  'priest',
        },
      });
    }

    // ── STEP 3: Not found anywhere ────────────────────────────
    return res.status(404).json({
      message: 'No account found with this email',
    });

  } catch (err) {
    console.error('Login error:', err.message);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

module.exports = router;