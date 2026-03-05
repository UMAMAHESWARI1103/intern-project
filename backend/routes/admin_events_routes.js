// ── ADD THESE ROUTES to your backend/routes/admin.js ──────────────────────────
// These handle admin CRUD for events

const express = require('express');
const router  = express.Router();
const Event   = require('../models/Event');
const EventRegistration = require('../models/EventRegistration');

// You likely already have auth middleware — import it here
// const { protect, isAdmin } = require('../middleware/auth');
// Then add protect, isAdmin to each route below

// ── GET all events (admin) ────────────────────────────────────────────────────
router.get('/events', async (req, res) => {
  try {
    const events = await Event.find().sort({ createdAt: -1 });
    res.status(200).json(events.map(e => ({
      id:              e._id,
      title:           e.title,
      description:     e.description,
      templeName:      e.templeName,
      date:            e.date,
      time:            e.time,
      location:        e.location        || '',
      category:        e.category        || 'Other',
      price:           e.registrationFee ?? 0,
      isFree:          e.isFree          ?? true,
      maxCapacity:     e.maxParticipants  ?? 100,
      registeredCount: e.registeredCount  ?? 0,
      isActive:        e.isActive,
    })));
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// ── POST add event ────────────────────────────────────────────────────────────
router.post('/events', async (req, res) => {
  try {
    const {
      title, description, templeName, date, time,
      location, category, isFree, registrationFee,
      maxParticipants, isActive,
    } = req.body;

    if (!title || !date) {
      return res.status(400).json({ message: 'Title and date are required.' });
    }

    const event = new Event({
      title, description, templeName, date, time,
      location, category,
      isFree:          isFree ?? true,
      registrationFee: isFree ? 0 : (registrationFee ?? 0),
      maxParticipants: maxParticipants ?? 100,
      registeredCount: 0,
      isActive:        isActive ?? true,
    });

    await event.save();
    res.status(201).json({ message: 'Event created!', id: event._id });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// ── PUT update event ──────────────────────────────────────────────────────────
router.put('/events/:id', async (req, res) => {
  try {
    const {
      title, description, templeName, date, time,
      location, category, isFree, registrationFee,
      maxParticipants, isActive,
    } = req.body;

    const updated = await Event.findByIdAndUpdate(
      req.params.id,
      {
        title, description, templeName, date, time,
        location, category,
        isFree:          isFree ?? true,
        registrationFee: isFree ? 0 : (registrationFee ?? 0),
        maxParticipants: maxParticipants ?? 100,
        isActive:        isActive ?? true,
      },
      { new: true }
    );

    if (!updated) return res.status(404).json({ message: 'Event not found.' });
    res.status(200).json({ message: 'Event updated!', event: updated });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// ── DELETE event ──────────────────────────────────────────────────────────────
router.delete('/events/:id', async (req, res) => {
  try {
    await Event.findByIdAndDelete(req.params.id);
    // Also remove all registrations for this event
    await EventRegistration.deleteMany({ eventId: req.params.id });
    res.status(200).json({ message: 'Event deleted.' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// ── GET admin stats (update your existing stats route to include events) ──────
// Add these lines inside your existing /stats route:
//   const totalEvents        = await Event.countDocuments();
//   const totalRegistrations = await EventRegistration.countDocuments();
// And include them in the response:
//   res.json({ totalTemples, totalUsers, totalEvents, totalRegistrations });

module.exports = router;