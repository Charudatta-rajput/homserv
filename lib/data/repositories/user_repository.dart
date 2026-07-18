import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../models/user.dart';

class UserRepository {
  final supabase.SupabaseClient _supabase = supabase.Supabase.instance.client;

  Future<User> getUser(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();
      return User.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch user: $e');
    }
  }

  Future<User> updateUser({
    required String userId,
    String? name,
    String? phone,
    String? email,
    String? address,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final Map<String, dynamic> updates = {};
      if (name != null) updates['name'] = name;
      if (phone != null) updates['phone'] = phone;
      if (email != null) updates['email'] = email;
      if (address != null) updates['address'] = address;
      if (latitude != null) updates['location_lat'] = latitude;
      if (longitude != null) updates['location_lng'] = longitude;

      final response = await _supabase
          .from('users')
          .update(updates)
          .eq('id', userId)
          .select()
          .single();

      return User.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }
}