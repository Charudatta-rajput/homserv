abstract class ProviderLoginState {}

class ProviderLoginInitial extends ProviderLoginState {}

class ProviderLoginLoading extends ProviderLoginState {}

class ProviderLoginSuccess extends ProviderLoginState {
  final String userId;
  final String email;
  final String verificationStatus;

  ProviderLoginSuccess({
    required this.userId,
    required this.email,
    required this.verificationStatus,
  });
}

class ProviderLoginError extends ProviderLoginState {
  final String message;
  ProviderLoginError(this.message);
}