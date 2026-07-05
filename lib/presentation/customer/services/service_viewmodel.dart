import 'package:flutter/material.dart';
import '../../../data/repositories/service_repository.dart';
import '../../../data/models/service.dart';
import 'service_state.dart';

class ServiceViewModel extends ChangeNotifier {
  final ServiceRepository _repository = ServiceRepository();

  ServiceState _state = ServiceInitial();
  ServiceState get state => _state;

  void _setState(ServiceState newState) {
    _state = newState;
    notifyListeners();
  }

  // Load all services
  Future<void> loadServices() async {
    _setState(ServiceLoading());

    try {
      final services = await _repository.getAllServices();
      final categories = await _repository.getCategories();

      if (services.isEmpty) {
        _setState(ServiceError('No services available'));
        return;
      }

      // Select first category by default
      final defaultCategory = categories.isNotEmpty ? categories.first : '';

      _setState(ServiceLoaded(
        services: services,
        categories: categories,
        selectedCategory: defaultCategory,
        filteredServices: services.where((s) => s.category == defaultCategory).toList(),
      ));
    } catch (e) {
      _setState(ServiceError(e.toString()));
    }
  }

  // Filter services by category
  void filterByCategory(String category) {
    if (_state is ServiceLoaded) {
      final currentState = _state as ServiceLoaded;

      final filtered = currentState.services
          .where((service) => service.category == category)
          .toList();

      _setState(currentState.copyWith(
        selectedCategory: category,
        filteredServices: filtered,
      ));
    }
  }

  // Refresh services
  Future<void> refreshServices() async {
    await loadServices();
  }

  void resetError() {
    if (_state is ServiceError) {
      _setState(ServiceInitial());
    }
  }
}