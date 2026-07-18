import 'package:flutter/material.dart';
import '../../../data/repositories/user_repository.dart';
import 'profile_state.dart';

class ProfileViewModel extends ChangeNotifier {
  final UserRepository _repository = UserRepository();

  ProfileState _state = ProfileInitial();
  ProfileState get state => _state;

  String _userId = '';

  void setUserId(String userId) {
    _userId = userId;
  }

  void _setState(ProfileState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> loadProfile() async {
    if (_userId.isEmpty) {
      _setState(ProfileError('User ID not set'));
      return;
    }

    _setState(ProfileLoading());

    try {
      final user = await _repository.getUser(_userId);
      _setState(ProfileLoaded(user));
    } catch (e) {
      _setState(ProfileError(e.toString()));
    }
  }

  Future<void> updateProfile({
    String? name,
    String? address,
    double? latitude,
    double? longitude,
  }) async {
    if (_userId.isEmpty) {
      _setState(ProfileError('User ID not set'));
      return;
    }

    try {
      final updatedUser = await _repository.updateUser(
        userId: _userId,
        name: name,
        address: address,
        latitude: latitude,
        longitude: longitude,
      );

      _setState(ProfileLoaded(updatedUser));
    } catch (e) {
      _setState(ProfileError(e.toString()));
    }
  }

  void resetError() {
    if (_state is ProfileError) {
      _setState(ProfileInitial());
    }
  }

  void resetState() {
    _setState(ProfileInitial());
  }
}