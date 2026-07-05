abstract class LocationPickerState {}

class LocationPickerInitial extends LocationPickerState {}

class LocationPickerLoading extends LocationPickerState {}

class LocationPickerLoaded extends LocationPickerState {
  final String address;
  final double latitude;
  final double longitude;

  LocationPickerLoaded({
    required this.address,
    required this.latitude,
    required this.longitude,
  });
}

class LocationPickerError extends LocationPickerState {
  final String message;
  LocationPickerError(this.message);
}