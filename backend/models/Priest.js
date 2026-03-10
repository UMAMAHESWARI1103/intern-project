// models/Priest.js
const mongoose = require('mongoose');

const priestSchema = new mongoose.Schema(
  {
    name:            { type: String, required: true },
    email:           { type: String, required: true, unique: true },
    phone:           { type: String, default: '' },
    password:        { type: String, default: '' },
    photo:           { type: String, default: '' },
    bio:             { type: String, default: '' },
    location:        { type: String, default: '' },
    experience:      { type: Number, default: 0 },
    specializations: [{ type: String }],
    languages:       [{ type: String }],
    isAvailable:     { type: Boolean, default: true },
    isApproved:      { type: Boolean, default: true },
    rating:          { type: Number, default: 0 },
    totalBookings:   { type: Number, default: 0 },
    role:            { type: String, default: 'priest' },
  },
  {
    timestamps: true,
    collection: 'priests', // ← explicitly maps to 'priests' collection in MongoDB
  }
);

module.exports = mongoose.model('Priest', priestSchema);