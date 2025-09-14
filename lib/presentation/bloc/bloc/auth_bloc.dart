import 'package:baatein/data/repositories/auth_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(AuthUnauthenticated()) {
    on<signUpRequest>(_onSignUpRequest);
    on<ProfileSetupCompleted>(_onProfileSetupCompleted);
  }

  Future<void> _onSignUpRequest(
    signUpRequest event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final user = await authRepository.registerWithEmailAndPassword(
        event.email,
        event.password,
      );

      if (user != null) {
        // New users need to set up their profile
        emit(AuthNeedsProfileSetup(userId: user.uid));
      } else {
        emit(
          const AuthError(message: 'Registration failed. Please try again.'),
        );
      }
    } catch (e) {
      emit(AuthError(message: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onProfileSetupCompleted(
    ProfileSetupCompleted event,
    Emitter<AuthState> emit,
  ) async {
    final user = authRepository.currentUser;
    if (user != null) {
      emit(AuthAuthenticated(userId: user.uid));
    }
  }
}
