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

  Future<Booking> createBooking({
    required String customerId,
    required String providerId,
    required String serviceId,
    required DateTime scheduledTime,
    required int totalPrice,
    String? address,
    String? notes,
  }) async {
    try {
      print('📦📦📦 createBooking STARTED');
      print('📦 customerId: $customerId');
      print('📦 providerId: $providerId');
      print('📦 serviceId: $serviceId');

      final bookingNumber = 'BKG${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

      final Map<String, dynamic> insertData = {
        'booking_number': bookingNumber,
        'customer_id': customerId,
        'provider_id': providerId,
        'service_id': serviceId,
        'scheduled_time': scheduledTime.toIso8601String(),
        'status': 'pending',
        'total_price': totalPrice,
        'total_amount': totalPrice,
        'payment_status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      };

      if (address != null && address.isNotEmpty) {
        insertData['address'] = address;
      }
      if (notes != null && notes.isNotEmpty) {
        insertData['notes'] = notes;
      }

      print('📦 Inserting booking...');

      final response = await _supabase
          .from('bookings')
          .insert(insertData)
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
          .single();

      final booking = Booking.fromJson(response);
      print('✅ Booking inserted! ID: ${booking.id}');

      // ✅ Send notification to provider
      print('📤 Getting customer name...');
      final customer = await _supabase
          .from('users')
          .select('name')
          .eq('id', customerId)
          .single();
      print('📤 Customer: ${customer['name']}');

      print('📤 Getting service name...');
      final service = await _supabase
          .from('services')
          .select('name')
          .eq('id', serviceId)
          .single();
      print('📤 Service: ${service['name']}');

      print('📤 Sending notification to provider: $providerId');
      await _sendNotification(
        recipientId: providerId,
        title: '🔔 New Booking Request',
        body: '${customer['name']} booked ${service['name']}',
        data: {
          'booking_id': booking.id,
          'type': 'new_booking',
        },
      );
      print('✅ Notification sent successfully!');

      return booking;
    } catch (e) {
      print('❌❌❌ createBooking ERROR: $e');
      throw Exception('Failed to create booking: $e');
    }
  }

  Future<List<Booking>> getProviderBookings(String providerId) async {
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
          service:services (
            id,
            name,
            fixed_price
          )
        ''')
          .eq('provider_id', providerId)
          .order('scheduled_time', ascending: true);

      return (response as List).map((json) => Booking.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch provider bookings: $e');
    }
  }

  Future<void> acceptBooking(String bookingId) async {
    try {
      print('📦 acceptBooking STARTED: $bookingId');

      // Get booking details first (for notification)
      final bookingData = await _supabase
          .from('bookings')
          .select('customer_id, provider_id, booking_number')
          .eq('id', bookingId)
          .single();

      // Get provider name
      final provider = await _supabase
          .from('users')
          .select('name')
          .eq('id', bookingData['provider_id'])
          .single();

      // Update booking status
      await _supabase
          .from('bookings')
          .update({
        'status': 'accepted',
        'accepted_at': DateTime.now().toIso8601String(),
      })
          .eq('id', bookingId);

      print('✅ Booking accepted!');

      // Send notification to customer
      print('📤 Sending notification to customer: ${bookingData['customer_id']}');
      await _sendNotification(
        recipientId: bookingData['customer_id'],
        title: '✅ Booking Accepted',
        body: '${provider['name']} accepted your booking #${bookingData['booking_number']}',
        data: {
          'booking_id': bookingId,
          'type': 'accepted',
        },
      );
      print('✅ Notification sent!');
    } catch (e) {
      print('❌❌❌ acceptBooking ERROR: $e');
      throw Exception('Failed to accept booking: $e');
    }
  }

// Reject booking
  Future<void> rejectBooking(String bookingId) async {
    try {
      await _supabase
          .from('bookings')
          .update({
        'status': 'rejected',
        'rejected_at': DateTime.now().toIso8601String(),
      })
          .eq('id', bookingId);
    } catch (e) {
      throw Exception('Failed to reject booking: $e');
    }
  }

// Complete booking (provider marks as complete)
  Future<void> completeBooking(String bookingId) async {
    try {
      print('📦 completeBooking STARTED: $bookingId');

      // Get booking details first (for notification)
      final bookingData = await _supabase
          .from('bookings')
          .select('customer_id, provider_id, booking_number')
          .eq('id', bookingId)
          .single();

      // Get provider name
      final provider = await _supabase
          .from('users')
          .select('name')
          .eq('id', bookingData['provider_id'])
          .single();

      // Update booking status
      await _supabase
          .from('bookings')
          .update({
        'status': 'completed',
        'completed_at': DateTime.now().toIso8601String(),
      })
          .eq('id', bookingId);

      // Update provider's total jobs completed
      await _supabase.rpc('increment_provider_jobs', params: {
        'p_user_id': bookingData['provider_id'],
      });

      print('✅ Booking completed!');

      // Send notification to customer
      print('📤 Sending notification to customer: ${bookingData['customer_id']}');
      await _sendNotification(
        recipientId: bookingData['customer_id'],
        title: '✅ Job Completed',
        body: '${provider['name']} completed your booking #${bookingData['booking_number']}. Please confirm.',
        data: {
          'booking_id': bookingId,
          'type': 'completed',
        },
      );
      print('✅ Notification sent!');
    } catch (e) {
      print('❌❌❌ completeBooking ERROR: $e');
      throw Exception('Failed to complete booking: $e');
    }
  }

  Future<void> _sendNotification({
    required String recipientId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    print('📤📤📤 _sendNotification CALLED');
    print('📤 recipientId: $recipientId');
    print('📤 title: $title');
    print('📤 body: $body');

    try {
      print('📤 Calling Supabase Edge Function...');
      final response = await _supabase.functions.invoke(
        'send-notification',
        body: {
          'recipient_id': recipientId,
          'title': title,
          'body': body,
          'data': data ?? {},
        },
      );
      print('✅ Edge Function response: $response');
      print('✅ _sendNotification completed successfully!');
    } catch (e) {
      print('❌❌❌ _sendNotification ERROR: $e');
      print('❌ Failed to send notification: $e');
    }
  }
}