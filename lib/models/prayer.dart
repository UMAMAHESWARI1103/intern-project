class Prayer {
  final String id;
  final String title;
  final String category;
  final String language;
  final String lyrics;
  final String meaning;
  final int durationMinutes;
  final String audioUrl;
  final String deity;
  final String imageUrl;

  Prayer({
    required this.id,
    required this.title,
    required this.category,
    required this.language,
    required this.lyrics,
    required this.meaning,
    required this.durationMinutes,
    required this.audioUrl,
    required this.deity,
    required this.imageUrl,
  });

  factory Prayer.fromJson(Map<String, dynamic> json) {
    return Prayer(
      id: json['id'] ?? json['_id'] ?? '',
      title: json['title'] ?? '',
      category: json['category'] ?? '',
      language: json['language'] ?? 'Sanskrit',
      lyrics: json['lyrics'] ?? '',
      meaning: json['meaning'] ?? '',
      durationMinutes: json['duration_minutes'] ?? 5,
      audioUrl: json['audio_url'] ?? '',
      deity: json['deity'] ?? '',
      imageUrl: json['image_url'] ?? '',
    );
  }
}
