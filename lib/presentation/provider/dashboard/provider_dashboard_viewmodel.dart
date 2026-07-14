import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/booking.dart';
import '../../../data/repositories/booking_repository.dart';
import 'provider_dashboard_state.dart';

class ProviderDashboardViewModel extends ChangeNotifier {
  final BookingRepository _repository = BookingRepository();

  ProviderDashboardState _state = ProviderDashboardInitial();
  ProviderDashboardState get state => _state;

  String _providerId = '';
  String get providerId => _providerId;

  void setProviderId(String id) {
    _providerId = id;
  }

  void _setState(ProviderDashboardState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> loadDashboard() async {
    if (_providerId.isEmpty) {
      _setState(ProviderDashboardError('Provider ID not set'));
      return;
    }

    _setState(ProviderDashboardLoading());

    try {
      // Get all bookings for this provider
      final allBookings = await _repository.getProviderBookings(_providerId);

      // Separate by status
      final pending = allBookings.where((b) => b.status == 'pending').toList();
      final accepted = allBookings.where((b) => b.status == 'accepted' || b.status == 'in_progress').toList();
      final completed = allBookings.where((b) => b.status == 'completed' || b.status == 'confirmed').toList();

      // Calculate earnings (from completed bookings)
      int totalEarnings = 0;
      for (var booking in completed) {
        totalEarnings += booking.totalPrice;
      }

      // Get provider rating
      double avgRating = 0;
      try {
        final profile = await Supabase.instance.client
            .from('provider_profiles')
            .select('rating')
            .eq('user_id', _providerId)
            .maybeSingle();
        avgRating = (profile?['rating'] ?? 0).toDouble();
      } catch (e) {
        avgRating = 0;
      }

      _setState(ProviderDashboardLoaded(
        pendingBookings: pending,
        acceptedBookings: accepted,
        completedBookings: completed,
        totalEarnings: totalEarnings,
        averageRating: avgRating,
      ));
    } catch (e) {
      _setState(ProviderDashboardError('Failed to load dashboard: ${e.toString()}'));
    }
  }

  Future<void> acceptBooking(String bookingId) async {
    try {
      await _repository.acceptBooking(bookingId);
      await loadDashboard();
    } catch (e) {
      _setState(ProviderDashboardError('Failed to accept booking: ${e.toString()}'));
    }
  }

  Future<void> rejectBooking(String bookingId) async {
    try {
      await _repository.rejectBooking(bookingId);
      await loadDashboard();
    } catch (e) {
      _setState(ProviderDashboardError('Failed to reject booking: ${e.toString()}'));
    }
  }

  Future<void> completeBooking(String bookingId) async {
    try {
      await _repository.completeBooking(bookingId);
      await loadDashboard();
    } catch (e) {
      _setState(ProviderDashboardError('Failed to complete booking: ${e.toString()}'));
    }
  }



  void resetError() {
    if (_state is ProviderDashboardError) {
      _setState(ProviderDashboardInitial());
    }
  }
}