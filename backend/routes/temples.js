const express = require('express');
const router = express.Router();
const Temple = require('../models/temple');

// ─────────────────────────────────────────
// HAVERSINE — calculate distance in km
// ─────────────────────────────────────────
function calculateDistance(lat1, lon1, lat2, lon2) {
  if (!lat1 || !lon1 || !lat2 || !lon2) return null;
  const R = 6371;
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
    Math.sin(dLon / 2) * Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return parseFloat((R * c).toFixed(1));
}

// ─────────────────────────────────────────
// CHECK OPEN STATUS — supports two sessions
// Morning:  openTime  → closeTime
// Evening:  reopenTime → finalCloseTime
// ─────────────────────────────────────────
function parseHour(timeStr) {
  if (!timeStr) return 0;
  const [time, period] = timeStr.trim().split(' ');
  let [h, m] = time.split(':').map(Number);
  if (period === 'PM' && h !== 12) h += 12;
  if (period === 'AM' && h === 12) h = 0;
  return h + (m || 0) / 60;
}

function checkOpen(openTime, closeTime, reopenTime, finalCloseTime) {
  const now = new Date();
  const currentHour = now.getHours() + now.getMinutes() / 60;

  const open       = parseHour(openTime);
  const close      = parseHour(closeTime);
  const reopen     = parseHour(reopenTime);
  const finalClose = parseHour(finalCloseTime);

  // Morning session
  if (currentHour >= open && currentHour < close) return true;
  // Evening session
  if (currentHour >= reopen && currentHour < finalClose) return true;
  return false;
}

// ─────────────────────────────────────────
// FORMAT timing string for display
// e.g. "6:00 AM – 12:00 PM | 4:30 PM – 8:30 PM"
// ─────────────────────────────────────────
function formatTimings(openTime, closeTime, reopenTime, finalCloseTime) {
  return `${openTime} – ${closeTime} | ${reopenTime} – ${finalCloseTime}`;
}

// ─────────────────────────────────────────
// 50+ MAJOR TAMIL NADU TEMPLES
// All temples use authentic two-session timings
// ─────────────────────────────────────────
function getFallbackTemples() {
  return [

    // ══ ARUPADAI VEEDU — Six Abodes of Lord Murugan ══════════════════════
    {
      id: 1001,
      name: 'Palani Murugan Temple',
      location: 'Palani, Dindigul, Tamil Nadu',
      deity: 'Lord Murugan (Dhandayuthapani)',
      description: 'One of the six sacred abodes of Lord Murugan, perched on a 500-foot hill. The idol is made of rare Navapashanam herbal paste. Accessible by rope car or 693 steps. Draws over 5 million pilgrims annually.',
      image_url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5a/Palani_temple.jpg/480px-Palani_temple.jpg',
      open_time: '6:00 AM', close_time: '1:00 PM',
      reopen_time: '4:00 PM', final_close_time: '8:30 PM',
      festivals: ['Thaipusam', 'Skanda Shashti', 'Panguni Uthiram'],
      lat: 10.4461, lon: 77.5196,
    },
    {
      id: 1002,
      name: 'Thiruchendur Murugan Temple',
      location: 'Thiruchendur, Thoothukudi, Tamil Nadu',
      deity: 'Lord Murugan (Senthilandavar)',
      description: 'One of the six abodes of Lord Murugan, uniquely located on the seashore of the Bay of Bengal. The only Arupadai Veedu on the coast.',
      image_url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4d/Thiruchendur_Murugan_Temple.jpg/480px-Thiruchendur_Murugan_Temple.jpg',
      open_time: '5:00 AM', close_time: '12:30 PM',
      reopen_time: '4:00 PM', final_close_time: '9:00 PM',
      festivals: ['Skanda Shashti', 'Thaipusam', 'Vaikasi Visakam'],
      lat: 8.4961, lon: 78.1201,
    },
    {
      id: 1003,
      name: 'Swamimalai Murugan Temple',
      location: 'Swamimalai, Kumbakonam, Tamil Nadu',
      deity: 'Lord Murugan (Swaminatha)',
      description: 'One of the six abodes of Lord Murugan. Murugan is worshipped as a Guru here — he is believed to have taught the Pranava Mantra to his own father Lord Shiva.',
      image_url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c0/Swamimalai_temple.jpg/480px-Swamimalai_temple.jpg',
      open_time: '6:00 AM', close_time: '12:30 PM',
      reopen_time: '4:00 PM', final_close_time: '8:30 PM',
      festivals: ['Skanda Shashti', 'Thaipusam', 'Vaikasi Visakam'],
      lat: 10.9726, lon: 79.3296,
    },
    {
      id: 1004,
      name: 'Tiruttani Murugan Temple',
      location: 'Tiruttani, Ranipet, Tamil Nadu',
      deity: 'Lord Murugan (Subramaniaswamy)',
      description: 'One of the six abodes of Lord Murugan. Situated on a hill of 365 steps — one for each day of the year.',
      image_url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/65/Tiruttani_murugan_temple.jpg/480px-Tiruttani_murugan_temple.jpg',
      open_time: '6:00 AM', close_time: '1:00 PM',
      reopen_time: '4:00 PM', final_close_time: '8:30 PM',
      festivals: ['Skanda Shashti', 'Vaikasi Visakam'],
      lat: 13.1849, lon: 79.6157,
    },
    {
      id: 1005,
      name: 'Pazhamudircholai Murugan Temple',
      location: 'Alagar Kovil, Madurai, Tamil Nadu',
      deity: 'Lord Murugan (Pazhamudircholanathar)',
      description: 'One of the six abodes of Lord Murugan, nestled in the lush Alagar Hills near Madurai. Surrounded by dense forests with a stream.',
      image_url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/bf/Azhagar_Temple.jpg/480px-Azhagar_Temple.jpg',
      open_time: '6:00 AM', close_time: '12:30 PM',
      reopen_time: '4:30 PM', final_close_time: '8:00 PM',
      festivals: ['Vaikasi Visakam', 'Panguni Uthiram', 'Chithirai Festival'],
      lat: 9.9968, lon: 78.2362,
    },

    // ══ PANCHA BHUTA STALAS ═══════════════════════════════════════════════
    {
      id: 1006,
      name: 'Nataraja Temple, Chidambaram',
      location: 'Chidambaram, Cuddalore, Tamil Nadu',
      deity: 'Lord Nataraja (Shiva — Space element)',
      description: 'One of the Pancha Bhuta Stalas representing space (Akasha). Lord Shiva performed his cosmic Ananda Tandava dance here.',
      image_url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/51/Chidambaram_temple.jpg/480px-Chidambaram_temple.jpg',
      open_time: '6:00 AM', close_time: '12:30 PM',
      reopen_time: '4:30 PM', final_close_time: '8:30 PM',
      festivals: ['Natyanjali Festival', 'Maha Shivaratri', 'Arudra Darshan'],
      lat: 11.3993, lon: 79.6934,
    },
    {
      id: 1007,
      name: 'Ekambareswarar Temple',
      location: 'Kanchipuram, Tamil Nadu',
      deity: 'Lord Shiva (Ekambareswarar — Earth element)',
      description: 'One of the Pancha Bhuta Stalas representing earth (Prithvi). Has a famous mango tree over 3500 years old.',
      image_url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7e/Ekambareswarar_temple_Kanchipuram.jpg/480px-Ekambareswarar_temple_Kanchipuram.jpg',
      open_time: '6:00 AM', close_time: '12:30 PM',
      reopen_time: '4:00 PM', final_close_time: '8:30 PM',
      festivals: ['Maha Shivaratri', 'Panguni Uthiram'],
      lat: 12.8471, lon: 79.7003,
    },
    {
      id: 1008,
      name: 'Arunachaleswarar Temple',
      location: 'Thiruvannamalai, Tamil Nadu',
      deity: 'Lord Shiva (Arunachaleswarar — Fire element)',
      description: 'One of the Pancha Bhuta Stalas representing fire (Agni). The sacred Karthigai Deepam lamp is lit on top of Arunachala Hill every year.',
      image_url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e0/Annamalai_Temple_Thiruvannamalai.jpg/480px-Annamalai_Temple_Thiruvannamalai.jpg',
      open_time: '5:30 AM', close_time: '12:30 PM',
      reopen_time: '4:00 PM', final_close_time: '9:00 PM',
      festivals: ['Karthigai Deepam', 'Maha Shivaratri'],
      lat: 12.2315, lon: 79.0667,
    },
    {
      id: 1009,
      name: 'Jambukeswarar Temple',
      location: 'Thiruvanaikaval, Tiruchirappalli, Tamil Nadu',
      deity: 'Lord Shiva (Jambukeswarar — Water element)',
      description: 'One of the Pancha Bhuta Stalas representing water (Appu). The Shiva lingam is submerged in a natural spring inside the sanctum.',
      image_url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b8/Thiruvanaikaval_Jambukeswarar_temple.jpg/480px-Thiruvanaikaval_Jambukeswarar_temple.jpg',
      open_time: '6:00 AM', close_time: '12:30 PM',
      reopen_time: '4:00 PM', final_close_time: '8:30 PM',
      festivals: ['Maha Shivaratri', 'Panguni Uthiram'],
      lat: 10.8554, lon: 78.7063,
    },
    {
      id: 1010,
      name: 'Srikalahasti Temple (Wind)',
      location: 'Near Thiruvannamalai, Tamil Nadu',
      deity: 'Lord Shiva (Vayu — Air element)',
      description: 'One of the Pancha Bhuta Stalas representing air (Vayu). The flame in the sanctum flickers as if moved by wind even though there is no physical breeze.',
      image_url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/87/Srikalahasti_temple.jpg/480px-Srikalahasti_temple.jpg',
      open_time: '6:00 AM', close_time: '1:00 PM',
      reopen_time: '4:00 PM', final_close_time: '8:00 PM',
      festivals: ['Maha Shivaratri', 'Rahu Ketu Puja'],
      lat: 13.7500, lon: 79.6978,
    },

    // ══ FAMOUS SHIVA TEMPLES ══════════════════════════════════════════════
    {
      id: 1011,
      name: 'Brihadeeswarar Temple',
      location: 'Thanjavur, Tamil Nadu',
      deity: 'Lord Shiva (Brihadeeswara)',
      description: 'UNESCO World Heritage Site built by Raja Raja Chola I in 1010 CE. The shadow of the main tower never falls on the ground.',
      image_url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5a/Brihadeeswara_temple%2C_Thanjavur.jpg/480px-Brihadeeswara_temple%2C_Thanjavur.jpg',
      open_time: '6:00 AM', close_time: '12:30 PM',
      reopen_time: '4:00 PM', final_close_time: '8:30 PM',
      festivals: ['Maha Shivaratri', 'Karthigai Deepam', 'Raja Raja Chola Utsav'],
      lat: 10.7828, lon: 79.1318,
    },
    {
      id: 1012,
      name: 'Ramanathaswamy Temple',
      location: 'Rameswaram, Ramanathapuram, Tamil Nadu',
      deity: 'Lord Shiva (Ramanathaswamy)',
      description: 'One of the twelve sacred Jyotirlinga temples. Has the longest corridor (1.2 km) among all Hindu temples in India.',
      image_url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2e/Ramanathaswamy_Temple_Rameswaram.jpg/480px-Ramanathaswamy_Temple_Rameswaram.jpg',
      open_time: '5:00 AM', close_time: '1:00 PM',
      reopen_time: '3:00 PM', final_close_time: '9:00 PM',
      festivals: ['Maha Shivaratri', 'Brahmotsavam', 'Aadi Amavasai'],
      lat: 9.2885, lon: 79.3129,
    },
    {
      id: 1013,
      name: 'Kapaleeshwarar Temple',
      location: 'Mylapore, Chennai, Tamil Nadu',
      deity: 'Lord Shiva (Kapaleeshwarar)',
      description: 'A famous Dravidian temple in Mylapore, one of the oldest parts of Chennai. The magnificent colorful gopuram rises 37 metres.',
      image_url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/93/Kapaleeswarar_Temple%2C_Mylapore%2C_Chennai.jpg/480px-Kapaleeswarar_Temple%2C_Mylapore%2C_Chennai.jpg',
      open_time: '5:00 AM', close_time: '12:00 PM',
      reopen_time: '4:00 PM', final_close_time: '9:30 PM',
      festivals: ['Arubathimoovar Festival', 'Navarathri', 'Panguni Uthiram'],
      lat: 13.0339, lon: 80.2699,
    },
    {
      id: 1014,
      name: 'Nellaiappar Temple',
      location: 'Tirunelveli, Tamil Nadu',
      deity: 'Lord Shiva (Nellaiappar) & Goddess Kanthimathi',
      description: 'Famous worldwide for its musical pillars — each pillar produces a distinct musical note when tapped.',
      image_url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/83/Nellaiappar_temple.jpg/480px-Nellaiappar_temple.jpg',
      open_time: '6:00 AM', close_time: '12:30 PM',
      reopen_time: '4:30 PM', final_close_time: '8:30 PM',
      festivals: ['Maha Shivaratri', 'Navarathri', 'Adi Pooram'],
      lat: 8.7239, lon: 77.6938,
    },
    {
      id: 1015,
      name: 'Vaitheeswaran Koil',
      location: 'Vaitheeswaran Koil, Nagapattinam, Tamil Nadu',
      deity: 'Lord Shiva (Vaidyanatha) & Goddess Thaiyalnayaki',
      description: 'Lord Shiva is worshipped as Vaidyanatha — the God of healing. The temple tank water is believed to cure diseases.',
      image_url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/15/Vaitheeswaran_Koil.jpg/480px-Vaitheeswaran_Koil.jpg',
      open_time: '5:30 AM', close_time: '1:00 PM',
      reopen_time: '4:00 PM', final_close_time: '9:00 PM',
      festivals: ['Maha Shivaratri', 'Soorasamharam', 'Skanda Shashti'],
      lat: 11.1607, lon: 79.6559,
    },
    {
      id: 1016,
      name: 'Airavatheeswarar Temple',
      location: 'Darasuram, Kumbakonam, Tamil Nadu',
      deity: 'Lord Shiva (Airavatheeswarar)',
      description: 'UNESCO World Heritage Site — part of the Great Living Chola Temples. Known for its unique musical steps (Saptaswaras).',
      image_url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4d/Airavatesvara_temple.jpg/480px-Airavatesvara_temple.jpg',
      open_time: '6:00 AM', close_time: '12:30 PM',
      reopen_time: '4:00 PM', final_close_time: '8:00 PM',
      festivals: ['Maha Shivaratri', 'Karthigai Deepam'],
      lat: 10.9547, lon: 79.3581,
    },
    {
      id: 1017,
      name: 'Thillai Nataraja Temple',
      location: 'Chidambaram, Cuddalore, Tamil Nadu',
      deity: 'Lord Nataraja (Cosmic Dancer)',
      description: 'Ancient sacred temple where Lord Shiva performed the cosmic Ananda Tandava dance.',
      image_url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/51/Chidambaram_temple.jpg/480px-Chidambaram_temple.jpg',
      open_time: '6:00 AM', close_time: '12:30 PM',
      reopen_time: '4:30 PM', final_close_time: '8:30 PM',
      festivals: ['Natyanjali', 'Arudra Darshan', 'Maha Shivaratri'],
      lat: 11.3993, lon: 79.6934,
    },
    {
      id: 1018,
      name: 'Suchindram Thanumalayan Temple',
      location: 'Suchindram, Kanyakumari, Tamil Nadu',
      deity: 'Lord Shiva, Vishnu & Brahma (Trinity)',
      description: 'A uniquely rare temple where the Hindu Trinity — Shiva, Vishnu and Brahma — are worshipped together as one.',
      image_url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Sthanumalayan_temple_Suchindram.jpg/480px-Sthanumalayan_temple_Suchindram.jpg',
      open_time: '5:00 AM', close_time: '12:30 PM',
      reopen_time: '4:30 PM', final_close_time: '8:30 PM',
      festivals: ['Maha Shivaratri', 'Vaikunta Ekadasi', 'Navarathri'],
      lat: 8.1573, lon: 77.4666,
    },
    {
      id: 1019,
      name: 'Kasi Viswanathar Temple',
      location: 'Tenkasi, Tirunelveli, Tamil Nadu',
      deity: 'Lord Shiva (Kasi Viswanathar)',
      description: 'Known as the Kashi of the South. Located at the base of the Western Ghats with the Courtallam waterfall nearby.',
      image_url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/49/Tenkasi_Vishwanatha_temple.jpg/480px-Tenkasi_Vishwanatha_temple.jpg',
      open_time: '6:00 AM', close_time: '12:30 PM',
      reopen_time: '4:30 PM', final_close_time: '8:00 PM',
      festivals: ['Maha Shivaratri', 'Karthigai Deepam'],
      lat: 8.9601, lon: 77.3153,
    },
    {
      id: 1020,
      name: 'Gangaikonda Cholapuram Temple',
      location: 'Gangaikonda Cholapuram, Ariyalur, Tamil Nadu',
      deity: 'Lord Shiva (Brihadeeswara)',
      description: 'UNESCO World Heritage Site — built by Rajendra Chola I in 1035 CE to commemorate his conquest up to the Ganges river.',
      image_url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/68/Gangaikonda_Cholapuram.jpg/480px-Gangaikonda_Cholapuram.jpg',
      open_time: '6:00 AM', close_time: '12:30 PM',
      reopen_time: '4:00 PM', final_close_time: '8:00 PM',
      festivals: ['Maha Shivaratri', 'Chola Heritage Festival'],
      lat: 11.2073, lon: 79.4511,
    },

    // ══ FAMOUS VISHNU / PERUMAL TEMPLES ══════════════════════════════════
    {
      id: 1021,
      name: 'Ranganathaswamy Temple, Srirangam',
      location: 'Srirangam, Tiruchirappalli, Tamil Nadu',
      deity: 'Lord Ranganatha (Vishnu reclining)',
      description: 'The largest functioning Hindu temple in the world, covering 156 acres with 21 gopurams.',
      image_url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/47/Sri_Ranganathaswamy_Temple%2C_Srirangam.jpg/480px-Sri_Ranganathaswamy_Temple%2C_Srirangam.jpg',
      open_time: '6:00 AM', close_time: '1:00 PM',
      reopen_time: '3:15 PM', final_close_time: '9:00 PM',
      festivals: ['Vaikunta Ekadasi', 'Brahmotsavam', 'Panguni Uthiram'],
      lat: 10.8617, lon: 78.6899,
    },
    {
      id: 1022,
      name: 'Varadaraja Perumal Temple',
      location: 'Kanchipuram, Tamil Nadu',
      deity: 'Lord Vishnu (Varadaraja)',
      description: 'One of the 108 Divya Desams. Famous for its magnificent 100-pillar mandapam with intricate Vijayanagara-era sculptures.',
      image_url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/89/Varadaraja_Perumal_Temple_Kanchipuram.jpg/480px-Varadaraja_Perumal_Temple_Kanchipuram.jpg',
      open_time: '7:00 AM', close_time: '12:30 PM',
      reopen_time: '4:00 PM', final_close_time: '8:00 PM',
      festivals: ['Brahmotsavam', 'Vaikunta Ekadasi', 'Garuda Seva'],
      lat: 12.8432, lon: 79.7156,
    },
    {
      id: 1023,
      name: 'Parthasarathy Temple',
      location: 'Triplicane, Chennai, Tamil Nadu',
      deity: 'Lord Krishna (Parthasarathy)',
      description: 'One of the 108 Divya Desams built by Pallava kings in the 8th century. One of the oldest temples in Chennai.',
      image_url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8f/Parthasarathy_temple_Chennai.jpg/480px-Parthasarathy_temple_Chennai.jpg',
      open_time: '7:00 AM', close_time: '12:00 PM',
      reopen_time: '4:00 PM', final_close_time: '8:30 PM',
      festivals: ['Brahmotsavam', 'Krishna Jayanthi', 'Vaikunta Ekadasi'],
      lat: 13.0569, lon: 80.2729,
    },
    {
      id: 1024,
      name: 'Thillai Kali Amman Temple',
      location: 'Chidambaram, Cuddalore, Tamil Nadu',
      deity: 'Goddess Kali (Thillai Kali)',
      description: 'An ancient powerful Kali temple adjacent to the famous Nataraja temple in Chidambaram.',
      image_url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/fb/Chidambaram_kali_amman.jpg/480px-Chidambaram_kali_amman.jpg',
      open_time: '6:00 AM', close_time: '12:30 PM',
      reopen_time: '4:30 PM', final_close_time: '8:00 PM',
      festivals: ['Navarathri', 'Karthigai Deepam'],
      lat: 11.3990, lon: 79.6940,
    },
    {
      id: 1025,
      name: 'Oppiliappan Temple',
      location: 'Thirunageswaram, Kumbakonam, Tamil Nadu',
      deity: 'Lord Vishnu (Oppiliappan)',
      description: 'One of the 108 Divya Desams. Famous as the temple where no salt is used in the food offered to the deity.',
      image_url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/57/Oppiliappan_temple.jpg/480px-Oppiliappan_temple.jpg',
      open_time: '6:00 AM', close_time: '12:30 PM',
      reopen_time: '4:00 PM', final_close_time: '8:00 PM',
      festivals: ['Vaikunta Ekadasi', 'Brahmotsavam'],
      lat: 10.9814, lon: 79.4051,
    },

    // ══ FAMOUS AMMAN / SHAKTI TEMPLES ════════════════════════════════════
    {
      id: 1026,
      name: 'Meenakshi Amman Temple',
      location: 'Madurai, Tamil Nadu',
      deity: 'Goddess Meenakshi & Lord Sundareswarar',
      description: 'One of the largest Hindu temples in the world. 14 magnificent painted gopurams, over 33,000 sculptures.',
      image_url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/9a/Madurai_Meenakshi_Amman_Temple.jpg/480px-Madurai_Meenakshi_Amman_Temple.jpg',
      open_time: '5:00 AM', close_time: '12:30 PM',
      reopen_time: '4:00 PM', final_close_time: '10:00 PM',
      festivals: ['Meenakshi Thirukalyanam', 'Navarathri', 'Chithirai Festival'],
      lat: 9.9195, lon: 78.1193,
    },
    {
      id: 1027,
      name: 'Kamakshi Amman Temple',
      location: 'Kanchipuram, Tamil Nadu',
      deity: 'Goddess Kamakshi (Parvati)',
      description: 'One of the most important Shakti Peethas in India. Adi Shankaracharya installed the Sri Chakra here.',
      image_url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2b/Kamakshi_Amman_Temple_Kanchipuram.jpg/480px-Kamakshi_Amman_Temple_Kanchipuram.jpg',
      open_time: '5:30 AM', close_time: '12:30 PM',
      reopen_time: '4:00 PM', final_close_time: '9:00 PM',
      festivals: ['Navarathri', 'Panguni Uthiram', 'Brahmotsavam'],
      lat: 12.8389, lon: 79.7003,
    },
    {
      id: 1028,
      name: 'Mariamman Temple Samayapuram',
      location: 'Samayapuram, Tiruchirappalli, Tamil Nadu',
      deity: 'Goddess Mariamman',
      description: 'One of the most visited temples in Tamil Nadu. Among the highest-revenue temples in India.',
      image_url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/87/Samayapuram_mariamman_temple.jpg/480px-Samayapuram_mariamman_temple.jpg',
      open_time: '5:00 AM', close_time: '12:30 PM',
      reopen_time: '4:00 PM', final_close_time: '9:00 PM',
      festivals: ['Panguni Uthiram', 'Navarathri', 'Aadi Festival'],
      lat: 10.9694, lon: 78.6434,
    },
    {
      id: 1029,
      name: 'Kanyakumari Bhagavathy Amman Temple',
      location: 'Kanyakumari, Tamil Nadu',
      deity: 'Goddess Kanyakumari (Devi Bhagavathi)',
      description: 'Located at the southernmost tip of India where the Arabian Sea, Bay of Bengal, and Indian Ocean converge.',
      image_url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6b/Kanyakumari_Temple.jpg/480px-Kanyakumari_Temple.jpg',
      open_time: '4:30 AM', close_time: '12:15 PM',
      reopen_time: '4:00 PM', final_close_time: '8:30 PM',
      festivals: ['Navarathri', 'Vaikasi Visakam', 'Adi Pooram'],
      lat: 8.0883, lon: 77.5385,
    },
    {
      id: 1030,
      name: 'Ashtalakshmi Temple',
      location: 'Besant Nagar, Chennai, Tamil Nadu',
      deity: 'Goddess Ashtalakshmi (8 forms of Lakshmi)',
      description: 'A beautiful modern temple right on the Bay of Bengal shore at Besant Nagar beach.',
      image_url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/25/Ashtalakshmi_temple%2C_Chennai.jpg/480px-Ashtalakshmi_temple%2C_Chennai.jpg',
      open_time: '6:00 AM', close_time: '12:00 PM',
      reopen_time: '4:00 PM', final_close_time: '9:00 PM',
      festivals: ['Navarathri', 'Lakshmi Puja', 'Varalakshmi Vratam'],
      lat: 13.0002, lon: 80.2710,
    },
    {
      id: 1031,
      name: 'Angalamman Temple',
      location: 'Therkku Patti, Virudhunagar, Tamil Nadu',
      deity: 'Goddess Angalamman',
      description: 'A highly revered village goddess temple near Virudhunagar. Known for fulfilling devotees\' wishes and granting prosperity.',
      image_url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/67/Angalamman_temple.jpg/480px-Angalamman_temple.jpg',
      open_time: '6:00 AM', close_time: '12:30 PM',
      reopen_time: '4:30 PM', final_close_time: '8:00 PM',
      festivals: ['Navarathri', 'Pongal'],
      lat: 9.5897, lon: 77.9174,
    },

    // ══ FAMOUS GANESHA TEMPLES ════════════════════════════════════════════
    {
      id: 1032,
      name: 'Uchipillaiyar Temple (Rock Fort)',
      location: 'Tiruchirappalli (Trichy), Tamil Nadu',
      deity: 'Lord Ganesha (Uchipillaiyar)',
      description: 'A famous Ganesha temple perched atop the iconic 83-metre Rock Fort in Trichy. Reached by 344 rock-cut steps.',
      image_url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5c/Rock_Fort_Temple_Trichy.jpg/480px-Rock_Fort_Temple_Trichy.jpg',
      open_time: '6:00 AM', close_time: '12:30 PM',
      reopen_time: '4:00 PM', final_close_time: '8:00 PM',
      festivals: ['Ganesh Chaturthi', 'Karthigai Deepam'],
      lat: 10.8205, lon: 78.6897,
    },
    {
      id: 1033,
      name: 'Karpaga Vinayagar Temple',
      location: 'Pillayarpatti, Sivaganga, Tamil Nadu',
      deity: 'Lord Ganesha (Karpaga Vinayagar)',
      description: 'An ancient rock-cut cave temple. The main idol is carved from a single rock and is believed to be over 1600 years old.',
      image_url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/97/Pillayarpatti_vinayagar_temple.jpg/480px-Pillayarpatti_vinayagar_temple.jpg',
      open_time: '6:00 AM', close_time: '12:30 PM',
      reopen_time: '4:30 PM', final_close_time: '8:00 PM',
      festivals: ['Ganesh Chaturthi', 'Vinayagar Chathurthi'],
      lat: 9.9785, lon: 78.6340,
    },

    // ══ FAMOUS VISHNU / DIVYA DESAM TEMPLES ══════════════════════════════
    {
      id: 1034,
      name: 'Azhagia Manavala Perumal Temple',
      location: 'Mayiladuthurai, Nagapattinam, Tamil Nadu',
      deity: 'Lord Vishnu (Trivikrama)',
      description: 'One of the 108 Divya Desams on the banks of the Cauvery river. The presiding deity is Trivikrama.',
      image_url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/44/Thiruvidandai_temple.jpg/480px-Thiruvidandai_temple.jpg',
      open_time: '6:00 AM', close_time: '12:30 PM',
      reopen_time: '4:00 PM', final_close_time: '8:00 PM',
      festivals: ['Vaikunta Ekadasi', 'Brahmotsavam'],
      lat: 11.1027, lon: 79.6531,
    },
    {
      id: 1035,
      name: 'Pandava Thoothar Perumal Temple',
      location: 'Kanchipuram, Tamil Nadu',
      deity: 'Lord Vishnu (Pandava Thoothar)',
      description: 'One of the 108 Divya Desams in Kanchipuram. Vishnu worshipped as the messenger of the Pandavas.',
      image_url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/35/Kanchipuram_perumal_temple.jpg/480px-Kanchipuram_perumal_temple.jpg',
      open_time: '7:00 AM', close_time: '12:00 PM',
      reopen_time: '4:00 PM', final_close_time: '7:30 PM',
      festivals: ['Vaikunta Ekadasi', 'Brahmotsavam'],
      lat: 12.8310, lon: 79.7060,
    },

    // ══ HERITAGE / UNESCO SITES ═══════════════════════════════════════════
    {
      id: 1036,
      name: 'Shore Temple',
      location: 'Mahabalipuram, Chengalpattu, Tamil Nadu',
      deity: 'Lord Shiva & Lord Vishnu',
      description: 'UNESCO World Heritage Site built by the Pallava king Narasimhavarman II in 700 CE. Stands on the shores of the Bay of Bengal.',
      image_url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c0/Shore_temple_at_Mahabalipuram.jpg/480px-Shore_temple_at_Mahabalipuram.jpg',
      open_time: '6:00 AM', close_time: '12:30 PM',
      reopen_time: '2:00 PM', final_close_time: '6:00 PM',
      festivals: ['Maha Shivaratri', 'Mahabalipuram Dance Festival'],
      lat: 12.6168, lon: 80.1993,
    },
    {
      id: 1037,
      name: 'Pancha Rathas',
      location: 'Mahabalipuram, Chengalpattu, Tamil Nadu',
      deity: 'Lord Shiva, Vishnu & Indra',
      description: 'UNESCO World Heritage monolithic rock-cut temples carved from a single rock each by Pallava king Narasimhavarman I (7th century CE).',
      image_url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/0/0b/Pancha_Rathas_Mahabalipuram.jpg/480px-Pancha_Rathas_Mahabalipuram.jpg',
      open_time: '6:00 AM', close_time: '12:30 PM',
      reopen_time: '2:00 PM', final_close_time: '6:00 PM',
      festivals: ['Mahabalipuram Dance Festival'],
      lat: 12.6234, lon: 80.1930,
    },

    // ══ NOTABLE REGIONAL TEMPLES ══════════════════════════════════════════
    {
      id: 1038,
      name: 'Murugan Temple, Vellore Fort',
      location: 'Vellore, Tamil Nadu',
      deity: 'Lord Murugan & Lord Jalakandeswarar',
      description: 'The Jalakandeswarar Temple inside Vellore Fort is a fine example of Vijayanagara architecture built in the 16th century.',
      image_url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/9f/Jalakandeswarar_temple_Vellore.jpg/480px-Jalakandeswarar_temple_Vellore.jpg',
      open_time: '6:00 AM', close_time: '12:30 PM',
      reopen_time: '4:00 PM', final_close_time: '8:00 PM',
      festivals: ['Maha Shivaratri', 'Karthigai Deepam'],
      lat: 12.9165, lon: 79.1325,
    },
    {
      id: 1039,
      name: 'Murugan Temple, Tiruppanandal',
      location: 'Tiruppanandal, Kumbakonam, Tamil Nadu',
      deity: 'Lord Murugan (Pazhamudhir Solai)',
      description: 'An important Murugan temple near Kumbakonam where Murugan blessed the sage Agastya.',
      image_url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/89/Tiruppanandal_temple.jpg/480px-Tiruppanandal_temple.jpg',
      open_time: '6:00 AM', close_time: '12:30 PM',
      reopen_time: '4:30 PM', final_close_time: '7:30 PM',
      festivals: ['Skanda Shashti', 'Thaipusam'],
      lat: 10.9419, lon: 79.3627,
    },
    {
      id: 1040,
      name: 'Sarangapani Temple',
      location: 'Kumbakonam, Tamil Nadu',
      deity: 'Lord Vishnu (Sarangapani)',
      description: 'One of the 108 Divya Desams. The 11-storeyed rajagopuram is 45 metres tall — one of the tallest in South India.',
      image_url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/85/Sarangapani_temple_Kumbakonam.jpg/480px-Sarangapani_temple_Kumbakonam.jpg',
      open_time: '7:00 AM', close_time: '12:30 PM',
      reopen_time: '4:00 PM', final_close_time: '8:30 PM',
      festivals: ['Vaikunta Ekadasi', 'Brahmotsavam'],
      lat: 10.9617, lon: 79.3795,
    },
    {
      id: 1041,
      name: 'Kumbeswarar Temple',
      location: 'Kumbakonam, Tamil Nadu',
      deity: 'Lord Shiva (Kumbeswarar)',
      description: 'One of the most important Shiva temples in Kumbakonam. The sacred Mahamaham tank draws millions every 12 years.',
      image_url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/dd/Kumbeswarar_temple_Kumbakonam.jpg/480px-Kumbeswarar_temple_Kumbakonam.jpg',
      open_time: '6:00 AM', close_time: '12:30 PM',
      reopen_time: '4:00 PM', final_close_time: '8:30 PM',
      festivals: ['Maha Shivaratri', 'Mahamaham (every 12 years)'],
      lat: 10.9651, lon: 79.3843,
    },
    {
      id: 1042,
      name: 'Thirunageswaram Rahu Temple',
      location: 'Thirunageswaram, Kumbakonam, Tamil Nadu',
      deity: 'Lord Shiva (Naganathaswamy) & Rahu',
      description: 'One of only a few temples in the world with a shrine dedicated to Rahu (the shadow planet).',
      image_url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2e/Thirunageswaram_temple.jpg/480px-Thirunageswaram_temple.jpg',
      open_time: '6:00 AM', close_time: '1:00 PM',
      reopen_time: '4:00 PM', final_close_time: '8:30 PM',
      festivals: ['Aadi Krithigai', 'Rahu Ketu Peyarchi'],
      lat: 10.9832, lon: 79.4064,
    },
    {
      id: 1043,
      name: 'Kanchi Kailasanathar Temple',
      location: 'Kanchipuram, Tamil Nadu',
      deity: 'Lord Shiva (Kailasanathar)',
      description: 'The oldest stone temple in Kanchipuram, built in the early 8th century by the Pallava king Rajasimha.',
      image_url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e8/Kailasanathar_temple_Kanchipuram.jpg/480px-Kailasanathar_temple_Kanchipuram.jpg',
      open_time: '6:00 AM', close_time: '12:30 PM',
      reopen_time: '4:00 PM', final_close_time: '8:00 PM',
      festivals: ['Maha Shivaratri', 'Karthigai Deepam'],
      lat: 12.8474, lon: 79.6980,
    },
    {
      id: 1044,
      name: 'Thiruparankundram Murugan Temple',
      location: 'Thiruparankundram, Madurai, Tamil Nadu',
      deity: 'Lord Murugan (Subramanya)',
      description: 'One of the six abodes of Lord Murugan. An ancient cave temple cut into a granite hill.',
      image_url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/3b/Thiruparankundram_murugan_temple.jpg/480px-Thiruparankundram_murugan_temple.jpg',
      open_time: '5:30 AM', close_time: '12:30 PM',
      reopen_time: '4:00 PM', final_close_time: '8:30 PM',
      festivals: ['Skanda Shashti', 'Thaipusam', 'Panguni Uthiram'],
      lat: 9.8795, lon: 78.0501,
    },
    {
      id: 1045,
      name: 'Arulmigu Rajagopalaswamy Temple',
      location: 'Mannargudi, Tiruvarur, Tamil Nadu',
      deity: 'Lord Vishnu (Rajagopalaswamy / Krishna)',
      description: 'One of the 108 Divya Desams. Known as the Dakshina Dwaraka. Has a massive sacred tank.',
      image_url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8e/Mannargudi_Rajagopalaswamy.jpg/480px-Mannargudi_Rajagopalaswamy.jpg',
      open_time: '6:00 AM', close_time: '1:00 PM',
      reopen_time: '4:00 PM', final_close_time: '9:00 PM',
      festivals: ['Brahmotsavam', 'Vaikunta Ekadasi', 'Rath Yatra'],
      lat: 10.6665, lon: 79.4524,
    },
    {
      id: 1046,
      name: 'Theppakulam Mariamman Temple',
      location: 'Madurai, Tamil Nadu',
      deity: 'Goddess Mariamman',
      description: 'Located adjacent to the famous Theppakulam tank in Madurai, associated with the annual Teppam float festival.',
      image_url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2d/Mariamman_Teppakkulam_Madurai.jpg/480px-Mariamman_Teppakkulam_Madurai.jpg',
      open_time: '6:00 AM', close_time: '12:30 PM',
      reopen_time: '4:30 PM', final_close_time: '8:00 PM',
      festivals: ['Teppam (Float) Festival', 'Navarathri'],
      lat: 9.9314, lon: 78.1392,
    },
    {
      id: 1047,
      name: 'Vedaranyeswarar Temple',
      location: 'Vedaranyam, Nagapattinam, Tamil Nadu',
      deity: 'Lord Shiva (Vedaranyeswarar)',
      description: 'An ancient Shiva temple in Vedaranyam at the end of the Cauvery delta.',
      image_url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/91/Vedaranyam_temple.jpg/480px-Vedaranyam_temple.jpg',
      open_time: '6:00 AM', close_time: '12:30 PM',
      reopen_time: '4:30 PM', final_close_time: '8:00 PM',
      festivals: ['Maha Shivaratri', 'Karthigai Deepam'],
      lat: 10.3742, lon: 79.8553,
    },
    {
      id: 1048,
      name: 'Ettukudi Murugan Temple',
      location: 'Ettukudi, Nagapattinam, Tamil Nadu',
      deity: 'Lord Murugan',
      description: 'A well-known Murugan temple on the Cauvery delta coast, surrounded by beautiful sea and backwaters.',
      image_url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a5/Murugan_temple.jpg/480px-Murugan_temple.jpg',
      open_time: '6:00 AM', close_time: '12:30 PM',
      reopen_time: '4:30 PM', final_close_time: '8:00 PM',
      festivals: ['Skanda Shashti', 'Thaipusam'],
      lat: 10.8619, lon: 79.8254,
    },
    {
      id: 1049,
      name: 'Govindrajaperumal Temple',
      location: 'Chidambaram, Cuddalore, Tamil Nadu',
      deity: 'Lord Vishnu (GovindaRaja)',
      description: 'One of the 108 Divya Desams located in Chidambaram. The presiding deity is worshipped in a sleeping posture.',
      image_url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5e/Govindaraja_Swami_Temple_Chidambaram.jpg/480px-Govindaraja_Swami_Temple_Chidambaram.jpg',
      open_time: '7:00 AM', close_time: '12:30 PM',
      reopen_time: '4:00 PM', final_close_time: '8:00 PM',
      festivals: ['Vaikunta Ekadasi', 'Brahmotsavam'],
      lat: 11.3978, lon: 79.6921,
    },
    {
      id: 1050,
      name: 'Murugan Temple, Sirkazhi',
      location: 'Sirkazhi, Nagapattinam, Tamil Nadu',
      deity: 'Lord Shiva (Brahmapureeswarar)',
      description: 'Birthplace of the great Shaivite saint Thirugnanasambandar (7th century CE). Has remarkable Chola-period bronze sculptures.',
      image_url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/31/Sirkazhi_brahmapureeswarar.jpg/480px-Sirkazhi_brahmapureeswarar.jpg',
      open_time: '6:00 AM', close_time: '12:30 PM',
      reopen_time: '4:30 PM', final_close_time: '8:00 PM',
      festivals: ['Maha Shivaratri', 'Thirugnanasambandar Jayanthi'],
      lat: 11.2388, lon: 79.7487,
    },
    {
      id: 1051,
      name: 'Dandayuthapani Swamy Temple',
      location: 'Courtallam (Kutralam), Tirunelveli, Tamil Nadu',
      deity: 'Lord Murugan (Dandayuthapani)',
      description: 'A Murugan temple near the famous Courtallam waterfalls — known as the Spa of South India.',
      image_url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/82/Courtallam_falls.jpg/480px-Courtallam_falls.jpg',
      open_time: '6:00 AM', close_time: '12:30 PM',
      reopen_time: '4:30 PM', final_close_time: '8:00 PM',
      festivals: ['Skanda Shashti', 'Thaipusam'],
      lat: 8.9386, lon: 77.2768,
    },
    {
      id: 1052,
      name: 'Thanumalayan Temple',
      location: 'Srivaikuntam, Thoothukudi, Tamil Nadu',
      deity: 'Lord Vishnu (Kalyana Perumal)',
      description: 'One of the 108 Divya Desams on the banks of the Thamirabarani river.',
      image_url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4d/Srivaikuntam_temple.jpg/480px-Srivaikuntam_temple.jpg',
      open_time: '7:00 AM', close_time: '12:30 PM',
      reopen_time: '4:00 PM', final_close_time: '8:00 PM',
      festivals: ['Vaikunta Ekadasi', 'Brahmotsavam'],
      lat: 8.6290, lon: 77.9094,
    },
    {
      id: 1053,
      name: 'Adikesava Perumal Temple',
      location: 'Thiruvattar, Kanyakumari, Tamil Nadu',
      deity: 'Lord Vishnu (Adikesava)',
      description: 'One of the 108 Divya Desams at the confluence of three rivers. Lord Vishnu is in a reclining posture.',
      image_url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c7/Thiruvattar_temple.jpg/480px-Thiruvattar_temple.jpg',
      open_time: '6:30 AM', close_time: '12:30 PM',
      reopen_time: '4:00 PM', final_close_time: '8:00 PM',
      festivals: ['Vaikunta Ekadasi', 'Brahmotsavam'],
      lat: 8.2305, lon: 77.3627,
    },

  ].map(t => ({
    ...t,
    distance: 0,
    is_open: checkOpen(t.open_time, t.close_time, t.reopen_time, t.final_close_time),
    icon: '🛕',
    // Convenience display string for the frontend
    timing_display: formatTimings(t.open_time, t.close_time, t.reopen_time, t.final_close_time),
  }));
}

// ─────────────────────────────────────────
// COMBINE DB + FALLBACK TEMPLES
// ─────────────────────────────────────────
async function getAllTemples() {
  const dbTemples = await Temple.find().sort({ createdAt: -1 });
  const dbFormatted = dbTemples.map((t, index) => {
    const openTime       = t.openTime       || '6:00 AM';
    const closeTime      = t.closeTime      || '12:00 PM';
    const reopenTime     = t.reopenTime     || '4:00 PM';
    const finalCloseTime = t.finalCloseTime || '8:30 PM';
    return {
      id:               index + 1,
      name:             t.name        && t.name.trim()     !== '' ? t.name        : 'Unknown Temple',
      location:         t.location    && t.location.trim() !== '' ? t.location    : 'Location not set',
      deity:            t.deity       && t.deity.trim()    !== '' ? t.deity       : 'Hindu Deity',
      description:      t.description || '',
      icon:             t.icon        || '🛕',
      distance:         0,
      open_time:        openTime,
      close_time:       closeTime,
      reopen_time:      reopenTime,
      final_close_time: finalCloseTime,
      timing_display:   formatTimings(openTime, closeTime, reopenTime, finalCloseTime),
      festivals:        t.festivals   || [],
      image_url:        t.imageUrl    || '',
      lat:              t.lat         || null,
      lon:              t.lon         || null,
      is_open:          checkOpen(openTime, closeTime, reopenTime, finalCloseTime),
    };
  });
  const fallback = getFallbackTemples();
  return [...dbFormatted, ...fallback];
}

// ─────────────────────────────────────────
// HELPER — sort by distance
// ─────────────────────────────────────────
function applyDistance(temples, userLat, userLon) {
  if (isNaN(userLat) || isNaN(userLon)) return temples;
  return temples
    .map(t => ({
      ...t,
      distance: calculateDistance(userLat, userLon, t.lat, t.lon) ?? 0,
    }))
    .sort((a, b) => a.distance - b.distance);
}

// ─────────────────────────────────────────
// ROUTES
// ─────────────────────────────────────────
router.get('/', async (req, res) => {
  try {
    const userLat = parseFloat(req.query.lat);
    const userLon = parseFloat(req.query.lon);
    let temples = await getAllTemples();
    temples = applyDistance(temples, userLat, userLon);
    res.status(200).json(temples);
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

router.get('/search', async (req, res) => {
  try {
    const query   = (req.query.q || '').toLowerCase().trim();
    const userLat = parseFloat(req.query.lat);
    const userLon = parseFloat(req.query.lon);
    let temples = await getAllTemples();
    temples = applyDistance(temples, userLat, userLon);
    if (!query) return res.status(200).json(temples);
    const results = temples.filter(t =>
      t.name.toLowerCase().includes(query)     ||
      t.location.toLowerCase().includes(query) ||
      t.deity.toLowerCase().includes(query)
    );
    res.status(200).json(results);
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

router.get('/nearby', async (req, res) => {
  try {
    const userLat = parseFloat(req.query.lat);
    const userLon = parseFloat(req.query.lon);
    if (isNaN(userLat) || isNaN(userLon)) {
      return res.status(400).json({ message: 'Valid lat and lon query params are required.' });
    }
    let temples = await getAllTemples();
    temples = applyDistance(temples, userLat, userLon);
    res.status(200).json(temples);
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

router.get('/:id', async (req, res) => {
  try {
    const temples = await getAllTemples();
    const temple  = temples.find(t => t.id === parseInt(req.params.id));
    if (!temple) return res.status(404).json({ message: 'Temple not found' });
    res.status(200).json(temple);
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

module.exports = router;