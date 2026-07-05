abstract class ProviderSignupState {}

class ProviderSignupInitial extends ProviderSignupState {}

class ProviderSignupLoading extends ProviderSignupState {}

class ProviderSignupSuccess extends ProviderSignupState {
  final String message;
  ProviderSignupSuccess(this.message);
}

class ProviderSignupError extends ProviderSignupState {
  final String message;
  ProviderSignupError(this.message);
}

// Document data class
class DocumentData {
  final String path;
  final String url;
  DocumentData({required this.path, required this.url});
}