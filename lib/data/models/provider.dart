class Provider {
  final String id;
  final String userId;
  final String name;
  final String phone;
  final String email;
  final String trade;
  final int experienceYears;
  final double rating;
  final int totalJobsCompleted;
  final String verificationStatus;
  final double? distance; // in km
  final String address;
  final double? latitude;
  final double? longitude;

  Provider({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    required this.email,
    required this.trade,
    required this.experienceYears,
    required this.rating,
    required this.totalJobsCompleted,
    required this.verificationStatus,
    this.distance,
    required this.address,
    this.latitude,
    this.longitude,
  });

  factory Provider.fromJson(Map<String, dynamic> json) {
    final user = json['users'] ?? json;
    final profile = json;

    return Provider(
      id: user['id'] ?? '',
      userId: profile['user_id'] ?? '',
      name: user['name'] ?? '',
      phone: user['phone'] ?? '',
      email: user['email'] ?? '',
      trade: profile['trade'] ?? '',
      experienceYears: profile['experience_years'] ?? 0,
      rating: (profile['rating'] ?? 0).toDouble(),
      totalJobsCompleted: profile['total_jobs_completed'] ?? 0,
      verificationStatus: profile['verification_status'] ?? '',
      distance: json['distance'] != null ? (json['distance']).toDouble() : null,
      address: user['address'] ?? '',
      latitude: user['location_lat'] != null
          ? (user['location_lat']).toDouble()
          : null,
      longitude: user['location_lng'] != null
          ? (user['location_lng']).toDouble()
          : null,
    );
  }

  String getDistanceDisplay() {
    if (distance == null) return 'Distance unknown';
    if (distance! < 1) {
      return '${(distance! * 1000).round()} m away';
    }
    return '${distance!.toStringAsFixed(1)} km away';
  }

  String getRatingDisplay() {
    return rating.toStringAsFixed(1);
  }
}