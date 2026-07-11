import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/provider.dart';

class ProviderRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get providers by trade within radius
  Future<List<Provider>> getProvidersByTrade({
    required String trade,
    required double customerLat,
    required double customerLng,
    required int radiusInKm,
  }) async {
    try {
      final response = await _supabase
          .from('provider_profiles')
          .select('''
            *,
            users!user_id (
              id,
              name,
              phone,
              email,
              address,
              location_lat,
              location_lng,
              location
            )
          ''')
          .eq('trade', trade)
          .eq('verification_status', 'approved')
          .eq('is_active', true);

      final providers = (response as List)
          .map((json) => Provider.fromJson(json))
          .toList();

      // Filter by distance using Haversine formula
      final filtered = providers.where((p) {
        if (p.latitude == null || p.longitude == null) return false;

        final distance = _calculateDistance(
          customerLat,
          customerLng,
          p.latitude!,
          p.longitude!,
        );

        return distance <= radiusInKm;
      }).toList();

      // Sort by distance
      filtered.sort((a, b) {
        final distA = _calculateDistance(
          customerLat,
          customerLng,
          a.latitude ?? 0,
          a.longitude ?? 0,
        );
        final distB = _calculateDistance(
          customerLat,
          customerLng,
          b.latitude ?? 0,
          b.longitude ?? 0,
        );
        return distA.compareTo(distB);
      });

      // Add distance to each provider
      return filtered.map((p) {
        final dist = _calculateDistance(
          customerLat,
          customerLng,
          p.latitude ?? 0,
          p.longitude ?? 0,
        );
        return Provider(
          id: p.id,
          userId: p.userId,
          name: p.name,
          phone: p.phone,
          email: p.email,
          trade: p.trade,
          experienceYears: p.experienceYears,
          rating: p.rating,
          totalJobsCompleted: p.totalJobsCompleted,
          verificationStatus: p.verificationStatus,
          distance: dist,
          address: p.address,
          latitude: p.latitude,
          longitude: p.longitude,
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch providers: $e');
    }
  }


  double _calculateDistance(
      double lat1,
      double lon1,
      double lat2,
      double lon2,
      ) {
    const R = 6371; // Earth's radius in km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _toRadians(double degree) => degree * pi / 180;
}