import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/repositories/provider_repository.dart';
import '../../../data/models/provider.dart';
import 'provider_list_state.dart';

class ProviderListViewModel extends ChangeNotifier {
  final ProviderRepository _repository = ProviderRepository();

  ProviderListState _state = ProviderListInitial();
  ProviderListState get state => _state;

  Position? _currentPosition;
  Position? get currentPosition => _currentPosition;

  String? _locationError;
  String? get locationError => _locationError;

  void _setState(ProviderListState newState) {
    _state = newState;
    notifyListeners();
  }

  // Get customer's current location (GPS first, fallback to saved)
  Future<bool> getCustomerLocation() async {
    try {
      // Try GPS first
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 10),
          );
          _currentPosition = position;
          _locationError = null;
          return true;
        }
      }

      // Fallback: Get saved location from users table
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final response = await Supabase.instance.client
            .from('users')
            .select('location_lat, location_lng')
            .eq('id', user.id)
            .maybeSingle();

        if (response != null &&
            response['location_lat'] != null &&
            response['location_lng'] != null) {
          _currentPosition = Position(
            latitude: (response['location_lat'] as num).toDouble(),
            longitude: (response['location_lng'] as num).toDouble(),
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            heading: 0,
            speed: 0,
            speedAccuracy: 0,
            altitudeAccuracy: 0,
            headingAccuracy: 0,
          );
          _locationError = null;
          return true;
        }
      }

      _locationError = 'Location not available. Please update your address.';
      return false;
    } catch (e) {
      _locationError = 'Failed to get location: ${e.toString()}';
      return false;
    }
  }

  // Load providers
  Future<void> loadProviders({
    required String serviceId,
    required String serviceName,
    required int radius,
  }) async {
    _setState(ProviderListLoading());

    try {
      // Get location first
      final hasLocation = await getCustomerLocation();
      if (!hasLocation || _currentPosition == null) {
        _setState(ProviderListError(_locationError ?? 'Location not available'));
        return;
      }

      final providers = await _repository.getProvidersByTrade(
        trade: serviceName,
        customerLat: _currentPosition!.latitude,
        customerLng: _currentPosition!.longitude,
        radiusInKm: radius,
      );

      _setState(ProviderListLoaded(
        providers: providers,
        serviceName: serviceName,
        radius: radius,
      ));
    } catch (e) {
      _setState(ProviderListError(e.toString()));
    }
  }

  void resetError() {
    if (_state is ProviderListError) {
      _setState(ProviderListInitial());
    }
  }
}