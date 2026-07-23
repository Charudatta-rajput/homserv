import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/booking.dart';
import '../../../data/models/service.dart';

enum CustomerHomeStateStatus { initial, loading, loaded, error }

class CustomerHomeViewModel extends ChangeNotifier {
  CustomerHomeStateStatus _status = CustomerHomeStateStatus.initial;
  List<Booking> _recentBookings = [];
  List<Service> _searchResults = [];
  String? _errorMessage;

  CustomerHomeStateStatus get status => _status;
  List<Booking> get recentBookings => _recentBookings;
  List<Service> get searchResults => _searchResults;
  String? get errorMessage => _errorMessage;

  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> loadRecentBookings() async {
    _status = CustomerHomeStateStatus.loading;
    notifyListeners();

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        _status = CustomerHomeStateStatus.loaded;
        _recentBookings = [];
        notifyListeners();
        return;
      }

      final response = await _supabase
          .from('bookings')
          .select('''
            id,
            booking_number,
            service:service_id ( name ),
            status,
            total_price,
            created_at,
            scheduled_time
          ''')
          .eq('customer_id', userId)
          .order('created_at', ascending: false)
          .limit(5);

      _recentBookings = (response as List)
          .map((json) => Booking.fromJson(json))
          .toList();
      _status = CustomerHomeStateStatus.loaded;
      _errorMessage = null;
    } catch (e) {
      _status = CustomerHomeStateStatus.error;
      _errorMessage = 'Failed to load recent bookings.';
      debugPrint('Error loading recent bookings: $e');
    }
    notifyListeners();
  }

  // NEW: search services
  Future<void> searchServices(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }
    try {
      final response = await _supabase
          .from('services')
          .select('id, name, fixed_price')
          .ilike('name', '%$query%')
          .limit(5);
      _searchResults = (response as List)
          .map((json) => Service.fromJson(json))
          .toList();
    } catch (e) {
      _searchResults = [];
      debugPrint('Search error: $e');
    }
    notifyListeners();
  }

  void retry() {
    loadRecentBookings();
  }
}