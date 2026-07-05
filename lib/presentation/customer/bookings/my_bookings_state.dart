import '../../../data/models/booking.dart';

abstract class MyBookingsState {}

class MyBookingsInitial extends MyBookingsState {}

class MyBookingsLoading extends MyBookingsState {}

class MyBookingsLoaded extends MyBookingsState {
  final List<Booking> bookings;
  final List<Booking> filteredBookings;
  final String selectedFilter;

  MyBookingsLoaded({
    required this.bookings,
    required this.filteredBookings,
    required this.selectedFilter,
  });

  MyBookingsLoaded copyWith({
    List<Booking>? bookings,
    List<Booking>? filteredBookings,
    String? selectedFilter,
  }) {
    return MyBookingsLoaded(
      bookings: bookings ?? this.bookings,
      filteredBookings: filteredBookings ?? this.filteredBookings,
      selectedFilter: selectedFilter ?? this.selectedFilter,
    );
  }
}

class MyBookingsError extends MyBookingsState {
  final String message;
  MyBookingsError(this.message);
}