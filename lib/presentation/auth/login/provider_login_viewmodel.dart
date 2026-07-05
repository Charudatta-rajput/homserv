import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'provider_login_state.dart';

class ProviderLoginViewModel extends ChangeNotifier {
  ProviderLoginState _state = ProviderLoginInitial();
  ProviderLoginState get state => _state;

  void _setState(ProviderLoginState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    // Validation
    if (email.isEmpty) {
      _setState(ProviderLoginError('Please enter email'));
      return;
    }
    if (password.isEmpty) {
      _setState(ProviderLoginError('Please enter password'));
      return;
    }

    _setState(ProviderLoginLoading());

    try {
      // Sign in with Supabase
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email.trim(),
        password: password.trim(),
      );

      if (response.user == null) {
        _setState(ProviderLoginError('Login failed'));
        return;
      }

      final userId = response.user!.id;

      // Check user role from database
      final userData = await Supabase.instance.client
          .from('users')
          .select('role')
          .eq('id', userId)
          .maybeSingle();

      final role = userData?['role'] ?? '';

      if (role != 'provider') {
        await Supabase.instance.client.auth.signOut();
        _setState(ProviderLoginError('This account is not a provider account'));
        return;
      }

      // Get provider profile for verification status
      final providerData = await Supabase.instance.client
          .from('provider_profiles')
          .select('verification_status')
          .eq('user_id', userId)
          .maybeSingle();

      final verificationStatus = providerData?['verification_status'] ?? 'pending';

      _setState(ProviderLoginSuccess(
        userId: userId,
        email: email.trim(),
        verificationStatus: verificationStatus,
      ));
    } catch (e) {
      _setState(ProviderLoginError(e.toString()));
    }
  }

  void resetError() {
    if (_state is ProviderLoginError) {
      _setState(ProviderLoginInitial());
    }
  }

  void resetState() {
    _setState(ProviderLoginInitial());
  }
}