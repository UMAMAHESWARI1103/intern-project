import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

// ─── UPDATE THIS to your backend IP/host ───────────────────────────────────
const String _baseUrl = 'http://10.189.163.70:5000';
// ───────────────────────────────────────────────────────────────────────────

class FacilitiesPage extends StatefulWidget {
  const FacilitiesPage({super.key});

  @override
  State<FacilitiesPage> createState() => _FacilitiesPageState();
}

class _FacilitiesPageState extends State<FacilitiesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Location state
  bool _isLoadingLocation = false;
  String _locationStatus = 'Getting your location...';
  Position? _currentPosition;

  // Data state
  bool _isLoadingData = false;
  List<Map<String, dynamic>> _stayFacilities = [];
  List<Map<String, dynamic>> _foodFacilities = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initLocationAndFetch();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── STEP 1: Get GPS, then fetch ──────────────────────────────────────────

  Future<void> _initLocationAndFetch() async {
    setState(() {
      _isLoadingLocation = true;
      _locationStatus = 'Getting your location...';
      _errorMessage = null;
    });

    Position? position;

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationStatus = 'Location off — showing all facilities';
          _isLoadingLocation = false;
        });
        await _fetchFacilities(null);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _locationStatus = 'Permission denied — showing all facilities';
          _isLoadingLocation = false;
        });
        await _fetchFacilities(null);
        return;
      }

      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _locationStatus = 'Showing facilities near you';
        _isLoadingLocation = false;
      });
    } catch (_) {
      setState(() {
        _locationStatus = 'Could not get location — showing all facilities';
        _isLoadingLocation = false;
      });
    }

    await _fetchFacilities(position);
  }

  // ── STEP 2: Fetch from backend with lat/lon params ───────────────────────

  Future<void> _fetchFacilities(Position? position) async {
    setState(() {
      _isLoadingData = true;
      _errorMessage = null;
    });

    try {
      String url = '$_baseUrl/api/facilities';
      if (position != null) {
        url += '?lat=${position.latitude}&lon=${position.longitude}&radius=200';
      }

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        setState(() {
          _stayFacilities =
              List<Map<String, dynamic>>.from(data['stay'] ?? []);
          _foodFacilities =
              List<Map<String, dynamic>>.from(data['food'] ?? []);
          _isLoadingData = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Server error (${response.statusCode})';
          _isLoadingData = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not connect to server. Check your network.';
        _isLoadingData = false;
      });
    }
  }

  // ── ACTIONS ──────────────────────────────────────────────────────────────

  void _callPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _openMaps(String name) async {
    final query = Uri.encodeComponent(name);
    final uri =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ── BUILD ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFFF9800);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text('Facilities',
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _isLoadingData || _isLoadingLocation
                ? null
                : _initLocationAndFetch,
            tooltip: 'Refresh',
          ),
        ],
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.hotel, size: 18), text: 'Stay'),
            Tab(icon: Icon(Icons.restaurant, size: 18), text: 'Food'),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Location banner ──────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: primaryColor.withValues(alpha: 0.08),
            child: Row(children: [
              _isLoadingLocation
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Color(0xFFFF9800)),
                    )
                  : Icon(
                      _currentPosition != null
                          ? Icons.location_on
                          : Icons.location_off,
                      color: primaryColor,
                      size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(_locationStatus,
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500)),
              ),
            ]),
          ),

          // ── Tab content ──────────────────────────────────────────────────
          Expanded(
            child: _isLoadingData
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFFFF9800)))
                : _errorMessage != null
                    ? _buildError(primaryColor)
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildStayTab(primaryColor),
                          _buildFoodTab(primaryColor),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  // ── ERROR STATE ──────────────────────────────────────────────────────────

  Widget _buildError(Color primaryColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(_errorMessage ?? 'Something went wrong',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _initLocationAndFetch,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  // ── STAY TAB ─────────────────────────────────────────────────────────────

  Widget _buildStayTab(Color primaryColor) {
    if (_stayFacilities.isEmpty) {
      return _buildEmpty('No accommodations found nearby', primaryColor);
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionHeader(
            'Nearby Accommodations',
            '${_stayFacilities.length} found',
            primaryColor),
        const SizedBox(height: 12),
        ..._stayFacilities.map((h) => _buildStayCard(h, primaryColor)),
      ],
    );
  }

  Widget _buildStayCard(Map<String, dynamic> item, Color primaryColor) {
    final amenities = List<String>.from(item['amenities'] ?? []);
    final distanceLabel = item['distance_label'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.hotel, color: primaryColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['name'] ?? '',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(item['type'] ?? '',
                        style:
                            TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(item['price'] ?? '',
                      style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                  Row(children: [
                    const Icon(Icons.star, size: 12, color: Colors.amber),
                    Text(' ${item['rating'] ?? ''}',
                        style: const TextStyle(fontSize: 12)),
                  ]),
                ],
              ),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
              Text(' $distanceLabel',
                  style:
                      TextStyle(fontSize: 12, color: Colors.grey[600])),
              const SizedBox(width: 10),
              Expanded(
                child: Wrap(
                  spacing: 5,
                  children: amenities
                      .take(3)
                      .map((a) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(a,
                                style: const TextStyle(fontSize: 10)),
                          ))
                      .toList(),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            _actionButtons(
                item['phone'] ?? '', item['name'] ?? '', primaryColor),
          ],
        ),
      ),
    );
  }

  // ── FOOD TAB ─────────────────────────────────────────────────────────────

  Widget _buildFoodTab(Color primaryColor) {
    if (_foodFacilities.isEmpty) {
      return _buildEmpty('No restaurants found nearby', primaryColor);
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionHeader(
            'Nearby Restaurants',
            '${_foodFacilities.length} found',
            primaryColor),
        const SizedBox(height: 12),
        ..._foodFacilities.map((r) => _buildFoodCard(r, primaryColor)),
      ],
    );
  }

  Widget _buildFoodCard(Map<String, dynamic> item, Color primaryColor) {
    final distanceLabel = item['distance_label'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    Icon(Icons.restaurant, color: primaryColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['name'] ?? '',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(
                        '${item['type'] ?? ''} · ${item['speciality'] ?? ''}',
                        style:
                            TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(children: [
                    const Icon(Icons.star, size: 12, color: Colors.amber),
                    Text(' ${item['rating'] ?? ''}',
                        style: const TextStyle(fontSize: 12)),
                  ]),
                  Text(distanceLabel,
                      style: TextStyle(
                          color: primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
              Text(' ${item['timing'] ?? ''}',
                  style:
                      TextStyle(fontSize: 12, color: Colors.grey[600])),
            ]),
            const SizedBox(height: 12),
            _actionButtons(
                item['phone'] ?? '', item['name'] ?? '', primaryColor),
          ],
        ),
      ),
    );
  }

  // ── SHARED WIDGETS ────────────────────────────────────────────────────────

  Widget _buildEmpty(String message, Color primaryColor) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(message,
              style:
                  const TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _initLocationAndFetch,
            child: Text('Try wider search',
                style: TextStyle(color: primaryColor)),
          )
        ],
      ),
    );
  }

  Widget _sectionHeader(
      String title, String subtitle, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold)),
        Text(subtitle,
            style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _actionButtons(
      String phone, String name, Color primaryColor) {
    return Row(children: [
      Expanded(
        child: OutlinedButton.icon(
          onPressed: () => _callPhone(phone),
          icon: const Icon(Icons.call, size: 16),
          label: const Text('Call'),
          style: OutlinedButton.styleFrom(
            foregroundColor: primaryColor,
            side: BorderSide(color: primaryColor),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: ElevatedButton.icon(
          onPressed: () => _openMaps(name),
          icon: const Icon(Icons.directions, size: 16),
          label: const Text('Directions'),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
    ]);
  }
}