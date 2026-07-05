abstract class CustomerLoginState {}

class CustomerLoginInitial extends CustomerLoginState {}

class CustomerLoginLoading extends CustomerLoginState {}

class CustomerLoginSuccess extends CustomerLoginState {
  final String userId;
  final String email;
  CustomerLoginSuccess({required this.userId, required this.email});
}

class CustomerLoginError extends CustomerLoginState {
  final String message;
  CustomerLoginError(this.message);
}