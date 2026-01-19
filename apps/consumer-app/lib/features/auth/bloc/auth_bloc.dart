import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthState()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthRegisterRequested>(_onAuthRegisterRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    final isAuthenticated = await _authRepository.isAuthenticated();
    emit(state.copyWith(
      status: isAuthenticated
          ? AuthStatus.authenticated
          : AuthStatus.unauthenticated,
    ));
  }

  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      final consumer = await _authRepository.login(
        email: event.email,
        password: event.password,
      );
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        consumer: consumer,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        error: e.toString(),
        isLoading: false,
      ));
    }
  }

  Future<void> _onAuthRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      final consumer = await _authRepository.register(
        email: event.email,
        password: event.password,
        name: event.name,
        phone: event.phone,
      );
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        consumer: consumer,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        error: e.toString(),
        isLoading: false,
      ));
    }
  }

  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.logout();
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }
}
