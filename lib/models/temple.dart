import 'package:geolocator/geolocator.dart';

class Temple {
  final String id;      // ✅ FIX: String not int (MongoDB _id is ObjectId string)
  final String name;
  final String location;
  final String deity;
  final String description;
  final String icon;
  final double distance;
  final String openTime;
  final String closeTime;
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

  factory Temple.fromJson(Map<String, dynamic> json) {
    return Temple(
      // ✅ FIX: MongoDB returns _id as ObjectId string, fallback to id field
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name:        json['name']        ?? '',
      location:    json['location']    ?? '',
      deity:       json['deity']       ?? '',
      description: json['description'] ?? '',
      icon:        json['icon']        ?? '🛕',
      distance:    (json['distance']   ?? 0).toDouble(),
      openTime:    json['open_time']   ?? json['openTime']  ?? '6:00 AM',
      closeTime:   json['close_time']  ?? json['closeTime'] ?? '8:00 PM',
      festivals: json['festivals'] != null
          ? List<String>.from(json['festivals'])
          : [],
      imageUrl: json['image_url'] ?? json['imageUrl'] ?? '',
      isOpen:   json['is_open']   ?? json['isOpen']   ?? true,
      lat: json['lat'] != null ? (json['lat']).toDouble() : null,
      lon: json['lon'] != null ? (json['lon']).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id':          id,
      'name':        name,
      'location':    location,
      'deity':       deity,
      'description': description,
      'icon':        icon,
      'distance':    distance,
      'open_time':   openTime,
      'close_time':  closeTime,
      'festivals':   festivals,
      'image_url':   imageUrl,
      'is_open':     isOpen,
      'lat':         lat,
      'lon':         lon,
    };
  }
}