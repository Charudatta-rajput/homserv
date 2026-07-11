import '../../../data/models/provider.dart';

abstract class ProviderListState {}

class ProviderListInitial extends ProviderListState {}

class ProviderListLoading extends ProviderListState {}

class ProviderListLoaded extends ProviderListState {
  final List<Provider> providers;
  final String serviceName;
  final int radius;

  ProviderListLoaded({
    required this.providers,
    required this.serviceName,
    required this.radius,
  });
}

class ProviderListError extends ProviderListState {
  final String message;
  ProviderListError(this.message);
}