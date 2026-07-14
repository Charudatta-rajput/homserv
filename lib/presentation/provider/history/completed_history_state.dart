import '../../../data/models/booking.dart';

class CompletedBookingWithRating {
  final Booking booking;
  final int? rating;
  final String? review;

  CompletedBookingWithRating({
    required this.booking,
    this.rating,
    this.review,
  });
}

abstract class CompletedHistoryState {}

class CompletedHistoryInitial extends CompletedHistoryState {}

class CompletedHistoryLoading extends CompletedHistoryState {}

class CompletedHistoryLoaded extends CompletedHistoryState {
  final List<CompletedBookingWithRating> completedBookings;
  final double averageRating;
  final int totalEarnings;

  CompletedHistoryLoaded({
    required this.completedBookings,
    required this.averageRating,
    required this.totalEarnings,
  });
}

class CompletedHistoryError extends CompletedHistoryState {
  final String message;
  CompletedHistoryError(this.message);
}