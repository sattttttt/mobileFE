class Schedule {
  final int id;
  final int userId;
  final String title;
  final String? location;
  final double? latitude;
  final double? longitude;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;

  Schedule({
    required this.id,
    required this.userId,
    required this.title,
    this.location,
    this.latitude,
    this.longitude,
    this.description,
    required this.startTime,
    required this.endTime,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      location: json['location'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      description: json['description'],
      startTime: DateTime.parse(json['start_time']).toLocal(),
      endTime: DateTime.parse(json['end_time']).toLocal(),
    );
  }
}
