import 'package:flutter/material.dart';
import '../models/temple.dart';
import '../services/api_service.dart';
import 'temple_detail_page.dart';
import 'package:geolocator/geolocator.dart';

class TempleListPage extends StatefulWidget {
  const TempleListPage({super.key});

  @override
  State<TempleListPage> createState() => _TempleListPageState();
}

class _TempleListPageState extends State<TempleListPage> {
  List<Temple> temples         = [];
  List<Temple> filteredTemples = [];
  bool         isLoading       = true;
  String?      errorMessage;
  final TextEditingController searchController = TextEditingController();
  Position? _userPosition;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    _loadTemples();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _getUserLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() => _userPosition = position);
    } catch (_) {}
  }

  Future<void> _loadTemples() async {
    setState(() { isLoading = true; errorMessage = null; });
    try {
      final raw     = await ApiService.getAllTemples();
      final fetched = raw
          .map((e) => Temple.fromJson(e as Map<String, dynamic>))
          .toList();
      setState(() {
        temples         = fetched;
        filteredTemples = List.from(fetched);
        isLoading       = false;
        if (searchController.text.trim().isNotEmpty) {
          _filterTemples(searchController.text);
        }
      });
    } catch (e) {
      setState(() { errorMessage = e.toString(); isLoading = false; });
    }
  }

  void _filterTemples(String query) {
    setState(() {
      if (query.trim().isEmpty) {
        filteredTemples = List.from(temples);
      } else {
        final q = query.trim().toLowerCase();
        filteredTemples = temples.where((t) =>
          t.name.toLowerCase().contains(q)     ||
          t.location.toLowerCase().contains(q) ||
          t.deity.toLowerCase().contains(q)
        ).toList();
      }
    });
  }

  String _getDistanceText(Temple temple) {
    // FIX: removed unnecessary null checks and ! operators on lat/lon
    if (_userPosition != null &&
        temple.lat != 0.0 && temple.lon != 0.0) {
      final d = temple.distanceFromUser(
          _userPosition!.latitude, _userPosition!.longitude);
      return '${d.toStringAsFixed(1)} km';
    }
    return '${temple.distance.toStringAsFixed(1)} km';
  }

  /// Returns a formatted two-session timing string.
  /// Uses timingDisplay from API if available, otherwise builds from fields.
  String _getTimingText(Temple temple) {
    // FIX: removed unnecessary null check and ! operator on timingDisplay
    if (temple.timingDisplay.isNotEmpty) {
      return temple.timingDisplay;
    }
    // Build from individual fields
    final open  = temple.openTime.isNotEmpty  ? temple.openTime  : '6:00 AM';
    final close = temple.closeTime.isNotEmpty ? temple.closeTime : '12:30 PM';

    // FIX: removed unnecessary null checks and ! operators on reopenTime/finalCloseTime
    final reopen     = temple.reopenTime.isNotEmpty     ? temple.reopenTime     : '4:00 PM';
    final finalClose = temple.finalCloseTime.isNotEmpty ? temple.finalCloseTime : '8:30 PM';

    return '$open–$close  |  $reopen–$finalClose';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Temples'),
        backgroundColor: const Color(0xFFFF9933),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadTemples),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: searchController,
            onChanged: (v) { _filterTemples(v); setState(() {}); },
            decoration: InputDecoration(
              hintText: 'Search temples...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFFFF9933)),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        searchController.clear();
                        _filterTemples('');
                        setState(() {});
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFFFF9933), width: 2),
              ),
            ),
          ),
        ),
        Expanded(child: _buildContent()),
      ]),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFFFF9933)));
    }
    if (errorMessage != null) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadTemples,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF9933),
              foregroundColor: Colors.white,
            ),
          ),
        ]),
      );
    }
    if (filteredTemples.isEmpty) {
      return Center(
        child: Text(
          searchController.text.isEmpty
              ? 'No temples found'
              : 'No temples match your search',
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredTemples.length,
      itemBuilder: (_, i) => _buildTempleCard(filteredTemples[i]),
    );
  }

  Widget _buildTempleCard(Temple temple) {
    final timingText = _getTimingText(temple);

    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => TempleDetailPage(temple: temple))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFF9933)),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Main row: avatar + info ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  Container(
                    width: 58, height: 58,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFFF9933),
                    ),
                    child: Center(
                      child: Text(
                        temple.name.isNotEmpty
                            ? temple.name[0].toUpperCase()
                            : 'T',
                        style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Text info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name
                        Text(
                          temple.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),

                        // Location
                        Row(children: [
                          const Icon(Icons.location_on,
                              size: 13, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              temple.location.isNotEmpty
                                  ? temple.location
                                  : 'Location not set',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ]),
                        const SizedBox(height: 3),

                        // Deity + Distance
                        Row(children: [
                          const Icon(Icons.self_improvement,
                              size: 13, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              temple.deity,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.directions_car,
                              size: 13, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            _getDistanceText(temple),
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey),
                          ),
                        ]),
                      ],
                    ),
                  ),

                  // Arrow
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(Icons.arrow_forward_ios,
                        size: 16, color: Color(0xFFFF9933)),
                  ),
                ],
              ),
            ),

            // ── Timing + Open/Closed banner ──────────────────────────────
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: temple.isOpen
                    ? Colors.green.withValues(alpha: 0.07)
                    : Colors.red.withValues(alpha: 0.05),
                border: Border(
                  top: BorderSide(
                    color: temple.isOpen
                        ? Colors.green.withValues(alpha: 0.25)
                        : Colors.red.withValues(alpha: 0.18),
                  ),
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(15),
                  bottomRight: Radius.circular(15),
                ),
              ),
              child: Row(
                children: [
                  // Clock icon
                  Icon(
                    Icons.access_time_rounded,
                    size: 14,
                    color: temple.isOpen ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 6),

                  // Timing text — two sessions
                  Expanded(
                    child: Text(
                      timingText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: temple.isOpen
                            ? Colors.green.shade700
                            : Colors.red.shade600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Open / Closed badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: temple.isOpen ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      temple.isOpen ? 'Open Now' : 'Closed',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}