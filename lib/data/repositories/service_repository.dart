import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/service.dart';

class ServiceRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all active services
  Future<List<Service>> getAllServices() async {
    try {
      final response = await _supabase
          .from('services')
          .select('*')
          .eq('is_active', true)
          .order('category', ascending: true);

      return (response as List).map((json) => Service.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch services: $e');
    }
  }

  // Get services by category
  Future<List<Service>> getServicesByCategory(String category) async {
    try {
      final response = await _supabase
          .from('services')
          .select('*')
          .eq('is_active', true)
          .eq('category', category)
          .order('name', ascending: true);

      return (response as List).map((json) => Service.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch services: $e');
    }
  }

  // Get all unique categories
  Future<List<String>> getCategories() async {
    try {
      final response = await _supabase
          .from('services')
          .select('category')
          .eq('is_active', true);

      final categories = (response as List)
          .map((json) => json['category'] as String)
          .toSet()
          .toList();

      return categories;
    } catch (e) {
      throw Exception('Failed to fetch categories: $e');
    }
  }
}