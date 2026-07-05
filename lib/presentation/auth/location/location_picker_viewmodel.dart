import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'location_picker_state.dart';

class LocationPickerViewModel extends ChangeNotifier {
  LocationPickerState _state = LocationPickerInitial();
  LocationPickerState get state => _state;

  GoogleMapController? mapController;
  LatLng _selectedLocation = const LatLng(28.6139, 77.2090);

  List<Map<String, dynamic>> _predictions = [];
  List<Map<String, dynamic>> get predictions => _predictions;

  Timer? _debounce;

  LatLng get selectedLocation => _selectedLocation;
  String _address = '';

  final String apiKey = 'AIzaSyDbKp-S4rHN2JMF957SEwfzmigjcf-Ik0g';

  void _setState(LocationPickerState newState) {
    _state = newState;
    notifyListeners();
  }

  // Autocomplete search using direct API call
  void searchAutocomplete(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();

    if (query.isEmpty) {
      _predictions = [];
      notifyListeners();
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      await _fetchPredictions(query);
    });
  }

  Future<void> _fetchPredictions(String query) async {
    try {
      final url = Uri.parse(
          'https://maps.googleapis.com/maps/api/place/autocomplete/json'
              '?input=$query'
              '&key=$apiKey'
              '&components=country:in'
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          _predictions = List<Map<String, dynamic>>.from(data['predictions']);
          notifyListeners();
        } else {
          _predictions = [];
          notifyListeners();
        }
      } else {
        _predictions = [];
        notifyListeners();
      }
    } catch (e) {
      _predictions = [];
      notifyListeners();
    }
  }

  // Select place from autocomplete
  Future<void> selectPlace(Map<String, dynamic> prediction) async {
    _setState(LocationPickerLoading());

    try {
      final placeId = prediction['place_id'];
      final url = Uri.parse(
          'https://maps.googleapis.com/maps/api/place/details/json'
              '?place_id=$placeId'
              '&key=$apiKey'
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final location = data['result']['geometry']['location'];
          final lat = location['lat'];
          final lng = location['lng'];

          _selectedLocation = LatLng(lat, lng);
          _address = prediction['description'] ?? '';

          await mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(_selectedLocation, 16),
          );

          _setState(LocationPickerLoaded(
            address: _address,
            latitude: lat,
            longitude: lng,
          ));

          _predictions = [];
          notifyListeners();
        }
      }
    } catch (e) {
      _setState(LocationPickerError(e.toString()));
    }
  }

  // Fetch current location
  Future<void> fetchCurrentLocation() async {
    _setState(LocationPickerLoading());

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setState(LocationPickerLoaded(
          address: 'Please enable GPS, then tap the location button',
          latitude: _selectedLocation.latitude,
          longitude: _selectedLocation.longitude,
        ));
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _setState(LocationPickerLoaded(
            address: 'Location permission denied. Tap on map to select.',
            latitude: _selectedLocation.latitude,
            longitude: _selectedLocation.longitude,
          ));
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _setState(LocationPickerLoaded(
          address: 'Location permission denied. Tap on map to select.',
          latitude: _selectedLocation.latitude,
          longitude: _selectedLocation.longitude,
        ));
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 10),
      );

      _selectedLocation = LatLng(position.latitude, position.longitude);

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        List<String> addressParts = [];
        if (place.street != null && place.street!.isNotEmpty) addressParts.add(place.street!);
        if (place.subLocality != null && place.subLocality!.isNotEmpty) addressParts.add(place.subLocality!);
        if (place.locality != null && place.locality!.isNotEmpty) addressParts.add(place.locality!);
        if (place.postalCode != null && place.postalCode!.isNotEmpty) addressParts.add(place.postalCode!);
        _address = addressParts.isNotEmpty ? addressParts.join(', ') : '${position.latitude}, ${position.longitude}';
      } else {
        _address = '${position.latitude}, ${position.longitude}';
      }

      await mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_selectedLocation, 16),
      );

      _setState(LocationPickerLoaded(
        address: _address,
        latitude: position.latitude,
        longitude: position.longitude,
      ));
    } catch (e) {
      _setState(LocationPickerLoaded(
        address: 'Tap on map to select your location',
        latitude: _selectedLocation.latitude,
        longitude: _selectedLocation.longitude,
      ));
    }
  }

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
    fetchCurrentLocation();
  }

  void onMapTapped(LatLng latLng) async {
    _selectedLocation = latLng;
    _setState(LocationPickerLoading());

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        List<String> addressParts = [];
        if (place.street != null && place.street!.isNotEmpty) addressParts.add(place.street!);
        if (place.subLocality != null && place.subLocality!.isNotEmpty) addressParts.add(place.subLocality!);
        if (place.locality != null && place.locality!.isNotEmpty) addressParts.add(place.locality!);
        if (place.postalCode != null && place.postalCode!.isNotEmpty) addressParts.add(place.postalCode!);
        _address = addressParts.isNotEmpty ? addressParts.join(', ') : '${latLng.latitude}, ${latLng.longitude}';
      } else {
        _address = '${latLng.latitude}, ${latLng.longitude}';
      }

      await mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(latLng, 16),
      );

      _setState(LocationPickerLoaded(
        address: _address,
        latitude: latLng.latitude,
        longitude: latLng.longitude,
      ));
    } catch (e) {
      _setState(LocationPickerLoaded(
        address: '${latLng.latitude}, ${latLng.longitude}',
        latitude: latLng.latitude,
        longitude: latLng.longitude,
      ));
    }
  }

  void resetError() {
    if (_state is LocationPickerError) {
      _setState(LocationPickerInitial());
    }
  }

  Future<void> refreshLocation() async {
    await fetchCurrentLocation();
  }

  void clearPredictions() {
    _predictions = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}