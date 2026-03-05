import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/temple.dart';

class TempleDetailPage extends StatefulWidget {
  final Temple temple;
  const TempleDetailPage({super.key, required this.temple});

  @override
  State<TempleDetailPage> createState() => _TempleDetailPageState();
}

class _TempleDetailPageState extends State<TempleDetailPage> {
  double? _realDistance;
  bool _loadingLocation = true;

  @override
  void initState() {
    super.initState();
    _calculateDistance();
  }

  Future<void> _calculateDistance() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _loadingLocation = false);
        return;
      }
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final templeLat = widget.temple.lat;
      final templeLon = widget.temple.lon;
      if (templeLat != null && templeLon != null &&
          templeLat != 0.0 && templeLon != 0.0) {
        double distanceInMeters = Geolocator.distanceBetween(
          position.latitude, position.longitude, templeLat, templeLon,
        );
        setState(() {
          _realDistance = distanceInMeters / 1000;
          _loadingLocation = false;
        });
      } else {
        setState(() => _loadingLocation = false);
      }
    } catch (e) {
      setState(() => _loadingLocation = false);
    }
  }

  // ── Wrap Wikipedia URL through wsrv.nl proxy to fix hotlink block ────────
  String _proxyImage(String url) {
    if (url.isEmpty) return '';
    // wsrv.nl is a free image proxy/CDN that bypasses hotlink protection
    return 'https://wsrv.nl/?url=${Uri.encodeComponent(url)}&w=600&output=jpg';
  }

  // ── Open Google Maps directions ──────────────────────────────────────────
  Future<void> _openDirections() async {
    final temple = widget.temple;
    if (temple.lat == null || temple.lon == null ||
        temple.lat == 0.0  || temple.lon == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location coordinates not available.')),
      );
      return;
    }
    final Uri nativeUri = Uri.parse(
      'google.navigation:q=${temple.lat},${temple.lon}&mode=d',
    );
    final Uri browserUri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${temple.lat},${temple.lon}'
      '&travelmode=driving',
    );
    if (await canLaunchUrl(nativeUri)) {
      await launchUrl(nativeUri);
    } else if (await canLaunchUrl(browserUri)) {
      await launchUrl(browserUri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Could not open Maps. Please install Google Maps.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final temple = widget.temple;
    final hasImage = temple.imageUrl.isNotEmpty;
    final proxiedUrl = _proxyImage(temple.imageUrl);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF3E0),
      body: CustomScrollView(
        slivers: [

          // ── SliverAppBar — real temple photo via proxy ───────────────────
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: const Color(0xFFFF9933),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                temple.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  shadows: [Shadow(blurRadius: 6, color: Colors.black54)],
                ),
              ),
              background: hasImage
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          proxiedUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (ctx, child, progress) =>
                              progress == null ? child : _fallbackHeader(),
                          errorBuilder: (ctx, err, stack) => _fallbackHeader(),
                        ),
                        // Dark gradient so title stays readable
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.transparent, Colors.black54],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    )
                  : _fallbackHeader(),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Status Row ─────────────────────────────────────────
                  Row(
                    children: [
                      // Open / Closed
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: temple.isOpen ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(children: [
                          Icon(
                            temple.isOpen ? Icons.check_circle : Icons.cancel,
                            color: Colors.white, size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            temple.isOpen ? 'Open' : 'Closed',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ]),
                      ),
                      const SizedBox(width: 12),
                      // Distance
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFCC80),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(children: [
                          const Icon(Icons.location_on,
                              size: 16, color: Color(0xFFFF6600)),
                          const SizedBox(width: 4),
                          _loadingLocation
                              ? const SizedBox(
                                  width: 14, height: 14,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2))
                              : Text(
                                  _realDistance != null
                                      ? '${_realDistance!.toStringAsFixed(1)} km away'
                                      : '${temple.distance.toStringAsFixed(1)} km away',
                                  style: const TextStyle(
                                      color: Color(0xFFFF6600),
                                      fontWeight: FontWeight.bold),
                                ),
                        ]),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── Info Cards ─────────────────────────────────────────
                  _infoCard(icon: Icons.place,             title: 'Location', value: temple.location),
                  _infoCard(icon: Icons.self_improvement,  title: 'Deity',    value: temple.deity),
                  _infoCard(icon: Icons.access_time,       title: 'Timings',  value: '${temple.openTime} - ${temple.closeTime}'),

                  // ── About ──────────────────────────────────────────────
                  if (temple.description.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text('About',
                        style: TextStyle(fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF6600))),
                    const SizedBox(height: 8),
                    Text(temple.description,
                        style: const TextStyle(fontSize: 14, height: 1.5)),
                  ],

                  // ── Festivals ──────────────────────────────────────────
                  if (temple.festivals.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text('Festivals',
                        style: TextStyle(fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF6600))),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: temple.festivals.map((f) => Chip(
                        label: Text(f),
                        backgroundColor: const Color(0xFFFFE0B2),
                        labelStyle: const TextStyle(color: Color(0xFFFF6600)),
                      )).toList(),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ── Get Directions Button ──────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _openDirections,
                      icon: const Icon(Icons.directions, size: 22),
                      label: const Text(
                        'Get Directions',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF9933),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Fallback orange gradient + icon ───────────────────────────────────────
  Widget _fallbackHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF9933), Color(0xFFFFCC80)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.35),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.temple_hindu,
                  size: 70, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  // ── Info card widget ───────────────────────────────────────────────────────
  Widget _infoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      color: const Color(0xFFFFF8F0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFCC80),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFFFF6600), size: 22),
        ),
        title: Text(title,
            style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w500)),
        subtitle: Text(value,
            style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
                fontWeight: FontWeight.bold)),
      ),
    );
  }
}