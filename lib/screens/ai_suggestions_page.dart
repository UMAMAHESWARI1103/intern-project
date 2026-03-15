// lib/screens/ai_suggestions_page.dart
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AiSuggestionsPage extends StatefulWidget {
  const AiSuggestionsPage({super.key});
  @override
  State<AiSuggestionsPage> createState() => _AiSuggestionsPageState();
}

class _AiSuggestionsPageState extends State<AiSuggestionsPage>
    with SingleTickerProviderStateMixin {

  static const Color _orange = Color(0xFFFF9933);
  static const Color _dark   = Color(0xFF1C1C2E);
  static const Color _bg     = Color(0xFFF8F4EF);
  static const Color _purple = Color(0xFF7C3AED);

  late TabController _tabCtrl;

  // TAB 1
  String  _vehicle      = 'bike';
  bool    _gpsLoading   = false;
  bool    _gpsDone      = false;
  String? _gpsError;
  List<_TempleResult> _nearbyList   = [];
  List<_TempleResult> _goodTimeList = [];

  static const Map<String, double>   _speedKmh     = {'walk': 4, 'bike': 25, 'car': 20, 'bus': 15};
  static const Map<String, String>   _vehicleLabel = {'walk': 'Walking', 'bike': 'Bike', 'car': 'Car', 'bus': 'Bus'};
  static const Map<String, IconData> _vehicleIcon  = {
    'walk': Icons.directions_walk, 'bike': Icons.two_wheeler,
    'car': Icons.directions_car,   'bus': Icons.directions_bus,
  };

  // TAB 2
  bool    _mlLoading  = true;
  String? _mlError;
  List<Map<String, dynamic>> _forYouList  = [];
  List<Map<String, dynamic>> _popularList = [];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadML();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  // ── GPS ──────────────────────────────────────────────────────────
  Future<void> _runGPS() async {
    setState(() {
      _gpsLoading = true;
      _gpsError   = null;
      _nearbyList   = [];
      _goodTimeList = [];
    });

    Position pos;
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
          .timeout(const Duration(seconds: 8));
    } catch (_) {
      pos = Position(
        latitude: 13.0827, longitude: 80.2707, timestamp: DateTime.now(),
        accuracy: 0, altitude: 0, altitudeAccuracy: 0,
        heading: 0, headingAccuracy: 0, speed: 0, speedAccuracy: 0,
      );
      if (mounted) {
        setState(() {
          _gpsError = 'GPS unavailable — using Chennai as default.';
        });
      }
    }

    List<Map<String, dynamic>> temples = [];
    try {
      final raw = await ApiService.getAllTemples();
      temples = raw
          .map((e) => Map<String, dynamic>.from(e as Map))
          .where((t) =>
              (t['lat'] ?? t['latitude'])  != null &&
              (t['lon'] ?? t['longitude']) != null)
          .toList();
    } catch (_) {
      if (mounted) {
        setState(() {
          _gpsError   = 'Could not load temples.';
          _gpsLoading = false;
        });
      }
      return;
    }

    final now     = DateTime.now();
    final results = <_TempleResult>[];

    for (final t in temples) {
      final lat  = ((t['lat']  ?? t['latitude'])  as num).toDouble();
      final lon  = ((t['lon']  ?? t['longitude']) as num).toDouble();
      final dist = _haversine(pos.latitude, pos.longitude, lat, lon) * 1.35;
      final tr   = ((dist / (_speedKmh[_vehicle] ?? 25)) * 60).ceil();
      final openH  = _parseHour((t['open_time']       ?? '6:00 AM').toString());
      final closeH = _parseHour((t['close_time']       ?? '1:00 PM').toString());
      final repH   = _parseHour((t['reopen_time']      ?? '4:00 PM').toString());
      final finH   = _parseHour((t['final_close_time'] ?? '8:30 PM').toString());
      final session = _checkSession(openH, closeH, repH, finH, tr, now);
      final crowd   = _guessCrowd(now.hour, now.weekday);
      results.add(_TempleResult(
        name:      (t['name']     ?? 'Temple').toString(),
        location:  (t['location'] ?? '').toString(),
        deity:     (t['deity']    ?? '').toString(),
        dist:      dist,
        travelMin: tr,
        crowd:     crowd,
        isOpen:    session.isOpen,
        session:   session.label,
        minsLeft:  session.minsLeft,
        score:     _score(dist, crowd, session.isOpen, session.minsLeft),
      ));
    }

    final byDist  = List<_TempleResult>.from(results)..sort((a, b) => a.dist.compareTo(b.dist));
    final byScore = List<_TempleResult>.from(results)..sort((a, b) => b.score.compareTo(a.score));
    final goodTime = byScore.where((r) => r.isOpen && r.crowd != 'very_high').take(6).toList();

    if (mounted) {
      setState(() {
        _nearbyList   = byDist.take(6).toList();
        _goodTimeList = goodTime.isEmpty ? byDist.take(4).toList() : goodTime;
        _gpsLoading   = false;
        _gpsDone      = true;
      });
    }
  }

  // ── ML ───────────────────────────────────────────────────────────
  Future<void> _loadML() async {
    setState(() {
      _mlLoading = true;
      _mlError   = null;
    });
    try {
      String email = '';
      final token = await ApiService.loadToken();

      // STEP 1: Decode email from JWT token
      if (token != null) {
        try {
          final parts = token.split('.');
          if (parts.length == 3) {
            final payload = utf8.decode(
              base64Url.decode(base64Url.normalize(parts[1])),
            );
            final map = jsonDecode(payload) as Map<String, dynamic>;
            email = (map['email'] ?? map['userEmail'] ?? '').toString();
          }
        } catch (_) {}
      }

      // STEP 2: SharedPreferences fallback
      if (email.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        email = prefs.getString('userEmail') ??
                prefs.getString('email')     ??
                prefs.getString('user_email') ?? '';
      }

      // STEP 3: Profile API fallback
      if (email.isEmpty) {
        final profile = await ApiService.getUserProfile();
        if (profile != null) {
          email = (profile['email']          ??
                   profile['userEmail']      ??
                   profile['user']?['email'] ??
                   profile['data']?['email'] ?? '').toString();
        }
      }

      if (email.isEmpty) {
        if (mounted) {
          setState(() {
            _mlLoading = false;
            _mlError   = 'Login to get personalised recommendations.';
          });
        }
        return;
      }

      final uri = Uri.parse(
        '${ApiService.baseUrl}/ml-recommendations/${Uri.encodeComponent(email)}',
      );
      final res = await http.get(uri, headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      }).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final forYouRaw = (data['forYou'] as List? ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          final popularRaw = (data['popular'] as List? ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();

          if (forYouRaw.isEmpty && popularRaw.isEmpty) {
            final temples = (data['temples'] as List? ?? [])
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();
            if (mounted) {
              setState(() {
                _popularList = temples.take(8).toList();
                _mlLoading   = false;
              });
            }
            return;
          }

          if (mounted) {
            setState(() {
              _forYouList  = forYouRaw;
              _popularList = popularRaw;
              _mlLoading   = false;
            });
          }
          return;
        }
      }

      if (mounted) {
        setState(() {
          _mlLoading = false;
          _mlError   = 'Could not load recommendations. Try again later.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _mlLoading = false;
          _mlError   = 'Could not load recommendations. Try again later.';
        });
      }
    }
  }

  // ── HELPERS ──────────────────────────────────────────────────────
  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLon = (lon2 - lon1) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2)
        + math.cos(lat1 * math.pi / 180) * math.cos(lat2 * math.pi / 180)
            * math.sin(dLon / 2) * math.sin(dLon / 2);
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  int _parseHour(String s) {
    try {
      final t = s.trim().toUpperCase();
      if (!t.contains('AM') && !t.contains('PM')) {
        return int.parse(t.split(':')[0]);
      }
      final isPM = t.contains('PM');
      int h = int.parse(
          t.replaceAll('AM', '').replaceAll('PM', '').trim().split(':')[0]);
      if (isPM && h != 12) h += 12;
      if (!isPM && h == 12) h = 0;
      return h;
    } catch (_) {
      return -1;
    }
  }

  _Session _checkSession(int o, int c, int r, int f, int tr, DateTime now) {
    final arrH = (now.hour * 60 + now.minute + tr) ~/ 60;
    final nm   = now.hour * 60 + now.minute;
    if (o >= 0 && c >= 0 && arrH >= o && arrH < c) {
      return _Session(true, c * 60 - (nm + tr), 'Morning session open');
    }
    if (r >= 0 && f >= 0 && arrH >= r && arrH < f) {
      return _Session(true, f * 60 - (nm + tr), 'Evening session open');
    }
    return const _Session(false, 0, 'Currently closed');
  }

  String _guessCrowd(int h, int weekday) {
    final isW = weekday >= 6;
    if (h < 7 || h >= 21)  return 'low';
    if (h >= 6  && h < 9)  return isW ? 'high'      : 'medium';
    if (h >= 9  && h < 12) return isW ? 'very_high' : 'medium';
    if (h >= 15 && h < 20) return isW ? 'very_high' : 'high';
    return 'medium';
  }

  double _score(double d, String crowd, bool open, int ml) {
    if (!open || ml < 30) return math.max(0, 50 - d);
    double s = 200 - math.min(d / 10 * 5, 80);
    s += const {'low': 50, 'medium': 30, 'high': 10, 'very_high': 0}[crowd] ?? 20;
    if (ml > 120) s += 20;
    return s;
  }

  String _nearbyReason(_TempleResult t) {
    if (t.dist < 3) return 'Just ${_ds(t.dist)} from your location.';
    if (t.isOpen && t.crowd == 'low') return 'Open now with less crowd — great time to visit.';
    if (t.deity.contains('Murugan')) return 'A sacred Murugan temple near you.';
    if (t.deity.contains('Shiva') || t.deity.contains('Siva')) return 'A revered Shiva temple close to you.';
    if (t.deity.contains('Vishnu') || t.deity.contains('Perumal')) return 'A sacred Vishnu temple near your location.';
    if (t.isOpen) return '${t.session} — ${t.travelMin} min away by ${_vehicleLabel[_vehicle]}.';
    return 'Recommended for your next visit.';
  }

  String _goodTimeReason(_TempleResult t) {
    if (t.crowd == 'low')    return 'Temple is open now and crowd is less — peaceful visit.';
    if (t.crowd == 'medium') return 'Good time — moderate crowd right now.';
    return 'Currently open — good time to plan your visit.';
  }

  String _forYouReason(Map<String, dynamic> t, int rank) {
    final deity = (t['deity'] ?? '').toString().toLowerCase();
    if (rank == 1) return 'Top pick based on your temple activity.';
    if (deity.contains('murugan')) return 'Matches your interest in Murugan temples.';
    if (deity.contains('shiva') || deity.contains('siva')) return 'Recommended based on your Shiva temple visits.';
    if (deity.contains('vishnu') || deity.contains('perumal')) return 'Matches your interest in Vishnu temples.';
    if (deity.contains('devi') || deity.contains('amman')) return 'Based on your visits to Devi temples.';
    return 'Recommended based on your temple activity.';
  }

  String _popularReason(Map<String, dynamic> t) {
    final deity = (t['deity'] ?? '').toString();
    if (deity.toLowerCase().contains('murugan')) return 'Highly visited Murugan temple among devotees.';
    if (deity.isNotEmpty) return 'Popular $deity temple this season.';
    return 'Trending temple visited by many devotees.';
  }

  String _ds(double km) =>
      km < 1 ? '${(km * 1000).round()} m' : '${km.toStringAsFixed(1)} km';

  Color _crowdColor(String c) => const {
    'low': Colors.green, 'medium': Colors.orange,
    'high': Colors.red,  'very_high': Colors.purple,
  }[c] ?? Colors.grey;

  String _crowdText(String c) => const {
    'low': 'Less crowd', 'medium': 'Moderate crowd',
    'high': 'Busy',      'very_high': 'Very crowded',
  }[c] ?? '';

  // ── BUILD ────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _orange,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Discover Temples',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (_tabCtrl.index == 0 && !_gpsLoading) _runGPS();
              if (_tabCtrl.index == 1 && !_mlLoading)  _loadML();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.location_on),  text: 'Near Me'),
            Tab(icon: Icon(Icons.auto_awesome), text: 'For You'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [_nearMeTab(), _forYouTab()],
      ),
    );
  }

  // ── TAB 1 ────────────────────────────────────────────────────────
  Widget _nearMeTab() => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 10, offset: const Offset(0, 3),
          )],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Text('🚗', style: TextStyle(fontSize: 18)),
            SizedBox(width: 8),
            Text('How are you travelling?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ]),
          const SizedBox(height: 14),
          Row(children: ['walk', 'bike', 'car', 'bus'].map((v) {
            final sel = _vehicle == v;
            return Expanded(child: GestureDetector(
              onTap: () => setState(() {
                _vehicle      = v;
                _gpsDone      = false;
                _nearbyList   = [];
                _goodTimeList = [];
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: sel ? _orange : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: sel ? _orange : Colors.grey.shade200),
                  boxShadow: sel
                      ? [BoxShadow(color: _orange.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))]
                      : [],
                ),
                child: Column(children: [
                  Icon(_vehicleIcon[v]!,
                      color: sel ? Colors.white : Colors.grey.shade500, size: 22),
                  const SizedBox(height: 4),
                  Text(
                    {'walk': 'Walk', 'bike': 'Bike', 'car': 'Car', 'bus': 'Bus'}[v]!,
                    style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600,
                      color: sel ? Colors.white : Colors.grey.shade500,
                    ),
                  ),
                ]),
              ),
            ));
          }).toList()),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _gpsLoading ? null : _runGPS,
              style: ElevatedButton.styleFrom(
                backgroundColor: _dark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
              ),
              child: _gpsLoading
                  ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)),
                      SizedBox(width: 10),
                      Text('Finding temples...', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    ])
                  : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Text('📍', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Text(
                        _gpsDone ? '🔄 Search Again' : '✨ Find Temples Near Me',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ]),
            ),
          ),
        ]),
      ),

      if (_gpsError != null) ...[const SizedBox(height: 12), _errorBox(_gpsError!)],

      if (_gpsDone && !_gpsLoading) ...[
        if (_nearbyList.isNotEmpty) ...[
          _sectionTitle('📍 Temples Near You', 'Sorted by distance · via ${_vehicleLabel[_vehicle]}'),
          ..._nearbyList.map(_buildNearbyCard),
        ],
        if (_goodTimeList.isNotEmpty) ...[
          _sectionTitle('⏰ Good Time To Visit Now', 'Open now with comfortable crowd'),
          SizedBox(
            height: 215,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _goodTimeList.length,
              itemBuilder: (_, i) => _buildGoodTimeCard(_goodTimeList[i]),
            ),
          ),
        ],
        if (_nearbyList.isEmpty && _goodTimeList.isEmpty)
          _emptyBox('😕', 'No temples found',
              'Enable location and make sure backend is running.'),
      ],
      const SizedBox(height: 60),
    ]),
  );

  // ── TAB 2 ────────────────────────────────────────────────────────
  Widget _forYouTab() => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (_mlLoading) _loadingBox('Loading your recommendations...', _purple),
      if (!_mlLoading && _mlError != null) _errorBox(_mlError!),
      if (!_mlLoading && _mlError == null) ...[
        if (_forYouList.isNotEmpty) ...[
          _sectionTitle('⭐ Recommended For You', 'Based on your temple activity'),
          ..._forYouList.asMap().entries.map((e) =>
              _buildMLCard(e.value, e.key + 1, forYou: true)),
        ],
        if (_popularList.isNotEmpty) ...[
          _sectionTitle('🔥 Popular Temples Today', 'Trending among devotees'),
          ..._popularList.asMap().entries.map((e) => _buildMLCard(e.value, e.key + 1)),
        ],
        if (_forYouList.isEmpty && _popularList.isEmpty)
          _emptyBox('🧠', 'No recommendations yet',
              'Book darshan or donate to temples to get personalised suggestions!'),
      ],
      const SizedBox(height: 60),
    ]),
  );

  // ── CARD: NEARBY ─────────────────────────────────────────────────
  Widget _buildNearbyCard(_TempleResult t) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(18),
      boxShadow: [BoxShadow(
        color: Colors.black.withValues(alpha: 0.07),
        blurRadius: 8, offset: const Offset(0, 3),
      )],
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Column(children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: _orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: Text('🛕', style: TextStyle(fontSize: 26))),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: t.isOpen ? Colors.green.shade50 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: t.isOpen ? Colors.green.shade300 : Colors.grey.shade300),
            ),
            child: Text(
              t.isOpen ? 'Open' : 'Closed',
              style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.bold,
                color: t.isOpen ? Colors.green.shade700 : Colors.grey.shade500,
              ),
            ),
          ),
        ]),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 3),
          if (t.location.isNotEmpty)
            Text('📍 ${t.location}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          if (t.deity.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text('🕉️ ${t.deity}',
                style: const TextStyle(fontSize: 11, color: _orange, fontWeight: FontWeight.w600),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 8),
          Text(_nearbyReason(t),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.4),
              maxLines: 2),
          const SizedBox(height: 10),
          Wrap(spacing: 6, runSpacing: 6, children: [
            _chip('${_ds(t.dist)} away', Colors.teal),
            _chip('${t.travelMin} min', Colors.blue),
            _chip(_crowdText(t.crowd), _crowdColor(t.crowd)),
            if (t.isOpen) _chip(t.session, Colors.green),
          ]),
        ])),
      ]),
    ),
  );

  // ── CARD: GOOD TIME ──────────────────────────────────────────────
  Widget _buildGoodTimeCard(_TempleResult t) => Container(
    width: 178,
    margin: const EdgeInsets.only(right: 12, bottom: 4),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.green.shade200),
      boxShadow: [BoxShadow(
        color: Colors.black.withValues(alpha: 0.07),
        blurRadius: 8, offset: const Offset(0, 3),
      )],
    ),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: _orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text('🛕', style: TextStyle(fontSize: 20)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.green.shade300),
            ),
            child: Text('Open',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold,
                    color: Colors.green.shade700)),
          ),
        ]),
        const SizedBox(height: 10),
        Text(t.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            maxLines: 2, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 3),
        if (t.location.isNotEmpty)
          Text(t.location,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        const Spacer(),
        Text(_goodTimeReason(t),
            style: TextStyle(fontSize: 11, color: Colors.green.shade700, height: 1.3),
            maxLines: 2),
        const SizedBox(height: 8),
        Wrap(spacing: 4, runSpacing: 4, children: [
          _miniChip(_ds(t.dist), Colors.teal),
          _miniChip(_crowdText(t.crowd), _crowdColor(t.crowd)),
        ]),
      ]),
    ),
  );

  // ── CARD: ML ─────────────────────────────────────────────────────
  Widget _buildMLCard(Map<String, dynamic> t, int rank, {bool forYou = false}) {
    final name    = (t['name']     ?? 'Temple').toString();
    final loc     = (t['location'] ?? '').toString();
    final deity   = (t['deity']    ?? '').toString();
    final fests   = t['festivals'];
    final festStr = (fests is List && fests.isNotEmpty)
        ? '✨ Popular during ${fests.first}'
        : '';
    final isTop       = rank == 1 && forYou;
    final accentColor = forYou ? _orange : Colors.red.shade400;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: isTop
            ? Border.all(color: _orange.withValues(alpha: 0.5), width: 1.5)
            : Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(
          color: isTop
              ? _orange.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.07),
          blurRadius: isTop ? 14 : 8,
          offset: const Offset(0, 3),
        )],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Stack(clipBehavior: Clip.none, children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: forYou ? _orange.withValues(alpha: 0.12) : Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Text(
                forYou ? '🛕' : (rank == 1 ? '🔥' : '🛕'),
                style: const TextStyle(fontSize: 26),
              )),
            ),
            if (isTop)
              Positioned(
                top: -5, right: -5,
                child: Container(
                  width: 20, height: 20,
                  decoration: const BoxDecoration(color: _orange, shape: BoxShape.circle),
                  child: const Center(child: Text('⭐', style: TextStyle(fontSize: 10))),
                ),
              ),
          ]),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 3),
            if (loc.isNotEmpty)
              Text('📍 $loc',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            if (deity.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text('🕉️ $deity',
                  style: TextStyle(fontSize: 11, color: accentColor,
                      fontWeight: FontWeight.w600)),
            ],
            if (festStr.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(festStr,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 8),
            Text(
              forYou ? _forYouReason(t, rank) : _popularReason(t),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.4),
              maxLines: 2,
            ),
          ])),
        ]),
      ),
    );
  }

  // ── SHARED WIDGETS ───────────────────────────────────────────────
  Widget _sectionTitle(String title, String sub) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 10),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _dark)),
      Text(sub, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
    ]),
  );

  Widget _errorBox(String msg) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.orange.shade50,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.orange.shade300),
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Icon(Icons.info_outline, color: Colors.orange, size: 18),
      const SizedBox(width: 8),
      Expanded(child: Text(msg,
          style: const TextStyle(fontSize: 13, color: Colors.brown))),
    ]),
  );

  Widget _loadingBox(String msg, Color color) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 40),
    child: Column(children: [
      CircularProgressIndicator(color: color, strokeWidth: 3),
      const SizedBox(height: 16),
      Text(msg, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
    ]),
  );

  Widget _emptyBox(String emoji, String title, String sub) => Container(
    margin: const EdgeInsets.only(top: 20),
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      color: Colors.orange.shade50,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.orange.shade200),
    ),
    child: Column(children: [
      Text(emoji, style: const TextStyle(fontSize: 40)),
      const SizedBox(height: 12),
      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      const SizedBox(height: 6),
      Text(sub,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.5)),
    ]),
  );

  Widget _chip(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.4)),
    ),
    child: Text(text,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
  );

  Widget _miniChip(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(text,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
  );
}

// ── MODELS ───────────────────────────────────────────────────────
class _Session {
  final bool   isOpen;
  final int    minsLeft;
  final String label;
  const _Session(this.isOpen, this.minsLeft, this.label);
}

class _TempleResult {
  final String name, location, deity, crowd, session;
  final double dist, score;
  final int    travelMin, minsLeft;
  final bool   isOpen;
  const _TempleResult({
    required this.name,      required this.location, required this.deity,
    required this.dist,      required this.travelMin, required this.crowd,
    required this.isOpen,    required this.session,
    required this.score,     required this.minsLeft,
  });
}