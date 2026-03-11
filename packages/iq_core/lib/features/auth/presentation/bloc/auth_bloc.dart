import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/auth_service.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/send_otp_usecase.dart';
import '../../domain/usecases/verify_otp_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// Auth BLoC - handles authentication flow
/// Shared between Passenger & Driver apps
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SendOtpUseCase sendOtpUseCase;
  final VerifyOtpUseCase verifyOtpUseCase;
  final RegisterUseCase registerUseCase;
  final LogoutUseCase logoutUseCase;
  final AuthRepository repository;
  final AuthService _authService;

  late final StreamSubscription<UnauthorizedEvent> _unauthorizedSub;

  AuthBloc({
    required this.sendOtpUseCase,
    required this.verifyOtpUseCase,
    required this.registerUseCase,
    required this.logoutUseCase,
    required this.repository,
    required AuthService authService,
  })  : _authService = authService,
        super(const AuthInitial()) {
    on<AuthSendOtpEvent>(_onSendOtp);
    on<AuthVerifyOtpEvent>(_onVerifyOtp);
    on<AuthResendOtpEvent>(_onResendOtp);
    on<AuthRegisterEvent>(_onRegister);
    on<AuthLogoutEvent>(_onLogout);
    on<AuthCheckStatusEvent>(_onCheckStatus);
    on<AuthUnauthorizedEvent>(_onUnauthorized);

    // Listen to 401 events from the API interceptor
    _unauthorizedSub = _authService.unauthorizedStream.listen((_) {
      add(const AuthUnauthorizedEvent());
    });
  }

  @override
  Future<void> close() {
    _unauthorizedSub.cancel();
    return super.close();
  }

  Future<void> _onSendOtp(
    AuthSendOtpEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await sendOtpUseCase(
      SendOtpParams(phone: event.phone, role: event.role),
    );
    result.fold(
      (failure) {
        if (failure is RegistrationRedirectFailure) {
          emit(AuthNeedsRegistration(
            phone: event.phone,
            whatsappLink: failure.whatsappLink,
            displayMessage: failure.displayMessage,
          ));
        } else if (failure.message == 'needs_registration') {
          emit(AuthNeedsRegistration(phone: event.phone));
        } else {
          emit(AuthError(message: failure.message));
        }
      },
      (_) => emit(AuthOtpSent(phone: event.phone)),
    );
  }

  Future<void> _onVerifyOtp(
    AuthVerifyOtpEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await verifyOtpUseCase(
      VerifyOtpParams(phone: event.phone, otp: event.otp, role: event.role),
    );
    result.fold(
      (failure) {
        // Route "needs_registration" to the correct state
        if (failure.message == 'needs_registration') {
          emit(AuthNeedsRegistration(phone: event.phone));
        } else {
          emit(AuthError(message: failure.message));
        }
      },
      (user) => emit(AuthAuthenticated(user: user)),
    );
  }

  Future<void> _onResendOtp(
    AuthResendOtpEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await sendOtpUseCase(
      SendOtpParams(phone: event.phone, role: event.role),
    );
    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (_) => emit(AuthOtpResent(phone: event.phone)),
    );
  }

  Future<void> _onRegister(
    AuthRegisterEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await registerUseCase(
      RegisterParams(
        name: event.name,
        phone: event.phone,
        email: event.email,
        gender: event.gender,
        role: event.role,
      ),
    );
    result.fold(
      (failure) {
        if (failure.message == 'needs_otp') {
          // Registration succeeded but OTP verification is required.
          emit(AuthOtpSent(phone: event.phone));
        } else {
          emit(AuthError(message: failure.message));
        }
      },
      (user) => emit(AuthAuthenticated(user: user)),
    );
  }

  Future<void> _onLogout(
    AuthLogoutEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await logoutUseCase(const NoParams());
    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (_) => emit(const AuthUnauthenticated()),
    );
  }

  Future<void> _onCheckStatus(
    AuthCheckStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final loginResult = await repository.isLoggedIn();

    await loginResult.fold(
      (failure) async => emit(const AuthUnauthenticated()),
      (isLoggedIn) async {
        if (!isLoggedIn) {
          emit(const AuthUnauthenticated());
          return;
        }

        // Token exists → try fetching cached user
        final userResult = await repository.getCachedUser();
        userResult.fold(
          (_) => emit(const AuthUnauthenticated()),
          (user) => emit(AuthAuthenticated(user: user)),
        );
      },
    );
  }

  /// Handle 401 Unauthorized response by triggering logout
  Future<void> _onUnauthorized(
    AuthUnauthorizedEvent event,
    Emitter<AuthState> emit,
  ) async {
    // Immediately logout without showing loading state
    final result = await logoutUseCase(const NoParams());

    // CRITICAL: Reset the refreshing flag so new requests (login) are not
    // queued forever. Also clear any pending request queue.
    _authService.setRefreshing(false);
    _authService.clearQueue();

    result.fold(
      (failure) => emit(const AuthUnauthenticated()),
      (_) => emit(const AuthUnauthenticated()),
    );
  }
}
