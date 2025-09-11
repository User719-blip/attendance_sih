import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  
  @override
  List<Object?> get props => [];
}

class LoginEvent extends AuthEvent {
  final String passkey;
  
  const LoginEvent({required this.passkey});
  
  @override
  List<Object?> get props => [passkey];
}

class LogoutEvent extends AuthEvent {}

class CheckAuthStatusEvent extends AuthEvent {}

class NetworkStatusChangedEvent extends AuthEvent {
  final bool isConnected;
  
  const NetworkStatusChangedEvent({required this.isConnected});
  
  @override
  List<Object?> get props => [isConnected];
}