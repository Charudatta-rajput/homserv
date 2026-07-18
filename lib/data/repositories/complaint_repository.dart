import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/complaint.dart';

class ComplaintRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Create complaint
  Future<Complaint> createComplaint({
    required String raisedBy,
    required String reason,
    String? bookingId,
    List<String>? evidencePhotos,
    int? refundAmount,
  }) async {
    try {
      final response = await _supabase
          .from('disputes')
          .insert({
        'raised_by': raisedBy,
        'reason': reason,
        'booking_id': bookingId,
        'evidence_photos': evidencePhotos ?? [],
        'status': 'open',
        'refund_amount': refundAmount ?? 0,
        'created_at': DateTime.now().toIso8601String(),
      })
          .select('''
            *,
            booking:bookings (
              booking_number,
              service:services (name),
              provider:users!bookings_provider_id_fkey (name)
            )
          ''')
          .single();

      return Complaint.fromJson(response);
    } catch (e) {
      throw Exception('Failed to raise complaint: $e');
    }
  }

  // Get complaints for a user
  Future<List<Complaint>> getUserComplaints(String userId) async {
    try {
      final response = await _supabase
          .from('disputes')
          .select('''
            *,
            booking:bookings (
              booking_number,
              service:services (name),
              provider:users!bookings_provider_id_fkey (name)
            )
          ''')
          .eq('raised_by', userId)
          .order('created_at', ascending: false);

      return (response as List).map((json) => Complaint.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch complaints: $e');
    }
  }

  // Get user's completed bookings for dropdown
  Future<List<Map<String, dynamic>>> getUserCompletedBookings(String userId) async {
    try {
      final response = await _supabase
          .from('bookings')
          .select('''
            id,
            booking_number,
            service:services (name),
            provider:users!bookings_provider_id_fkey (name)
          ''')
          .eq('customer_id', userId)
          .inFilter('status', ['completed', 'confirmed'])
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch bookings: $e');
    }
  }
}