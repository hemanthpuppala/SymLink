import 'package:equatable/equatable.dart';
import '../repositories/auth_repository.dart';

enum AuthStatus {
  unknown,
  authenticated,
  unauthenticated,
}

class AuthState extends Equatable {
  final AuthStatus status;
  final Consumer? consumer;
  final String? error;
  final bool isLoading;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.consumer,
    this.error,
    this.isLoading = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    Consumer? consumer,
    String? error,
    bool? isLoading,
  }) {
    return AuthState(
      status: status ?? this.status,
      consumer: consumer ?? this.consumer,
      error: error,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [status, consumer, error, isLoading];
}
