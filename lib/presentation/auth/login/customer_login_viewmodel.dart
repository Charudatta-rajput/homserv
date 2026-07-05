import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'customer_login_state.dart';

class CustomerLoginViewModel extends ChangeNotifier {
  CustomerLoginState _state = CustomerLoginInitial();
  CustomerLoginState get state => _state;

  void _setState(CustomerLoginState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    // Validation
    if (email.isEmpty) {
      _setState(CustomerLoginError('Please enter email'));
      return;
    }
    if (password.isEmpty) {
      _setState(CustomerLoginError('Please enter password'));
      return;
    }

    _setState(CustomerLoginLoading());

    try {
      // Sign in with Supabase
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email.trim(),
        password: password.trim(),
      );

      if (response.user == null) {
        _setState(CustomerLoginError('Login failed'));
        return;
      }

      // Check user role from database
      final userData = await Supabase.instance.client
          .from('users')
          .select('role')
          .eq('id', response.user!.id)
          .maybeSingle();

      final role = userData?['role'] ?? 'customer';

      if (role != 'customer') {
        await Supabase.instance.client.auth.signOut();
        _setState(CustomerLoginError('This account is not a customer account'));
        return;
      }

      _setState(CustomerLoginSuccess(
        userId: response.user!.id,
        email: email.trim(),
      ));
    } catch (e) {
      _setState(CustomerLoginError(e.toString()));
    }
  }

  void resetError() {
    if (_state is CustomerLoginError) {
      _setState(CustomerLoginInitial());
    }
  }

  void resetState() {
    _setState(CustomerLoginInitial());
  }
}