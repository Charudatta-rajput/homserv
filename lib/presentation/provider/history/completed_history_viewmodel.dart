import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/repositories/booking_repository.dart';
import 'completed_history_state.dart';

class CompletedHistoryViewModel extends ChangeNotifier {
  final BookingRepository _repository = BookingRepository();
  final SupabaseClient _supabase = Supabase.instance.client;

  CompletedHistoryState _state = CompletedHistoryInitial();
  CompletedHistoryState get state => _state;

  String _providerId = '';

  void setProviderId(String id) {
    _providerId = id;
  }

  void _setState(CompletedHistoryState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> loadHistory() async {
    if (_providerId.isEmpty) {
      _setState(CompletedHistoryError('Provider ID not set'));
      return;
    }

    _setState(CompletedHistoryLoading());

    try {
      // Get completed bookings
      final allBookings = await _repository.getProviderBookings(_providerId);
      final completed = allBookings.where((b) =>
      b.status == 'completed' || b.status == 'confirmed'
      ).toList();

      // Fetch ratings for these bookings
      final bookingIds = completed.map((b) => b.id).toList();
      Map<String, Map<String, dynamic>> ratingsMap = {};

      if (bookingIds.isNotEmpty) {
        final ratingsResponse = await _supabase
            .from('ratings')
            .select('booking_id, rating, review')
            .inFilter('booking_id', bookingIds);

        for (var item in ratingsResponse) {
          ratingsMap[item['booking_id']] = {
            'rating': item['rating'],
            'review': item['review'],
          };
        }
      }

      // Combine bookings with ratings
      final completedWithRatings = completed.map((booking) {
        final ratingData = ratingsMap[booking.id];
        return CompletedBookingWithRating(
          booking: booking,
          rating: ratingData?['rating'],
          review: ratingData?['review'],
        );
      }).toList();

      // Calculate total earnings
      int totalEarnings = 0;
      for (var booking in completed) {
        totalEarnings += booking.totalPrice;
      }

      // Get provider rating
      double avgRating = 0;
      try {
        final profile = await _supabase
            .from('provider_profiles')
            .select('rating')
            .eq('user_id', _providerId)
            .maybeSingle();
        avgRating = (profile?['rating'] ?? 0).toDouble();
      } catch (e) {
        avgRating = 0;
      }

      _setState(CompletedHistoryLoaded(
        completedBookings: completedWithRatings,
        averageRating: avgRating,
        totalEarnings: totalEarnings,
      ));
    } catch (e) {
      _setState(CompletedHistoryError(e.toString()));
    }
  }

  void resetError() {
    if (_state is CompletedHistoryError) {
      _setState(CompletedHistoryInitial());
    }
  }
}