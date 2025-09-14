part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class signUpRequest extends AuthEvent {
  final String email;
  final String password;

  const signUpRequest({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}

class signInRequest extends AuthEvent {
  final String email;
  final String password;

  const signInRequest({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}

class ProfileSetupCompleted extends AuthEvent {
  const ProfileSetupCompleted();
}

class SignOutRequested extends AuthEvent {
  const SignOutRequested();
}

class ResetPasswordRequested extends AuthEvent {
  final String email;

  const ResetPasswordRequested({required this.email});

  @override
  List<Object> get props => [email];
}
