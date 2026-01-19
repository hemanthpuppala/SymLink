import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthState()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthProfileRequested>(_onProfileRequested);
  }

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      final isAuthenticated = await _authRepository.isAuthenticated();
      if (isAuthenticated) {
        final owner = await _authRepository.getProfile();
        emit(state.copyWith(
          status: AuthStatus.authenticated,
          owner: owner,
        ));
      } else {
        emit(state.copyWith(status: AuthStatus.unauthenticated));
      }
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, error: null));
    try {
      final owner = await _authRepository.login(
        email: event.email,
        password: event.password,
      );
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        owner: owner,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        error: _parseError(e),
      ));
    }
  }

  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, error: null));
    try {
      final owner = await _authRepository.register(
        email: event.email,
        password: event.password,
        name: event.name,
        phone: event.phone,
      );
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        owner: owner,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        error: _parseError(e),
      ));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.logout();
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  Future<void> _onProfileRequested(
    AuthProfileRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final owner = await _authRepository.getProfile();
      if (owner != null) {
        emit(state.copyWith(owner: owner));
      }
    } catch (e) {
      // Silently fail for profile refresh
    }
  }

  String _parseError(dynamic error) {
    final errorStr = error.toString();
    if (errorStr.contains('401')) {
      return 'Invalid email or password';
    }
    if (errorStr.contains('409')) {
      return 'Email already registered';
    }
    if (errorStr.contains('400')) {
      return 'Invalid input. Please check your details.';
    }
    if (errorStr.contains('network')) {
      return 'Network error. Please check your connection.';
    }
    return 'Something went wrong. Please try again.';
  }
}
