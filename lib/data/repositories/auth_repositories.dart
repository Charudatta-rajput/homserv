import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../models/user.dart';

class AuthRepository {
  final supabase.SupabaseClient _supabase = supabase.Supabase.instance.client;

  // ==================== CUSTOMER METHODS ====================

  Future<User> customerLogin(String email, String password) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw Exception('Login failed');
    }

    // Get user data from users table
    final userData = await _supabase
        .from('users')
        .select()
        .eq('id', response.user!.id)
        .single();

    return User.fromJson(userData);
  }

  Future<User> customerSignup({
    required String name,
    required String phone,
    required String email,
    required String password,
    String? address,
    double? latitude,
    double? longitude,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'name': name, 'role': 'customer'},
    );

    if (response.user == null) {
      throw Exception('Signup failed');
    }

    // Insert into users table
    await _supabase.from('users').insert({
      'id': response.user!.id,
      'name': name,
      'phone': phone,
      'email': email,
      'role': 'customer',
      'address': address,
      'location_lat': latitude,
      'location_lng': longitude,
    });

    return User(
      id: response.user!.id,
      name: name,
      email: email,
      phone: phone,
      role: 'customer',
      address: address,
      latitude: latitude,
      longitude: longitude,
    );
  }

  // ==================== PROVIDER METHODS ====================

  Future<User> providerLogin(String email, String password) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw Exception('Login failed');
    }

    // Get user data from users table
    final userData = await _supabase
        .from('users')
        .select()
        .eq('id', response.user!.id)
        .single();

    return User.fromJson(userData);
  }

  Future<Map<String, dynamic>> providerSignup({
    required String name,
    required String phone,
    required String email,
    required String password,
    required String address,
    required double latitude,
    required double longitude,
    required String trade,
    required int experience,
    String? aadharUrl,
    String? itiUrl,
    String? policeUrl,
  }) async {
    // 1. Create auth user
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'name': name, 'role': 'provider'},
    );

    if (response.user == null) {
      throw Exception('Failed to create account');
    }

    final userId = response.user!.id;

    // 2. Insert into users table
    await _supabase.from('users').insert({
      'id': userId,
      'name': name,
      'phone': phone,
      'email': email,
      'role': 'provider',
      'address': address,
      'location_lat': latitude,
      'location_lng': longitude,
    });

    // 3. Insert into provider_profiles table
    await _supabase.from('provider_profiles').insert({
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

    return {
      'id': userId,
      'email': email,
      'name': name,
    };
  }


  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  Future<String?> getCurrentUserRole() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final response = await _supabase
        .from('users')
        .select('role')
        .eq('id', user.id)
        .maybeSingle();

    return response?['role'];
  }
}