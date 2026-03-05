// Place at: lib/services/route_service.dart

import 'package:geolocator/geolocator.dart';
import 'api_service.dart';

class RouteService {
  /// Returns route info for a given temple + vehicle.
  /// {
  ///   'can_reach':          bool,
  ///   'distance_km':        String,
  ///   'estimated_duration': String,
  ///   'warnings':           List<String>,
  /// }
  Future<Map<String, dynamic>> checkAccessibility({
    required Position userLocation,
    required String templeId,
    required String vehicleType,
  }) async {
    // Fetch temple details from backend to get lat/lng
    Map<String, dynamic>? temple;
    try {
      final temples = await ApiService.getAllTemples();
      final found   = temples.where((t) => t['_id'] == templeId).toList();
      if (found.isNotEmpty) temple = Map<String, dynamic>.from(found.first as Map);
    } catch (_) {}

    double distKm = 10; // default fallback

    if (temple != null) {
      final lat = (temple['latitude']  as num? ??
                   temple['lat']       as num? ?? 0).toDouble();
      final lng = (temple['longitude'] as num? ??
                   temple['lng']       as num? ?? 0).toDouble();

      if (lat != 0 && lng != 0) {
        distKm = Geolocator.distanceBetween(
              userLocation.latitude,
              userLocation.longitude,
              lat,
              lng,
            ) /
            1000;
      }
    }

    final warnings = <String>[];
    bool canReach  = true;

    // Vehicle-specific rules
    if (vehicleType == 'walk' && distKm > 5) {
      warnings.add('⚠️ Walking distance is ${distKm.toStringAsFixed(1)} km — consider a vehicle.');
      canReach = false;
    }
    if (vehicleType == 'car') {
      warnings.add('🚗 Limited parking near the temple. Arrive early for parking.');
    }
    if (vehicleType == 'bus') {
      warnings.add('🚌 Check local bus timings — last buses may end by 9 PM.');
    }
    if (distKm > 100) {
      warnings.add('📍 Temple is ${distKm.toStringAsFixed(0)} km away. Plan an overnight trip.');
    }

    final duration = _estimateDuration(vehicleType, distKm);

    return {
      'can_reach':          canReach,
      'distance_km':        distKm.toStringAsFixed(1),
      'estimated_duration': duration,
      'warnings':           warnings,
    };
  }

  String _estimateDuration(String vehicle, double km) {
    double speedKmH;
    switch (vehicle) {
      case 'walk': speedKmH = 5;  break;
      case 'bike': speedKmH = 35; break;
      case 'car':  speedKmH = 40; break;
      case 'bus':  speedKmH = 25; break;
      default:     speedKmH = 35;
    }
    final minutes = ((km / speedKmH) * 60).round();
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}min';
  }
}