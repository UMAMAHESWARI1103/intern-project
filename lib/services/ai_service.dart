// Place at: lib/services/ai_service.dart

import 'package:geolocator/geolocator.dart';
import '../models/temple_suggestion.dart';
import 'crowd_service.dart';
import 'route_service.dart';

class AIService {
  final CrowdService _crowdService = CrowdService();
  final RouteService _routeService = RouteService();

  // ──────────────────────────────────────────────────────────────────────────
  // 1. VISIT PLAN  (crowd + route)
  // ──────────────────────────────────────────────────────────────────────────
  Future<TempleSuggestion> getSuggestion({
    required String templeId,
    required String vehicleType,
  }) async {
    // ── Get user location ─────────────────────────────────────────────────
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission denied. Enable it in Settings.');
    }

    Position position;
    try {
      position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high)
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      // Fallback to a default position (Chennai) when GPS unavailable
      position = Position(
        latitude: 13.0827,
        longitude: 80.2707,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
    }

    final now = DateTime.now();

    // ── Route ─────────────────────────────────────────────────────────────
    final route = await _routeService.checkAccessibility(
      userLocation: position,
      templeId:     templeId,
      vehicleType:  vehicleType,
    );

    // ── Crowd ─────────────────────────────────────────────────────────────
    final crowdData   = await _crowdService.predictCrowd(templeId, now);
    final crowdLevel  = crowdData['level']      as String;
    final crowdPercent= crowdData['percent']    as int;
    final isFestival  = crowdData['is_festival'] as bool;

    // ── Decision ──────────────────────────────────────────────────────────
    final canReach    = route['can_reach']    as bool;
    final goDecision  = _crowdService.getGoDecision(crowdLevel, canReach);
    final bestTime    = _crowdService.getBestTime(crowdLevel, now);

    final recommendation = _buildRecommendation(
      goDecision:  goDecision,
      crowdLevel:  crowdLevel,
      canReach:    canReach,
      isFestival:  isFestival,
      vehicle:     vehicleType,
      duration:    route['estimated_duration'] as String,
      distance:    route['distance_km']        as String,
    );

    return TempleSuggestion(
      canReach:          canReach,
      crowdLevel:        crowdLevel,
      crowdPercent:      crowdPercent,
      bestTimeToVisit:   bestTime,
      estimatedDuration: route['estimated_duration'] as String,
      distanceKm:        route['distance_km']        as String,
      warnings:          List<String>.from(route['warnings'] as List),
      recommendation:    recommendation,
      goDecision:        goDecision,
    );
  }

  String _buildRecommendation({
    required String goDecision,
    required String crowdLevel,
    required bool   canReach,
    required bool   isFestival,
    required String vehicle,
    required String duration,
    required String distance,
  }) {
    if (!canReach) {
      return '🚫 Your $vehicle may not be suitable for this temple. '
          'Check the warnings below.';
    }
    final travel = 'Travel: ~$distance km (~$duration by $vehicle).';
    switch (goDecision) {
      case 'go':
        return crowdLevel == 'low'
            ? '✅ Great time to visit! Very low crowd expected. $travel Peaceful darshan ahead.'
            : '✅ Good time to visit! Moderate crowd. $travel Plan to arrive a bit early.';
      case 'wait':
        return '⏳ High crowd right now. Try early morning (6–8 AM) or evening (7–8 PM). $travel';
      case 'avoid':
        return isFestival
            ? '🎉 Festival season! Extremely heavy crowd expected. Visit after the festival. $travel'
            : '🚫 Very high crowd. Avoid now. Best on a weekday morning. $travel';
      default:
        return '$travel Check crowd details below.';
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 2. BEST TIME WEEKLY SCHEDULE
  // ──────────────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getBestTimeAnalysis(String templeId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return {
      'schedule': [
        {'day': 'Monday',    'morning': 'Low 🟢',       'afternoon': 'Medium 🟡', 'evening': 'Medium 🟡'},
        {'day': 'Tuesday',   'morning': 'Low 🟢',       'afternoon': 'Low 🟢',   'evening': 'Medium 🟡'},
        {'day': 'Wednesday', 'morning': 'Low 🟢',       'afternoon': 'Medium 🟡', 'evening': 'High 🔴'},
        {'day': 'Thursday',  'morning': 'Medium 🟡',    'afternoon': 'High 🔴',   'evening': 'High 🔴'},
        {'day': 'Friday',    'morning': 'Low 🟢',       'afternoon': 'Medium 🟡', 'evening': 'Very High 🟣'},
        {'day': 'Saturday',  'morning': 'High 🔴',      'afternoon': 'Very High 🟣', 'evening': 'Very High 🟣'},
        {'day': 'Sunday',    'morning': 'Very High 🟣', 'afternoon': 'Very High 🟣', 'evening': 'High 🔴'},
      ],
      'tip': '🌅 Best overall: Tuesday morning 6–8 AM — lowest crowd all week.\n\n'
          '📅 Avoid weekends, especially Saturday & Sunday afternoons.\n\n'
          '⭐ Friday evening is popular for special poojas — expect high footfall.\n\n'
          '💡 Pro tip: Arrive 30 min before opening for a truly peaceful darshan.',
    };
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 3. MOOD-BASED SPIRITUAL SUGGESTION
  // ──────────────────────────────────────────────────────────────────────────
  Map<String, dynamic> getMoodSuggestion(String mood) {
    final data = {
      'Stressed': {
        'deity':   'Lord Shiva',
        'temple':  'Chidambaram Nataraja / Kapaleeshwarar Temple',
        'pooja':   'Abhishekam & Rudra Puja',
        'mantra':  '"Om Namah Shivaya" — chant 108 times.',
        'advice':  '🕊️ Lord Shiva destroys negativity. Offer bilva leaves and water. The cosmic dance of Nataraja reminds us — all struggles are temporary.',
        'color':   'red',
        'icon':    'self_improvement',
      },
      'Career Focus': {
        'deity':   'Goddess Saraswati',
        'temple':  'Gnana Saraswati Temple, Basar / Koothanur Saraswati Temple',
        'pooja':   'Saraswati Puja & Vidyarambham',
        'mantra':  '"Ya Devi Sarva Bhuteshu Vidya-Rupena Samsthita" — for knowledge clarity.',
        'advice':  '📚 Goddess Saraswati blesses with wisdom. Offer white flowers & coconut. Best day: Wednesday.',
        'color':   'blue',
        'icon':    'school',
      },
      'Financial Help': {
        'deity':   'Goddess Lakshmi',
        'temple':  'Mahalakshmi Temple, Kolhapur / Padmavathi Temple, Tiruchanur',
        'pooja':   'Lakshmi Puja & Sri Sukta Homam',
        'mantra':  '"Om Shreem Mahalakshmiyei Namaha" — daily chant for prosperity.',
        'advice':  '💛 Offer lotus flowers, turmeric & kumkum. Keep your home clean — Lakshmi resides where there is purity. Best day: Friday evening.',
        'color':   'green',
        'icon':    'account_balance',
      },
      'Peaceful': {
        'deity':   'Lord Vishnu / Krishna',
        'temple':  'Srirangam Ranganathaswamy / ISKCON Temple',
        'pooja':   'Vishnu Sahasranama Parayanam',
        'mantra':  '"Om Namo Narayanaya" — surrender and peace.',
        'advice':  '🌸 Lord Vishnu is the cosmic sustainer. Offer tulsi leaves, sit quietly in the hall for 15–20 min. Best time: Early morning before 8 AM.',
        'color':   'teal',
        'icon':    'spa',
      },
      'Health Problems': {
        'deity':   'Lord Dhanvantari / Vaitheeswaran',
        'temple':  'Vaitheeswaran Temple, Tamil Nadu / Dhanvantari Temple, Thrissur',
        'pooja':   'Dhanvantari Homam & Mrityunjaya Jaap',
        'mantra':  '"Om Tryambakam Yajamahe, Sugandhim Pushtivardhanam, Urvarukamiva Bandhanan, Mrityor Mukshiya Mamritat." — Mahamrityunjaya Mantra.',
        'advice':  '🌿 Vaitheeswaran Temple is uniquely dedicated to healing. Offer neem leaves & sesame. Many devotees report miraculous recoveries here.',
        'color':   'orange',
        'icon':    'favorite',
      },
      'Love & Marriage': {
        'deity':   'Goddess Parvati / Meenakshi Amman',
        'temple':  'Meenakshi Amman Temple, Madurai / Kaamakshi Temple, Kanchipuram',
        'pooja':   'Swayamvara Parvathi Homam & Kanya Puja',
        'mantra':  '"Om Hreem Katyayinyai Namaha" — especially for finding a life partner.',
        'advice':  '💑 Offer red flowers, turmeric and kumkum. Kanchipuram Kaamakshi Devi is famous across South India for fulfilling marriage wishes. Best day: Friday.',
        'color':   'pink',
        'icon':    'favorite_border',
      },
    };
    return data[mood] ?? {};
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 4. FESTIVAL ALERTS
  // ──────────────────────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getFestivalAlerts(
      {String? templeId}) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return [
      {
        'name':    'Panguni Uthiram',
        'date':    'March 26, 2026',
        'deity':   'Murugan & Shiva',
        'desc':    'Auspicious day for celestial weddings. Tiruchendur & Palani temples will have massive gatherings. Arrive before 5 AM for darshan.',
        'crowd':   'Very High 🟣',
        'temples': 'Tiruchendur, Palani, Swamimalai',
        'color':   'purple',
      },
      {
        'name':    'Tamil New Year (Puthandu)',
        'date':    'April 14, 2026',
        'deity':   'All Deities',
        'desc':    'Tamil New Year — all major temples packed. Special poojas throughout the day. Book darshan tickets in advance.',
        'crowd':   'Very High 🟣',
        'temples': 'All major temples across Tamil Nadu',
        'color':   'orange',
      },
      {
        'name':    'Akshaya Tritiya',
        'date':    'April 28, 2026',
        'deity':   'Goddess Lakshmi',
        'desc':    'Highly auspicious for prosperity. Lakshmi and Vishnu temples will see high crowd in the morning hours.',
        'crowd':   'High 🔴',
        'temples': 'Tirupati, Srirangam, Padmavathi Temple',
        'color':   'green',
      },
      {
        'name':    'Vaikasi Visakam',
        'date':    'May 22, 2026',
        'deity':   'Lord Murugan',
        'desc':    'Birthday of Lord Murugan — all 6 Arupadai Veedu temples celebrate grandly. Palani will see 1 lakh+ devotees.',
        'crowd':   'Very High 🟣',
        'temples': '6 Arupadai Veedu temples',
        'color':   'deepOrange',
      },
      {
        'name':    'Adi Amavasai',
        'date':    'July 2026 (varies)',
        'deity':   'Ancestors (Pitru)',
        'desc':    'Sacred day for ancestor rituals. Rameswaram and Kasi Viswanath see significant crowds for tarpanam.',
        'crowd':   'High 🔴',
        'temples': 'Rameswaram, Varanasi, Gaya',
        'color':   'indigo',
      },
      {
        'name':    'Karthigai Deepam',
        'date':    'November 2026 (varies)',
        'deity':   'Lord Shiva (Annamalai)',
        'desc':    'Sea of lamps — Tiruvannamalai Arunachaleswarar Temple lights the giant beacon on the hill. Millions attend the Girivalam walk.',
        'crowd':   'Very High 🟣',
        'temples': 'Tiruvannamalai (most significant)',
        'color':   'red',
      },
    ];
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 5. PRAYER RECOMMENDATION
  // ──────────────────────────────────────────────────────────────────────────
  Map<String, dynamic> getPrayerRecommendation(String goal) {
    final data = {
      'Exam / Education': {
        'deity':   'Goddess Saraswati',
        'temple':  'Saraswati Temple, Koothanur (Tamil Nadu) — most famous for exam prayers',
        'prayer':  'Saraswati Vandana & Hayagriva Stotram',
        'mantra':  '"Saraswati Namasthubhyam, Varade Kaamaroopini.\nVidyaarambham Karishyaami, Siddhir Bhavatu Me Sadaa."',
        'ritual':  '📚 Offer white flowers and books to Saraswati. Light a ghee lamp. Keep your textbooks near the idol overnight (Ayudha Puja style). Best day: Wednesday.',
        'advice':  '🌟 Divine blessings multiply hard work. Even a single visit to Koothanur temple is said to bless students with clarity of mind.',
        'color':   'blue',
        'icon':    'school',
      },
      'Job / Career': {
        'deity':   'Lord Venkateswara (Balaji)',
        'temple':  'Tirumala Tirupati, Andhra Pradesh — most powerful for career blessings',
        'prayer':  'Venkateswara Suprabhatam & Vishnu Sahasranamam',
        'mantra':  '"Om Namo Venkatesaya Namaha" — chant 108 times daily.',
        'ritual':  '💼 Offer the famous Ladoo prasadam. Perform hair tonsuring (Mottai) as a fulfillment vow when you get your job. Light sesame oil lamp on Saturdays.',
        'advice':  '🙏 Make a vow (Mannat) at Tirumala — when fulfilled, return to thank the Lord. Millions have experienced career breakthroughs through this sacred vow.',
        'color':   'indigo',
        'icon':    'work',
      },
      'Business Success': {
        'deity':   'Lord Ganesha + Goddess Lakshmi',
        'temple':  'Rockfort Ucchi Pillayar Temple, Trichy / Mahalakshmi Temple, Kolhapur',
        'prayer':  'Ganesha Atharvashirsha & Lakshmi Ashtakam',
        'mantra':  '"Om Gam Ganapataye Namaha" — before any business decision.',
        'ritual':  '💛 Light a golden oil lamp for Lakshmi every Friday. Offer modak to Ganesha every Wednesday. Keep a Ganesha idol at your business entrance.',
        'advice':  '📈 Ganesha removes business obstacles. Always seek His blessing before signing contracts or launching new ventures.',
        'color':   'green',
        'icon':    'trending_up',
      },
      'Health & Healing': {
        'deity':   'Lord Dhanvantari + Vaitheeswaran',
        'temple':  'Vaitheeswaran Temple, Tamil Nadu / Dhanvantari Temple, Thrissur',
        'prayer':  'Mahamrityunjaya Mantra & Dhanvantari Stotram',
        'mantra':  '"Om Tryambakam Yajamahe, Sugandhim Pushtivardhanam,\nUrvarukamiva Bandhanan, Mrityor Mukshiya Mamritat."',
        'ritual':  '🌿 Offer neem leaves, bilva and sesame. Pour water abhishekam daily. Tuesdays & Sundays are best at Vaitheeswaran Temple.',
        'advice':  '💊 Vaitheeswaran = Divine Physician. The temple tank water is believed to have healing properties. Many devotees report miraculous recoveries.',
        'color':   'orange',
        'icon':    'favorite',
      },
      'Marriage Blessing': {
        'deity':   'Goddess Parvati / Meenakshi Amman',
        'temple':  'Meenakshi Amman Temple, Madurai / Kaamakshi Temple, Kanchipuram',
        'prayer':  'Swayamvara Parvathi Homam & Katyayani Puja',
        'mantra':  '"Om Hreem Katyayinyai Namaha" — chant for finding a suitable life partner.',
        'ritual':  '💑 Offer red flowers, turmeric and kumkum. Performing Swayamvara Parvathi Homam removes marriage obstacles. Visit on Fridays.',
        'advice':  '🌸 Kanchipuram Kaamakshi is known across South India for fulfilling marriage wishes. Approach with pure heart and clear intention.',
        'color':   'pink',
        'icon':    'favorite_border',
      },
      'Child Blessing': {
        'deity':   'Lord Murugan + Santana Krishna',
        'temple':  'Pazhamudircholai Murugan Temple / Santana Krishna Temple',
        'prayer':  'Santana Gopala Mantra & Murugan Kavacham',
        'mantra':  '"Om Devaki Sudha Govinda Vasudeva Jagatpate,\nDehi Me Tanayam Krishna Tvam Aham Sharanam Gatah."',
        'ritual':  '👶 Offer bananas and coconut to Lord Murugan. Seek the Lord\'s blessing through Vel puja. Visit on Skanda Shashti for maximum blessings.',
        'advice':  '🙏 Many families have been blessed with children after sincere prayers. Lord Murugan — always child-like and compassionate — readily responds to heartfelt requests.',
        'color':   'teal',
        'icon':    'child_care',
      },
      'Travel Safety': {
        'deity':   'Lord Hanuman',
        'temple':  'Hanuman Temple, Salasar / Maruthi Temple (local)',
        'prayer':  'Hanuman Chalisa & Bajrang Baan',
        'mantra':  '"Om Anjaneyaya Vidmahe, Vayuputraya Dhimahi,\nTanno Hanumat Prachodayat."',
        'ritual':  '✈️ Recite Hanuman Chalisa before any long journey. Offer orange flowers and sesame laddoos. Tuesdays & Saturdays are especially auspicious.',
        'advice':  '🚗 Keep a small Hanuman image in your vehicle. Lord Hanuman is the embodiment of fearlessness — His blessing ensures safe travel.',
        'color':   'cyan',
        'icon':    'flight',
      },
      'Home Blessing': {
        'deity':   'Lord Ganesha / Vastu Purusha',
        'temple':  'Pillayarpatti Ganesha Temple / Local Ganesha Temple',
        'prayer':  'Vastu Shanti Puja & Ganesha Homam',
        'mantra':  '"Om Gam Ganapataye Namaha" — perform at home entry.',
        'ritual':  '🏠 Perform Griha Pravesh puja before entering a new home. Light lamps at four corners on Diwali. Place Swastika symbol at the main doorway.',
        'advice':  '✨ A home blessed by Ganesha is free of obstacles and filled with prosperity. The idol at the entrance removes negative energy.',
        'color':   'brown',
        'icon':    'home',
      },
      'Inner Peace': {
        'deity':   'Lord Vishnu',
        'temple':  'Srirangam Ranganathaswamy Temple / Belur Chennakesava Temple',
        'prayer':  'Vishnu Sahasranamam & Dhyana (Meditation)',
        'mantra':  '"Om Namo Narayanaya" — the 8-syllable mantra for complete surrender and peace.',
        'ritual':  '☮️ Sit quietly in the temple hall for 20–30 minutes. Offer tulsi leaves. Practice slow conscious breathing while chanting. Best: Before 8 AM.',
        'advice':  '🌊 True peace comes when we surrender worries to the divine. In Lord Vishnu\'s presence all anxieties dissolve. Make temple visits a regular — not just occasional — practice.',
        'color':   'purple',
        'icon':    'self_improvement',
      },
    };
    return data[goal] ?? {};
  }
}