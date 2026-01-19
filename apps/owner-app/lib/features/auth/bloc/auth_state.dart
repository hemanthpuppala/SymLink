import 'package:equatable/equatable.dart';
import '../repositories/auth_repository.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
}

class AuthState extends Equatable {
  final AuthStatus status;
  final Owner? owner;
  final String? error;

  const AuthState({
    this.status = AuthStatus.initial,
    this.owner,
    this.error,
  });

  AuthState copyWith({
    AuthStatus? status,
    Owner? owner,
    String? error,
  }) {
    return AuthState(
      status: status ?? this.status,
      owner: owner ?? this.owner,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, owner, error];
}
