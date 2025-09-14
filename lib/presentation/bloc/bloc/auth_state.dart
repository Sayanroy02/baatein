part of 'auth_bloc.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

final class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {
  @override
  List<Object> get props => [];
}

class AuthUnauthenticated extends AuthState {
  @override
  List<Object> get props => [];
}

class AuthNeedsProfileSetup extends AuthState {
  final String userId;

  const AuthNeedsProfileSetup({required this.userId});

  @override
  List<Object> get props => [userId];
}

class AuthAuthenticated extends AuthState {
  final String userId;
  final UserModel user;

  const AuthAuthenticated({required this.userId, required this.user});

  @override
  List<Object> get props => [userId, user];
}

class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object> get props => [message];
}

class AuthPasswordResetSent extends AuthState {
  const AuthPasswordResetSent();

  @override
  List<Object> get props => [];
}
