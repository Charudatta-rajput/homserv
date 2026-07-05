import 'package:flutter/material.dart';
import '../../../data/repositories/booking_repository.dart';
import '../../../data/models/booking.dart';
import 'my_bookings_state.dart';

class MyBookingsViewModel extends ChangeNotifier {
  final BookingRepository _repository = BookingRepository();

  MyBookingsState _state = MyBookingsInitial();
  MyBookingsState get state => _state;

  String _customerId = '';

  void setCustomerId(String customerId) {
    _customerId = customerId;
  }

  void _setState(MyBookingsState newState) {
    _state = newState;
    notifyListeners();
  }

  // Load bookings
  Future<void> loadBookings() async {
    if (_customerId.isEmpty) {
      _setState(MyBookingsError('Customer ID not set'));
      return;
    }

    _setState(MyBookingsLoading());

    try {
      final bookings = await _repository.getCustomerBookings(_customerId);

      _setState(MyBookingsLoaded(
        bookings: bookings,
        filteredBookings: bookings,
        selectedFilter: 'All',
      ));
    } catch (e) {
      _setState(MyBookingsError(e.toString()));
    }
  }

  // Filter bookings by status
  void filterByStatus(String status) {
    if (_state is MyBookingsLoaded) {
      final currentState = _state as MyBookingsLoaded;

      List<Booking> filtered;
      if (status == 'All') {
        filtered = currentState.bookings;
      } else {
        filtered = currentState.bookings
            .where((b) => b.status == status)
            .toList();
      }

      _setState(currentState.copyWith(
        filteredBookings: filtered,
        selectedFilter: status,
      ));
    }
  }

  // Cancel booking
  Future<void> cancelBooking(String bookingId) async {
    try {
      await _repository.cancelBooking(bookingId);
      await loadBookings();
    } catch (e) {
      _setState(MyBookingsError(e.toString()));
    }
  }

  // Confirm booking
  Future<void> confirmBooking(String bookingId) async {
    try {
      await _repository.confirmBooking(bookingId);
      await loadBookings();
    } catch (e) {
      _setState(MyBookingsError(e.toString()));
    }
  }

  // Rate booking
  Future<void> rateBooking({
    required String bookingId,
    required int rating,
    String? review,
  }) async {
    try {
      await _repository.rateBooking(
        bookingId: bookingId,
        rating: rating,
        review: review,
      );
      await loadBookings();
    } catch (e) {
      _setState(MyBookingsError(e.toString()));
    }
  }

  void resetError() {
    if (_state is MyBookingsError) {
      _setState(MyBookingsInitial());
    }
  }
}