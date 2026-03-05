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

  // Aliases for any legacy code
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
    return Event(
      // id — handle both _id (Mongo) and id
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',

      title:       json['title'] ?? '',
      description: json['description'] ?? '',

      // Backend sends temple_name and templeId / temple_id
      templeName: json['temple_name'] ?? json['templeName'] ?? '',
      templeId:   json['temple_id']?.toString() ?? json['templeId']?.toString() ?? '',

      date: json['date'] != null
          ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now()
          : DateTime.now(),

      time:     json['time'] ?? '',
      location: json['location'] ?? '',
      category: json['category'] ?? 'Other',

      // Backend sends registration_fee — also accept price as fallback
      price: ((json['registration_fee'] ?? json['price'] ?? json['registrationFee'] ?? 0) as num).toDouble(),

      // Backend sends is_free
      isFree: json['is_free'] ?? json['isFree'] ?? true,

      // Backend sends max_participants — also accept maxCapacity as fallback
      maxCapacity: ((json['max_participants'] ?? json['maxCapacity'] ?? json['maxParticipants'] ?? 100) as num).toInt(),

      // Backend sends registered_count
      registeredCount: ((json['registered_count'] ?? json['registeredCount'] ?? 0) as num).toInt(),

      imageUrl: json['image_url'] ?? json['imageUrl'] ?? '',
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
