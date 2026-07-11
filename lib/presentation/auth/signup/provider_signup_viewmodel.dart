import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'provider_signup_state.dart';
import '../../../data/repositories/service_repository.dart';
import '../../../data/models/service.dart';

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

  // Services
  final ServiceRepository _serviceRepository = ServiceRepository();
  List<Service> _availableServices = [];
  List<Service> get availableServices => _availableServices;
  bool _servicesLoading = false;
  bool get servicesLoading => _servicesLoading;

  void _setState(ProviderSignupState newState) {
    _state = newState;
    notifyListeners();
  }
// In loadServices() method
  Future<void> loadServices() async {
    _servicesLoading = true;
    notifyListeners();

    try {
      _availableServices = await _serviceRepository.getAllServices();
      print('✅ Services loaded: ${_availableServices.length}');  // Debug
      print('📋 Services: ${_availableServices.map((s) => s.name).toList()}');  // Debug
    } catch (e) {
      print('❌ Error loading services: $e');  // Debug
    } finally {
      _servicesLoading = false;
      notifyListeners();
    }
  }

  // Pick image from gallery or camera
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

  // Upload image to Supabase Storage
  Future<String?> _uploadImage(XFile image, String userId, String docType) async {
    try {
      final file = File(image.path);
      final filePath = 'providers/$userId/$docType.jpg';

      await Supabase.instance.client.storage
          .from('provider_documents')
          .upload(filePath, file, fileOptions: const FileOptions(
        cacheControl: '3600',
        upsert: true,
      ));

      final url = Supabase.instance.client.storage
          .from('provider_documents')
          .getPublicUrl(filePath);

      return url;
    } catch (e) {
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
      // 1. Create auth user
      final authResponse = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {'name': name, 'role': 'provider'},
      );

      if (authResponse.user == null) {
        throw Exception('Failed to create account');
      }

      final userId = authResponse.user!.id;

      // 2. Upload documents
      final aadharUrl = _aadharImage != null
          ? await _uploadImage(_aadharImage!, userId, 'aadhar')
          : null;

      final itiUrl = _itiImage != null
          ? await _uploadImage(_itiImage!, userId, 'iti_certificate')
          : null;

      final policeUrl = _policeImage != null
          ? await _uploadImage(_policeImage!, userId, 'police_verification')
          : null;

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

      _setState(ProviderSignupSuccess('Registration submitted! Awaiting admin verification.'));
    } catch (e) {
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