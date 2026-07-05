import '../../../data/models/service.dart';

abstract class ServiceState {}

class ServiceInitial extends ServiceState {}

class ServiceLoading extends ServiceState {}

class ServiceLoaded extends ServiceState {
  final List<Service> services;
  final List<String> categories;
  final String selectedCategory;
  final List<Service> filteredServices;

  ServiceLoaded({
    required this.services,
    required this.categories,
    required this.selectedCategory,
    required this.filteredServices,
  });

  ServiceLoaded copyWith({
    List<Service>? services,
    List<String>? categories,
    String? selectedCategory,
    List<Service>? filteredServices,
  }) {
    return ServiceLoaded(
      services: services ?? this.services,
      categories: categories ?? this.categories,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      filteredServices: filteredServices ?? this.filteredServices,
    );
  }
}

class ServiceError extends ServiceState {
  final String message;
  ServiceError(this.message);
}