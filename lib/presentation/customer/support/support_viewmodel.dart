import 'package:flutter/material.dart';
import 'package:homserv/presentation/customer/support/support_state.dart';
import '../../../data/repositories/complaint_repository.dart';
import '../../../data/models/complaint.dart';


class ComplaintViewModel extends ChangeNotifier {
  final ComplaintRepository _repository = ComplaintRepository();

  ComplaintState _state = ComplaintInitial();
  ComplaintState get state => _state;

  String _userId = '';

  void setUserId(String userId) {
    _userId = userId;
  }

  void _setState(ComplaintState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> loadComplaints() async {
    if (_userId.isEmpty) {
      _setState(ComplaintError('User ID not set'));
      return;
    }

    _setState(ComplaintLoading());

    try {
      final complaints = await _repository.getUserComplaints(_userId);
      _setState(ComplaintLoaded(complaints));
    } catch (e) {
      _setState(ComplaintError(e.toString()));
    }
  }

  Future<void> loadBookings() async {
    if (_userId.isEmpty) return;

    try {
      final bookings = await _repository.getUserCompletedBookings(_userId);
      _setState(BookingsLoaded(bookings));
    } catch (e) {
      // Ignore error
    }
  }

  Future<void> raiseComplaint({
    required String reason,
    String? bookingId,
    List<String>? evidencePhotos,
  }) async {
    _setState(RaiseComplaintLoading());

    try {
      final complaint = await _repository.createComplaint(
        raisedBy: _userId,
        reason: reason,
        bookingId: bookingId,
        evidencePhotos: evidencePhotos,
      );
      _setState(RaiseComplaintSuccess(complaint));
    } catch (e) {
      _setState(ComplaintError(e.toString()));
    }
  }

  void resetError() {
    if (_state is ComplaintError) {
      _setState(ComplaintInitial());
    }
  }

  void resetState() {
    _setState(ComplaintInitial());
  }
}