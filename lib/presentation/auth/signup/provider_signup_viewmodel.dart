import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'provider_signup_state.dart';

class ProviderSignupViewModel extends ChangeNotifier {
  ProviderSignupState _state = ProviderSignupInitial();
  ProviderSignupState get state => _state;

  // Image files
  XFile? _aadharImage;
  XFile? _itiImage;
  XFile? _policeImage;

  XFile? get aadharImage => _aadharImage;
  XFile? get itiImage => _itiImage;
  XFile? get policeImage => _policeImage;

  void _setState(ProviderSignupState newState) {
    _state = newState;
    notifyListeners();
  }

  // Pick image from gallery
  Future<void> pickImage(String type, {ImageSource source = ImageSource.gallery}) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source);

    if (image != null) {
      if (type == 'aadhar') {
        _aadharImage = image;
      } else if (type == 'iti') {
        _itiImage = image;
      } else if (type == 'police') {
        _policeImage = image;
      }
      notifyListeners();
    }
  }

  // Remove image
  void removeImage(String type) {
    if (type == 'aadhar') {
      _aadharImage = null;
    } else if (type == 'iti') {
      _itiImage = null;
    } else if (type == 'police') {
      _policeImage = null;
    }
    notifyListeners();
  }

  // Upload image to Supabase Storage - FIXED VERSION
  Future<String?> _uploadImage(XFile image, String userId, String docType) async {
    try {
      // Convert XFile to File
      final file = File(image.path);
      final filePath = '$userId/$docType.jpg';

      debugPrint('Uploading to: providers/$filePath');
      debugPrint('File size: ${await file.length()} bytes');

      // Upload the File directly
      await Supabase.instance.client.storage
          .from('provider_documents')
          .upload(filePath, file, fileOptions: const FileOptions(
        cacheControl: '3600',
        upsert: true,
      ));

      // Get public URL
      final url = Supabase.instance.client.storage
          .from('provider_documents')
          .getPublicUrl(filePath);

      debugPrint('Upload successful: $url');
      return url;
    } catch (e) {
      debugPrint('Upload error for $docType: $e');
      return null;
    }
  }

  // Complete provider registration
  Future<void> registerProvider({
    required String name,
    required String phone,
    required String email,
    required String password,
    required String address,
    required double latitude,
    required double longitude,
    required String trade,
    required int experience,
  }) async {
    _setState(ProviderSignupLoading());

    try {
      // 1. Create auth user FIRST
      final authResponse = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {'name': name, 'role': 'provider'},
      );

      if (authResponse.user == null) {
        throw Exception('Failed to create account');
      }

      final userId = authResponse.user!.id;
      debugPrint('User created with ID: $userId');

      // 2. Upload documents AFTER user is created
      String? aadharUrl;
      String? itiUrl;
      String? policeUrl;

      if (_aadharImage != null) {
        aadharUrl = await _uploadImage(_aadharImage!, userId, 'aadhar');
      }

      if (_itiImage != null) {
        itiUrl = await _uploadImage(_itiImage!, userId, 'iti_certificate');
      }

      if (_policeImage != null) {
        policeUrl = await _uploadImage(_policeImage!, userId, 'police_verification');
      }

      // 3. Insert into users table
      await Supabase.instance.client.from('users').insert({
        'id': userId,
        'name': name,
        'phone': phone,
        'email': email,
        'role': 'provider',
        'address': address,
        'location_lat': latitude,
        'location_lng': longitude,
      });
      debugPrint('User inserted into users table');

      // 4. Insert into provider_profiles table
      await Supabase.instance.client.from('provider_profiles').insert({
        'user_id': userId,
        'trade': trade,
        'experience_years': experience,
        'verification_status': 'pending',
        'aadhar_url': aadharUrl,
        'iti_certificate_url': itiUrl,
        'police_verification_url': policeUrl,
        'rating': 0,
        'total_jobs_completed': 0,
        'is_active': true,
      });
      debugPrint('Provider profile inserted');

      _setState(ProviderSignupSuccess('Registration submitted! Awaiting admin verification.'));
    } catch (e) {
      debugPrint('Registration error: $e');
      _setState(ProviderSignupError(e.toString()));
    }
  }

  void resetError() {
    if (_state is ProviderSignupError) {
      _setState(ProviderSignupInitial());
    }
  }

  void resetState() {
    _setState(ProviderSignupInitial());
  }
}