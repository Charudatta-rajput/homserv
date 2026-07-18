import '../../../data/models/complaint.dart';

abstract class ComplaintState {}

class ComplaintInitial extends ComplaintState {}

class ComplaintLoading extends ComplaintState {}

class ComplaintLoaded extends ComplaintState {
  final List<Complaint> complaints;
  ComplaintLoaded(this.complaints);
}

class ComplaintError extends ComplaintState {
  final String message;
  ComplaintError(this.message);
}

// For raising complaint
class RaiseComplaintLoading extends ComplaintState {}

class RaiseComplaintSuccess extends ComplaintState {
  final Complaint complaint;
  RaiseComplaintSuccess(this.complaint);
}

// For bookings dropdown
class BookingsLoaded extends ComplaintState {
  final List<Map<String, dynamic>> bookings;
  BookingsLoaded(this.bookings);
}