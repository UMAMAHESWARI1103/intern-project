/**
 * seedEvents.js  — run once to populate MongoDB with sample events
 * Usage:  node seedEvents.js
 */

const mongoose = require('mongoose');
require('dotenv').config();

const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/godsconnect';

// ── Inline schema (mirrors your Event model) ──────────────────────────────────
const eventSchema = new mongoose.Schema({
  title:          { type: String, required: true },
  description:    String,
  templeId:       String,
  templeName:     String,
  date:           Date,
  time:           String,
  location:       String,
  category:       { type: String, default: 'Other' },
  registrationFee:{ type: Number, default: 0 },
  isFree:         { type: Boolean, default: true },
  imageUrl:       { type: String, default: '' },
  maxParticipants:{ type: Number, default: 100 },
  registeredCount:{ type: Number, default: 0 },
  isActive:       { type: Boolean, default: true },
}, { timestamps: true });

const Event = mongoose.models.Event || mongoose.model('Event', eventSchema);

// ── Sample events ─────────────────────────────────────────────────────────────
const sampleEvents = [
  {
    title: 'Maha Shivaratri Celebrations',
    description: 'Grand celebration with special abhishekam, bhajans, and night-long pooja. All devotees are welcome to participate.',
    templeName: 'Sri Venkateswara Temple',
    templeId: '1',
    date: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000),
    time: '6:00 AM – 6:00 AM (Next day)',
    location: 'Tirupati, Andhra Pradesh',
    category: 'Festival',
    registrationFee: 0,
    isFree: true,
    maxParticipants: 500,
    registeredCount: 120,
    isActive: true,
  },
  {
    title: 'Brahmotsavam Special Darshan',
    description: 'Annual Brahmotsavam festival with special processions, cultural programs, and divine darshan.',
    templeName: 'Meenakshi Temple',
    templeId: '2',
    date: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
    time: '5:00 AM – 9:00 PM',
    location: 'Madurai, Tamil Nadu',
    category: 'Festival',
    registrationFee: 150,
    isFree: false,
    maxParticipants: 300,
    registeredCount: 89,
    isActive: true,
  },
  {
    title: 'Karthigai Deepam Pooja',
    description: 'Special Karthigai Deepam celebration with thousands of lamps illuminating the entire temple complex.',
    templeName: 'Brihadeeswarar Temple',
    templeId: '3',
    date: new Date(Date.now() + 10 * 24 * 60 * 60 * 1000),
    time: '7:00 PM – 10:00 PM',
    location: 'Thanjavur, Tamil Nadu',
    category: 'Special',
    registrationFee: 0,
    isFree: true,
    maxParticipants: 200,
    registeredCount: 45,
    isActive: true,
  },
  {
    title: 'Satabhishekam Homam',
    description: 'Powerful homam ceremony for long life and prosperity. Performed by expert priests with full Vedic rituals.',
    templeName: 'Sri Venkateswara Temple',
    templeId: '1',
    date: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000),
    time: '8:00 AM – 12:00 PM',
    location: 'Tirupati, Andhra Pradesh',
    category: 'Pooja',
    registrationFee: 500,
    isFree: false,
    maxParticipants: 50,
    registeredCount: 12,
    isActive: true,
  },
  {
    title: 'Navratri Dance Festival',
    description: 'Nine nights of classical dance performances by renowned artists celebrating the divine feminine energy.',
    templeName: 'Meenakshi Temple',
    templeId: '2',
    date: new Date(Date.now() + 21 * 24 * 60 * 60 * 1000),
    time: '6:30 PM – 9:30 PM',
    location: 'Madurai, Tamil Nadu',
    category: 'Cultural',
    registrationFee: 0,
    isFree: true,
    maxParticipants: 400,
    registeredCount: 201,
    isActive: true,
  },
];

// ── Run ───────────────────────────────────────────────────────────────────────
async function seed() {
  try {
    await mongoose.connect(MONGO_URI);
    console.log('✅  Connected to MongoDB:', MONGO_URI);

    const before = await Event.countDocuments();
    console.log(`📊  Events currently in DB: ${before}`);

    if (before > 0) {
      console.log('⚠️   Events already exist. Deleting old events and re-seeding...');
      await Event.deleteMany({});
    }

    const result = await Event.insertMany(sampleEvents);
    console.log(`🎉  Successfully inserted ${result.length} sample events!`);
    console.log('   Titles added:');
    result.forEach(e => console.log(`   • ${e.title}`));

  } catch (err) {
    console.error('❌  Seed failed:', err.message);
  } finally {
    await mongoose.disconnect();
    console.log('🔌  Disconnected from MongoDB. Done!');
  }
}

seed();