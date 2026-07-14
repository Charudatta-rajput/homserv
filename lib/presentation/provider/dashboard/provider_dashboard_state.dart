import '../../../data/models/booking.dart';

abstract class ProviderDashboardState {}

class ProviderDashboardInitial extends ProviderDashboardState {}

class ProviderDashboardLoading extends ProviderDashboardState {}

class ProviderDashboardLoaded extends ProviderDashboardState {
  final List<Booking> pendingBookings;
  final List<Booking> acceptedBookings;
  final List<Booking> completedBookings;
  final int totalEarnings;
  final double averageRating;

  ProviderDashboardLoaded({
    required this.pendingBookings,
    required this.acceptedBookings,
    required this.completedBookings,
    required this.totalEarnings,
    required this.averageRating,
  });

  int get totalPending => pendingBookings.length;
  int get totalAccepted => acceptedBookings.length;
  int get totalCompleted => completedBookings.length;
}

class ProviderDashboardError extends ProviderDashboardState {
  final String message;
  ProviderDashboardError(this.message);
}


