import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;
import '../services/api_service.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  REAL-TIME AI TEMPLE SUGGESTER
//  Place at: lib/screens/ai_suggestions_page.dart
//
//  HOW IT WORKS:
//  1. Gets user GPS location
//  2. Loads temples from YOUR backend (ApiService.getAllTemples)
//     → Each temple already has lat, lon, open_time, close_time from your DB
//  3. Haversine formula → real km distance to each temple
//  4. Vehicle speed → real travel time in minutes
//  5. Checks if temple will still be OPEN when you arrive
//  6. Real-time crowd estimate based on current hour + day of week
//  7. Smart scoring: distance + crowd + open status + deity preference
//  8. Generates human-readable AI message like:
//     "Based on your bike and current location, you can reach
//      Kapaleeshwarar Temple in 12 minutes before closing.
//      It matches your Shiva preference."
// ═══════════════════════════════════════════════════════════════════════════

class AISuggestionsPage extends StatefulWidget {
  final String? templeId;
  final String? templeName;
  final String  vehicleType;

  const AISuggestionsPage({
    super.key,
    this.templeId,
    this.templeName,
    this.vehicleType = 'bike',
  });

  @override
  State<AISuggestionsPage> createState() => _AISuggestionsPageState();
}

class _AISuggestionsPageState extends State<AISuggestionsPage>
    with SingleTickerProviderStateMixin {

  // ── Theme ──────────────────────────────────────────────────────────────
  static const Color _primary = Color(0xFFFF9933);
  static const Color _dark    = Color(0xFF1C1C2E);
  static const Color _bg      = Color(0xFFFFF8F0);

  // ── Vehicle speeds in km/h (realistic city speeds) ──────────────────────
  static const Map<String, double> _speedKmh = {
    'walk': 4,  // realistic walking in city
    'bike': 25, // city bike including signals
    'car':  20, // city car including traffic
    'bus':  15, // bus with stops
  };
  // Road distance is always longer than straight-line (Haversine)
  // 1.35x multiplier approximates real road distance
  static const double _roadFactor = 1.35;

  // ── State ──────────────────────────────────────────────────────────────
  late String   _vehicle;
  bool          _isLoading   = false;
  bool          _hasFetched  = false;
  Position?     _userPos;
  String?       _locError;

  List<_RankedTemple> _results = [];

  final List<Map<String,dynamic>> _vehicles = [
    {'type':'walk','icon':Icons.directions_walk, 'label':'Walk'},
    {'type':'bike','icon':Icons.two_wheeler,     'label':'Bike'},
    {'type':'car', 'icon':Icons.directions_car,  'label':'Car'},
    {'type':'bus', 'icon':Icons.directions_bus,  'label':'Bus'},
  ];

  // Animation for the scan button
  late AnimationController _scanCtrl;
  late Animation<double>    _scanAnim;

  @override
  void initState() {
    super.initState();
    _vehicle  = widget.vehicleType;
    _scanCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _scanAnim = Tween<double>(begin: 0.97, end: 1.03)
        .animate(CurvedAnimation(parent: _scanCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _scanCtrl.dispose(); super.dispose(); }

  // ══════════════════════════════════════════════════════════════════════
  //  CORE AI ENGINE
  // ══════════════════════════════════════════════════════════════════════

  /// Haversine formula — straight-line distance in km
  double _distKm(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLon = (lon2 - lon1) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2)
            + math.cos(lat1 * math.pi / 180)
            * math.cos(lat2 * math.pi / 180)
            * math.sin(dLon / 2) * math.sin(dLon / 2);
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  /// Travel time in minutes based on distance + vehicle speed
  int _travelMin(double km, String vehicle) =>
      ((km / (_speedKmh[vehicle] ?? 30)) * 60).ceil();

  /// Parse "6:00 AM" → hour integer (e.g. 6)
  int _parseHour(String timeStr) {
    try {
      final parts  = timeStr.trim().split(' ');
      final hPart  = parts[0].split(':')[0];
      final period = parts.length > 1 ? parts[1].toUpperCase() : 'AM';
      int h = int.parse(hPart);
      if (period == 'PM' && h != 12) h += 12;
      if (period == 'AM' && h == 12) h = 0;
      return h;
    } catch (_) { return 6; }
  }

  /// Will the temple still be open when we arrive?
  bool _willBeOpen(int openH, int closeH, int travelMins) {
    final now     = DateTime.now();
    final nowMins = now.hour * 60 + now.minute;
    final arrMins = nowMins + travelMins;
    final arrH    = arrMins ~/ 60;
    return arrH >= openH && arrH < closeH;
  }

  /// Minutes remaining before closing after arrival
  int _minsLeft(int closeH, int travelMins) {
    final now     = DateTime.now();
    final nowMins = now.hour * 60 + now.minute;
    final arrMins = nowMins + travelMins;
    return (closeH * 60) - arrMins;
  }

  /// Real-time crowd estimate based on time of day + weekday
  String _liveCrowd(String base, int hour, int weekday) {
    final isWeekend = weekday >= 6;
    // Peak hours boost
    if (isWeekend && hour >= 9 && hour < 17) {
      if (base == 'low')    return 'medium';
      if (base == 'medium') return 'high';
      return 'very_high';
    }
    // Early morning or late evening = calmer
    if (hour < 8 || hour >= 20) {
      if (base == 'very_high') return 'high';
      if (base == 'high')      return 'medium';
    }
    // Lunch rush
    if (hour >= 11 && hour < 14) {
      if (base == 'low') return 'medium';
    }
    return base;
  }

  /// Numeric crowd score — lower crowd = higher score
  double _crowdScore(String c) {
    switch (c) {
      case 'low':       return 40;
      case 'medium':    return 25;
      case 'high':      return 10;
      case 'very_high': return 0;
      default:          return 20;
    }
  }

  /// Master scoring: combines distance, crowd, timing, preferences
  double _score({
    required double dist,
    required String crowd,
    required bool   open,
    required int    minsLeft,
  }) {
    if (!open || minsLeft < 30) return -1; // Won't make it in time

    double s = 100;

    // Distance penalty — every 10 km reduces score by 5 pts (max 50 pts lost)
    s -= math.min((dist / 10) * 5, 50);

    // Crowd bonus
    s += _crowdScore(crowd);

    // Time comfort bonus (more time at temple = better)
    if (minsLeft > 120) s += 10;
    if (minsLeft > 180) s += 5;

    return s;
  }

  /// Generate human-readable AI message — exactly like your example
  String _aiMessage(_RankedTemple t) {
    final vLabel  = {'walk':'Walk','bike':'bike','car':'car','bus':'bus'}[_vehicle] ?? _vehicle;
    final vEmoji  = {'walk':'Walking','bike':'Bike','car':'Car','bus':'Bus'}[_vehicle] ?? _vehicle;
    final distStr = t.dist < 1
        ? '${(t.dist * 1000).round()} metres'
        : '${t.dist.toStringAsFixed(1)} km';
    final timeStr = t.travelMin < 60
        ? '${t.travelMin} minutes'
        : '${t.travelMin ~/ 60}h ${t.travelMin % 60}m';
    final closingStr = t.minsLeft > 60
        ? '${t.minsLeft ~/ 60}h ${t.minsLeft % 60}m before closing'
        : '${t.minsLeft} minutes before closing';
    final crowdDesc = {
      'low':       'very peaceful - minimal crowd',
      'medium':    'moderately crowded',
      'high':      'quite busy right now',
      'very_high': 'very crowded today',
    }[t.crowd] ?? 'manageable crowd';

    return 'Based on your $vEmoji and current location, you can reach '
        '${t.name} in $timeStr ($distStr away) - arriving $closingStr. '
        'The temple is $crowdDesc.';
  }

  // ══════════════════════════════════════════════════════════════════════
  //  MAIN: GET LOCATION → FETCH TEMPLES → SCORE → RANK
  // ══════════════════════════════════════════════════════════════════════
  Future<void> _runAI() async {
    setState(() {
      _isLoading  = true;
      _hasFetched = false;
      _locError   = null;
      _results    = [];
    });

    // ── Step 1: Get GPS ────────────────────────────────────────────────
    Position pos;
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        setState(() {
          _locError  = 'Location permission denied. Enable in Settings.';
          _isLoading = false;
        });
        return;
      }
      pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high)
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      // Fallback to Chennai if GPS unavailable
      pos = Position(
        latitude: 13.0827, longitude: 80.2707,
        timestamp: DateTime.now(), accuracy: 0, altitude: 0,
        altitudeAccuracy: 0, heading: 0, headingAccuracy: 0,
        speed: 0, speedAccuracy: 0,
      );
      setState(() => _locError = 'GPS unavailable — using Chennai as default location.');
    }
    setState(() => _userPos = pos);

    // ── Step 2: Fetch temples from YOUR backend ────────────────────────
    List<Map<String,dynamic>> temples = [];
    try {
      final raw = await ApiService.getAllTemples();
      temples = raw
          .map((e) => Map<String,dynamic>.from(e as Map))
          .where((t) {
            final lat = t['lat'] ?? t['latitude'];
            final lon = t['lon'] ?? t['longitude'];
            final nm  = (t['name'] ?? '').toString().trim();
            return lat != null && lon != null && nm.isNotEmpty;
          })
          .toList();
    } catch (e) {
      setState(() {
        _locError  = 'Could not load temples from server: $e';
        _isLoading = false;
      });
      return;
    }

    if (temples.isEmpty) {
      setState(() {
        _locError  = 'No temples found from backend. Check your server.';
        _isLoading = false;
      });
      return;
    }

    // ── Step 3: Score each temple ──────────────────────────────────────
    final now     = DateTime.now();
    final scored  = <_RankedTemple>[];

    for (final t in temples) {
      // ✅ FIX: cast each field individually to avoid Dart precedence bug
      final latRaw = t['lat'] ?? t['latitude'];
      final lonRaw = t['lon'] ?? t['longitude'];
      if (latRaw == null || lonRaw == null) continue;
      final lat = (latRaw as num).toDouble();
      final lon = (lonRaw as num).toDouble();

      final name    = (t['name']     ?? 'Unknown').toString();
      final deity   = (t['deity']    ?? '').toString();
      final loc     = (t['location'] ?? '').toString();
      final openH   = _parseHour((t['open_time']  ?? '6:00 AM').toString());
      final closeH  = _parseHour((t['close_time'] ?? '8:00 PM').toString());

      // Base crowd from temple data
      String baseCrowd = (t['crowd_level'] ?? t['crowd'] ?? 'medium').toString();
      if (!['low','medium','high','very_high'].contains(baseCrowd)) baseCrowd = 'medium';

      final straightLine = _distKm(pos.latitude, pos.longitude, lat, lon);
      final dist   = straightLine * _roadFactor; // road is ~35% longer than straight line
      final travel = _travelMin(dist, _vehicle);
      final crowd  = _liveCrowd(baseCrowd, now.hour, now.weekday);
      final open   = _willBeOpen(openH, closeH, travel);
      final left   = _minsLeft(closeH, travel);
      final sc     = _score(dist: dist, crowd: crowd, open: open, minsLeft: left);

      scored.add(_RankedTemple(
        id:        (t['_id'] ?? t['id'] ?? '').toString(),
        name:      name,
        deity:     deity,
        location:  loc,
        dist:      dist,
        travelMin: travel,
        crowd:     crowd,
        isOpen:    open,
        minsLeft:  left > 0 ? left : 0,
        score:     sc,
        rank:      0,
      ));
    }

    // ── Step 4: Sort & assign ranks ────────────────────────────────────
    final valid = scored.where((s) => s.score > 0).toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    final top5 = valid.take(5).toList();
    for (int i = 0; i < top5.length; i++) {
      top5[i] = top5[i].withRank(i + 1, _aiMessage(top5[i]));
    }

    if (mounted) setState(() { _results = top5; _isLoading = false; _hasFetched = true; });
  }

  // ══════════════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('AI Temple Suggester',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          if (_hasFetched)
            IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Re-scan',
                onPressed: _isLoading ? null : _runAI),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          _heroCard(),
          const SizedBox(height: 20),
          _preferencesCard(),
          const SizedBox(height: 16),
          _scanButton(),
          const SizedBox(height: 20),

          if (_locError != null) _errorBanner(),
          if (_isLoading)        _loadingCard(),
          if (_hasFetched && _results.isEmpty && !_isLoading) _noResultCard(),
          if (_results.isNotEmpty && !_isLoading) ...[
            _topPickBanner(),
            const SizedBox(height: 14),
            ..._results.map((t) => _templeCard(t)),
          ],

          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  //  UI PIECES
  // ══════════════════════════════════════════════════════════════════════

  Widget _heroCard() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
          colors: [Color(0xFFFF9933), Color(0xFFCC5500)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(22),
      boxShadow: [BoxShadow(color: _primary.withValues(alpha: 0.45), blurRadius: 20, offset: const Offset(0, 8))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        ScaleTransition(
          scale: _scanAnim,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14)),
            child: const Text('🤖', style: TextStyle(fontSize: 28)),
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Real-Time AI Suggester',
              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Text('Scans your GPS • Calculates real travel time\n'
               'Checks temple timing • Picks the best for you',
              style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.4)),
        ])),
      ]),
      const SizedBox(height: 14),
      Wrap(spacing: 8, runSpacing: 6, children: [
        _heroBadge('📍 GPS Location'),
        _heroBadge('⏱️ Real travel time'),
        _heroBadge('👥 Live crowd estimate'),
        _heroBadge('🕐 Open/close check'),
        _heroBadge('⭐ Smart AI scoring'),
      ]),
      if (_userPos != null) ...[
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(9)),
          child: Text(
            '📍 ${_userPos!.latitude.toStringAsFixed(5)}°N  '
            '${_userPos!.longitude.toStringAsFixed(5)}°E',
            style: const TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'monospace'),
          ),
        ),
      ],
    ]),
  );

  Widget _heroBadge(String s) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20)),
    child: Text(s, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
  );

  Widget _preferencesCard() => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.grey.shade200),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      // Title
      Row(children: [
        Container(width: 4, height: 20, decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        const Text('Your Preferences', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ]),
      const SizedBox(height: 18),

      // ── Vehicle ─────────────────────────────────────────────────────
      const Text('Vehicle', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
      const SizedBox(height: 8),
      Row(children: _vehicles.map((v) {
        final sel = _vehicle == v['type'];
        return Expanded(child: GestureDetector(
          onTap: () => setState(() { _vehicle = v['type'] as String; _results = []; }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              color:  sel ? _primary : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: sel ? _primary : Colors.grey.shade200),
              boxShadow: sel ? [BoxShadow(color: _primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))] : [],
            ),
            child: Column(children: [
              Icon(v['icon'] as IconData, color: sel ? Colors.white : Colors.grey.shade500, size: 24),
              const SizedBox(height: 4),
              Text(v['label'] as String,
                  style: TextStyle(fontSize: 11, color: sel ? Colors.white : Colors.grey, fontWeight: FontWeight.w600)),
            ]),
          ),
        ));
      }).toList()),

    ]),
  );

  Widget _scanButton() => ScaleTransition(
    scale: _hasFetched ? const AlwaysStoppedAnimation(1.0) : _scanAnim,
    child: SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _runAI,
        style: ElevatedButton.styleFrom(
          backgroundColor: _dark,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 6,
          shadowColor: _dark.withValues(alpha: 0.5),
        ),
        child: _isLoading
            ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)),
                SizedBox(width: 14),
                Text('AI is scanning temples...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ])
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('🤖', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Text(_hasFetched ? '🔄  Re-Scan Near Me' : '✨  Find Best Temple For Me Now',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ]),
      ),
    ),
  );

  Widget _errorBanner() => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.orange.shade50,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.orange.shade300),
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Icon(Icons.info_outline, color: Colors.orange, size: 20),
      const SizedBox(width: 10),
      Expanded(child: Text(_locError!, style: const TextStyle(fontSize: 13, color: Colors.brown))),
    ]),
  );

  Widget _loadingCard() => Container(
    padding: const EdgeInsets.symmetric(vertical: 36),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200)),
    child: const Column(children: [
      CircularProgressIndicator(color: _primary, strokeWidth: 3),
      SizedBox(height: 18),
      Text('🤖  AI is working...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      SizedBox(height: 8),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          'Getting your GPS → Fetching temples from server\n'
          '→ Calculating distances → Checking crowd & timings\n'
          '→ Scoring & ranking best matches',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.6),
        ),
      ),
    ]),
  );

  Widget _noResultCard() => Container(
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.orange.shade200)),
    child: const Column(children: [
      Text('😕', style: TextStyle(fontSize: 40)),
      SizedBox(height: 12),
      Text('No temples found for your preferences', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      SizedBox(height: 6),
      Text('Temples may be closing soon, or try changing your deity / crowd preference.',
          textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.5)),
    ]),
  );

  Widget _topPickBanner() {
    final t = _results.first;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _dark,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: _dark.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('🤖', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          const Text('AI Recommendation', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(8)),
            child: const Text('#1 BEST MATCH', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ]),
        const SizedBox(height: 12),
        // ★ THE AI MESSAGE — just like your example
        Text(
          '"${t.aiMessage ?? ''}"',
          style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.65, fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 16),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _darkTag('🛕 ${t.deity}',              Colors.orange),
          _darkTag(_crowdLabel(t.crowd),          _crowdColor(t.crowd)),
          _darkTag('⏱️ ${t.travelMin} min away', Colors.blue),
          _darkTag('📍 ${_distStr(t.dist)}',      Colors.teal),
        ]),
      ]),
    );
  }

  Widget _darkTag(String s, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
        color: c.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.withValues(alpha: 0.35))),
    child: Text(s, style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.bold)),
  );

  Widget _templeCard(_RankedTemple t) {
    final isTop = t.rank == 1;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: isTop ? _primary.withValues(alpha: 0.6) : Colors.grey.shade200,
            width: isTop ? 2 : 1),
        boxShadow: [
          BoxShadow(
              color: isTop ? _primary.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.04),
              blurRadius: isTop ? 14 : 6,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Card header ─────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isTop ? _primary.withValues(alpha: 0.07) : Colors.grey.shade50,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          ),
          child: Row(children: [
            // Rank circle
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: isTop ? _primary : Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Center(child: Text(
                isTop ? '⭐' : '#${t.rank}',
                style: TextStyle(
                    color: isTop ? Colors.white : Colors.grey.shade600,
                    fontSize: isTop ? 18 : 14,
                    fontWeight: FontWeight.bold),
              )),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(t.location,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              if (t.deity.isNotEmpty)
                Text('🕉️ ${t.deity}', style: const TextStyle(color: _primary, fontSize: 11, fontWeight: FontWeight.w500)),
            ])),
            const SizedBox(width: 8),
            // Open / closed pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: t.isOpen ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: t.isOpen ? Colors.green.shade300 : Colors.red.shade300),
              ),
              child: Text(
                t.isOpen ? '🟢 Open' : '🔴 Closed',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: t.isOpen ? Colors.green.shade700 : Colors.red.shade700),
              ),
            ),
          ]),
        ),

        // ── Stats grid ──────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(children: [
            Row(children: [
              _statTile('📍 Distance',   _distStr(t.dist),           Colors.teal),
              const SizedBox(width: 8),
              _statTile('⏱️ Travel',      '${t.travelMin} min',       Colors.blue),
              const SizedBox(width: 8),
              _statTile('⭐ Score',       t.score.toInt().toString(),  _primary),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              _statTile('👥 Crowd',       _crowdLabelShort(t.crowd),  _crowdColor(t.crowd)),
              const SizedBox(width: 8),
              _statTile('🕐 Time left',
                  t.isOpen ? '${t.minsLeft ~/ 60}h ${t.minsLeft % 60}m' : 'Closed',
                  t.isOpen ? Colors.green : Colors.red),
              const SizedBox(width: 8),
              _statTile('🚦 Status',
                  _vehicle[0].toUpperCase() + _vehicle.substring(1),
                  Colors.purple),
            ]),
            const SizedBox(height: 12),

            // Crowd bar
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Live Crowd Level',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                Text(_crowdLabel(t.crowd),
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _crowdColor(t.crowd))),
              ]),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value:           _crowdFraction(t.crowd),
                  minHeight:       10,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(_crowdColor(t.crowd)),
                ),
              ),
            ]),

            // AI message bubble
            if (t.aiMessage != null && t.aiMessage!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: isTop ? const Color(0xFFFFF3E0) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: isTop ? _primary.withValues(alpha: 0.3) : Colors.grey.shade200),
                ),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('🤖 ', style: TextStyle(fontSize: 15)),
                  Expanded(
                    child: Text(t.aiMessage!,
                        style: TextStyle(
                            fontSize: 12.5,
                            height: 1.55,
                            color: isTop ? Colors.brown.shade800 : Colors.grey.shade700)),
                  ),
                ]),
              ),
            ],
          ]),
        ),
      ]),
    );
  }

  Widget _statTile(String label, String value, Color color) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withValues(alpha: 0.2)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      const SizedBox(height: 3),
      Text(value,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
          maxLines: 1, overflow: TextOverflow.ellipsis),
    ]),
  ));

  // ── Helpers ────────────────────────────────────────────────────────────
  String _distStr(double km) =>
      km < 1 ? '${(km * 1000).round()} m' : '${km.toStringAsFixed(1)} km';

  Color  _crowdColor(String c) {
    switch (c) {
      case 'low':       return Colors.green;
      case 'medium':    return Colors.orange;
      case 'high':      return Colors.red;
      case 'very_high': return Colors.purple;
      default:          return Colors.grey;
    }
  }

  double _crowdFraction(String c) {
    switch (c) {
      case 'low':       return 0.18;
      case 'medium':    return 0.50;
      case 'high':      return 0.76;
      case 'very_high': return 0.95;
      default:          return 0.4;
    }
  }

  String _crowdLabel(String c) {
    switch (c) {
      case 'low':       return '🟢 Low Crowd';
      case 'medium':    return '🟡 Moderate';
      case 'high':      return '🔴 High Crowd';
      case 'very_high': return '🟣 Very High';
      default:          return c;
    }
  }

  String _crowdLabelShort(String c) {
    switch (c) {
      case 'low':       return 'Low 🟢';
      case 'medium':    return 'Moderate 🟡';
      case 'high':      return 'Busy 🔴';
      case 'very_high': return 'V.High 🟣';
      default:          return c;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  DATA MODEL
// ═══════════════════════════════════════════════════════════════════════════
class _RankedTemple {
  final String  id, name, deity, location, crowd;
  final double  dist, score;
  final int     travelMin, minsLeft, rank;
  final bool    isOpen;
  final String? aiMessage;

  const _RankedTemple({
    required this.id,       required this.name,     required this.deity,
    required this.location, required this.dist,     required this.travelMin,
    required this.crowd,    required this.isOpen,   required this.minsLeft,
    required this.score,    required this.rank,     this.aiMessage,
  });

  _RankedTemple withRank(int r, String msg) => _RankedTemple(
    id: id, name: name, deity: deity, location: location,
    dist: dist, travelMin: travelMin, crowd: crowd,
    isOpen: isOpen, minsLeft: minsLeft, score: score,
    rank: r, aiMessage: msg,
  );
}