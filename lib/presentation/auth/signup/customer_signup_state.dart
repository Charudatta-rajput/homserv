abstract class CustomerSignupState {}

class CustomerSignupInitial extends CustomerSignupState {}

class CustomerSignupLoading extends CustomerSignupState {}

class CustomerSignupSuccess extends CustomerSignupState {
  final String message;
  CustomerSignupSuccess(this.message);
}

class CustomerSignupError extends CustomerSignupState {
  final String message;
  CustomerSignupError(this.message);
}

// Location data to pass between screens
class LocationData {
  final String address;
  final double latitude;
  final double longitude;

  LocationData({
    required this.address,
    required this.latitude,
    required this.longitude,
  });
}