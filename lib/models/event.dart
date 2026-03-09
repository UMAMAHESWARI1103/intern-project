class Event {
  final String id;
  final String title;
  final String description;
  final String templeName;
  final String templeId;
  final DateTime date;
  final String time;
  final String location;
  final String category;
  final double price;
  final bool isFree;
  final int maxCapacity;
  final int registeredCount;
  final String imageUrl;
  final bool isActive;

  // Aliases for legacy code
  double get registrationFee => price;
  int get maxParticipants => maxCapacity;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.templeName,
    required this.templeId,
    required this.date,
    required this.time,
    this.location = '',
    this.category = 'Other',
    this.price = 0,
    required this.isFree,
    this.maxCapacity = 100,
    this.registeredCount = 0,
    this.imageUrl = '',
    this.isActive = true,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    // Parse price first — needed to derive isFree if backend field is missing
    final double parsedPrice = ((json['registration_fee'] ??
            json['price'] ??
            json['registrationFee'] ??
            0) as num)
        .toDouble();

    // FIX: Never default isFree to true.
    // Priority: is_free → isFree → derive from price (price == 0 means free)
    final bool parsedIsFree = json.containsKey('is_free')
        ? (json['is_free'] == true || json['is_free'] == 1)
        : json.containsKey('isFree')
            ? (json['isFree'] == true || json['isFree'] == 1)
            : parsedPrice == 0.0; // fallback: free only if price is 0

    return Event(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',

      title:       json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',

      templeName: json['temple_name']?.toString() ??
          json['templeName']?.toString() ?? '',
      templeId: json['temple_id']?.toString() ??
          json['templeId']?.toString() ?? '',

      date: json['date'] != null
          ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now()
          : DateTime.now(),

      time:     json['time']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Other',

      price:  parsedPrice,
      isFree: parsedIsFree,

      maxCapacity: ((json['max_participants'] ??
              json['maxCapacity'] ??
              json['maxParticipants'] ??
              100) as num)
          .toInt(),

      registeredCount: ((json['registered_count'] ??
              json['registeredCount'] ??
              0) as num)
          .toInt(),

      imageUrl: json['image_url']?.toString() ??
          json['imageUrl']?.toString() ?? '',
      isActive: json['is_active'] ?? json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id':               id,
        'title':            title,
        'description':      description,
        'temple_name':      templeName,
        'temple_id':        templeId,
        'date':             date.toIso8601String(),
        'time':             time,
        'location':         location,
        'category':         category,
        'registration_fee': price,
        'is_free':          isFree,
        'max_participants': maxCapacity,
        'registered_count': registeredCount,
        'image_url':        imageUrl,
        'is_active':        isActive,
      };
}