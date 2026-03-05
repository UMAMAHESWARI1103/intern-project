// fix_indexes.js
// Run this ONCE from your backend folder: node fix_indexes.js

require('dotenv').config();
const mongoose = require('mongoose');

async function fixIndexes() {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    console.log('✅ Connected to MongoDB');

    const col = mongoose.connection.collection('eventregistrations');

    // ── Drop ALL existing indexes except _id ─────────────────────────────
    const indexes = await col.indexes();
    console.log('Current indexes:', indexes.map(i => i.name));

    for (const idx of indexes) {
      if (idx.name !== '_id_') {
        await col.dropIndex(idx.name);
        console.log(`🗑️  Dropped index: ${idx.name}`);
      }
    }

    // ── Recreate correct indexes ──────────────────────────────────────────

    // 1. Real event duplicate prevention
    await col.createIndex(
      { eventId: 1, userEmail: 1 },
      { unique: true, sparse: true, name: 'real_event_user_unique' }
    );
    console.log('✅ Created index: real_event_user_unique');

    // 2. Sample event duplicate prevention
    await col.createIndex(
      { sampleEventId: 1, userEmail: 1 },
      { unique: true, sparse: true, name: 'sample_event_user_unique' }
    );
    console.log('✅ Created index: sample_event_user_unique');

    // 3. Regular lookup indexes
    await col.createIndex({ eventId: 1 },   { name: 'eventId_index' });
    await col.createIndex({ userId: 1 },    { name: 'userId_index' });
    await col.createIndex({ userEmail: 1 }, { name: 'userEmail_index' });
    console.log('✅ Created lookup indexes');

    console.log('\n🎉 All indexes fixed! Restart your backend now.');
    process.exit(0);
  } catch (err) {
    console.error('❌ Error:', err.message);
    process.exit(1);
  }
}

fixIndexes();