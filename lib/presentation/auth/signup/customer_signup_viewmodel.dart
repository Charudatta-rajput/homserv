import 'package:flutter/material.dart';
import '../../../data/repositories/auth_repositories.dart';
import 'customer_signup_state.dart';

class CustomerSignupViewModel extends ChangeNotifier {
  final AuthRepository _repository = AuthRepository();

  CustomerSignupState _state = CustomerSignupInitial();
  CustomerSignupState get state => _state;

  void _setState(CustomerSignupState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> signup({
    required String name,
    required String phone,
    required String email,
    required String password,
    required String address,
    required double latitude,
    required double longitude,
  }) async {
    _setState(CustomerSignupLoading());

    try {
      await _repository.customerSignup(
        name: name,
        phone: phone,
        email: email,
        password: password,
        address: address,
        latitude: latitude,
        longitude: longitude,
      );

      _setState(CustomerSignupSuccess('Account created successfully! Please login.'));
    } catch (e) {
      _setState(CustomerSignupError(e.toString()));
    }
  }

  void resetError() {
    if (_state is CustomerSignupError) {
      _setState(CustomerSignupInitial());
    }
  }
}