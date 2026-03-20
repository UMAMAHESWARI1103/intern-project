import 'package:geolocator/geolocator.dart';

class Temple {
  final String id;
  final String name;
  final String location;
  final String deity;
  final String description;
  final String icon;
  final double distance;

  // ── Morning session ──────────────────────────────────────
  final String openTime;
  final String closeTime;

  // ── Evening session ──────────────────────────────────────
  final String reopenTime;
  final String finalCloseTime;

  // ── Convenience display string ───────────────────────────
  // e.g. "6:00 AM – 12:00 PM | 4:30 PM – 8:30 PM"
  final String timingDisplay;

  final List<String> festivals;
  final String imageUrl;
  final bool isOpen;
  final double? lat;
  final double? lon;

  Temple({
    required this.id,
    required this.name,
    required this.location,
    required this.deity,
    required this.description,
    required this.icon,
    required this.distance,
    required this.openTime,
    required this.closeTime,
    required this.reopenTime,
    required this.finalCloseTime,
    required this.timingDisplay,
    required this.festivals,
    required this.imageUrl,
    required this.isOpen,
    this.lat,
    this.lon,
  });

  double distanceFromUser(double userLat, double userLon) {
    if (lat == null || lon == null || lat == 0.0 || lon == 0.0) {
      return distance;
    }
    final distanceInMeters = Geolocator.distanceBetween(
      userLat, userLon, lat!, lon!,
    );
    return distanceInMeters / 1000;
  }

  /// Returns a human-friendly status string for the current IST time.
  /// e.g.  "Open"  /  "Closed (Opens 4:30 PM)"  /  "Closed (Opens 6:00 AM)"
  String get currentSessionStatus {
    if (isOpen) return 'Open';
    // Determine which session opens next
    final now     = _currentHour();
    final morning = _parseHour(openTime);
    final noon    = _parseHour(closeTime);
    final evening = _parseHour(reopenTime);

    if (now < morning) return 'Closed · Opens $openTime';
    if (now >= noon && now < evening) return 'Closed · Opens $reopenTime';
    return 'Closed';
  }

  // ✅ Uses IST time
  double _currentHour() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
    return now.hour + now.minute / 60.0;
  }

  double _parseHour(String timeStr) {
    try {
      final parts  = timeStr.trim().split(' ');
      final period = parts.length > 1 ? parts[1] : 'AM';
      final hm     = parts[0].split(':');
      double h     = double.parse(hm[0]);
      final m      = hm.length > 1 ? double.parse(hm[1]) : 0.0;
      if (period == 'PM' && h != 12) h += 12;
      if (period == 'AM' && h == 12) h = 0;
      return h + m / 60.0;
    } catch (_) {
      return 0;
    }
  }

  // ✅ Calculate isOpen from actual IST time instead of trusting backend
  static bool _calculateIsOpen(
    String openTime,
    String closeTime,
    String reopenTime,
    String finalCloseTime,
  ) {
    // Get current IST time
    final now     = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
    final current = now.hour * 60 + now.minute;

    int toMin(String t) {
      try {
        t = t.trim();
        final isPM = t.toUpperCase().contains('PM');
        final isAM = t.toUpperCase().contains('AM');
        t = t.replaceAll(RegExp(r'[AaPpMm]'), '').trim();
        final parts = t.split(':');
        int h = int.tryParse(parts[0]) ?? 0;
        int m = parts.length > 1 ? (int.tryParse(parts[1].trim()) ?? 0) : 0;
        if (isPM && h != 12) h += 12;
        if (isAM && h == 12) h = 0;
        return h * 60 + m;
      } catch (_) {
        return 0;
      }
    }

    final open1  = toMin(openTime);
    final close1 = toMin(closeTime);
    final open2  = toMin(reopenTime);
    final close2 = toMin(finalCloseTime);

    return (current >= open1 && current <= close1) ||
           (current >= open2 && current <= close2);
  }

  factory Temple.fromJson(Map<String, dynamic> json) {
    final openTime       = json['open_time']        ?? json['openTime']        ?? '6:00 AM';
    final closeTime      = json['close_time']       ?? json['closeTime']       ?? '12:00 PM';
    final reopenTime     = json['reopen_time']      ?? json['reopenTime']      ?? '4:00 PM';
    final finalCloseTime = json['final_close_time'] ?? json['finalCloseTime']  ?? '8:30 PM';

    return Temple(
      id:             (json['_id'] ?? json['id'] ?? '').toString(),
      name:           json['name']        ?? '',
      location:       json['location']    ?? '',
      deity:          json['deity']       ?? '',
      description:    json['description'] ?? '',
      icon:           json['icon']        ?? '🛕',
      distance:       (json['distance']   ?? 0).toDouble(),
      openTime:       openTime,
      closeTime:      closeTime,
      reopenTime:     reopenTime,
      finalCloseTime: finalCloseTime,
      timingDisplay:  json['timing_display'] ?? '$openTime – $closeTime | $reopenTime – $finalCloseTime',
      festivals: json['festivals'] != null
          ? List<String>.from(json['festivals'])
          : [],
      imageUrl: json['image_url'] ?? json['imageUrl'] ?? '',

      // ✅ Calculate from actual IST time — ignores backend is_open value
      isOpen: _calculateIsOpen(openTime, closeTime, reopenTime, finalCloseTime),

      lat: json['lat'] != null ? (json['lat']).toDouble() : null,
      lon: json['lon'] != null ? (json['lon']).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id':               id,
      'name':             name,
      'location':         location,
      'deity':            deity,
      'description':      description,
      'icon':             icon,
      'distance':         distance,
      'open_time':        openTime,
      'close_time':       closeTime,
      'reopen_time':      reopenTime,
      'final_close_time': finalCloseTime,
      'timing_display':   timingDisplay,
      'festivals':        festivals,
      'image_url':        imageUrl,
      'is_open':          isOpen,
      'lat':              lat,
      'lon':              lon,
    };
  }
}