import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/booking.dart';

class BookingRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all bookings for a customer
  Future<List<Booking>> getCustomerBookings(String customerId) async {
    try {
      final response = await _supabase
          .from('bookings')
          .select('''
            *,
            customer:users!customer_id (
              id,
              name,
              phone,
              address
            ),
            provider:users!provider_id (
              id,
              name,
              phone
            ),
            service:services (
              id,
              name,
              fixed_price
            )
          ''')
          .eq('customer_id', customerId)
          .order('created_at', ascending: false);

      return (response as List).map((json) => Booking.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch bookings: $e');
    }
  }

  // Get booking by ID
  Future<Booking> getBookingById(String bookingId) async {
    try {
      final response = await _supabase
          .from('bookings')
          .select('''
            *,
            customer:users!customer_id (
              id,
              name,
              phone,
              address
            ),
            provider:users!provider_id (
              id,
              name,
              phone
            ),
            service:services (
              id,
              name,
              fixed_price
            )
          ''')
          .eq('id', bookingId)
          .single();

      return Booking.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch booking: $e');
    }
  }

  // Cancel booking
  Future<void> cancelBooking(String bookingId) async {
    try {
      await _supabase
          .from('bookings')
          .update({
        'status': 'cancelled',
        'cancelled_at': DateTime.now().toIso8601String(),
      })
          .eq('id', bookingId);
    } catch (e) {
      throw Exception('Failed to cancel booking: $e');
    }
  }

  // Confirm booking (customer confirms completion)
  Future<void> confirmBooking(String bookingId) async {
    try {
      await _supabase
          .from('bookings')
          .update({
        'status': 'confirmed',
        'payment_status': 'paid',
        'customer_confirmed_at': DateTime.now().toIso8601String(),
      })
          .eq('id', bookingId);
    } catch (e) {
      throw Exception('Failed to confirm booking: $e');
    }
  }

  // Rate booking
  Future<void> rateBooking({
    required String bookingId,
    required int rating,
    String? review,
  }) async {
    try {
      // Insert rating
      await _supabase.from('ratings').insert({
        'booking_id': bookingId,
        'rating': rating,
        'review': review ?? '',
        'created_at': DateTime.now().toIso8601String(),
      });

      // Get provider_id from booking
      final booking = await _supabase
          .from('bookings')
          .select('provider_id')
          .eq('id', bookingId)
          .single();

      if (booking['provider_id'] != null) {
        // Update provider rating (simplified)
        // Get all ratings for this provider
        final ratings = await _supabase
            .from('ratings')
            .select('rating');

        // Calculate average
        if (ratings.isNotEmpty) {
          double total = 0;
          for (var r in ratings) {
            total += (r['rating'] as num).toDouble();
          }
          final avg = total / ratings.length;

          // Update provider profile
          await _supabase
              .from('provider_profiles')
              .update({'rating': avg})
              .eq('user_id', booking['provider_id']);
        }
      }
    } catch (e) {
      throw Exception('Failed to rate booking: $e');
    }
  }
}