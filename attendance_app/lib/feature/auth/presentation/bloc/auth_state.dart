import 'package:attendance_app/feature/auth/domain/entities/teacher_entities.dart';
import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  final bool isOnline;
  
  const AuthInitial({required this.isOnline});
  
  @override
  List<Object?> get props => [isOnline];
}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final Teacher teacher;
  final bool isOnline;
  
  const AuthSuccess({
    required this.teacher,
    required this.isOnline,
  });
  
  @override
  List<Object?> get props => [teacher, isOnline];
}

class AuthFailure extends AuthState {
  final String message;
  final bool isOnline;
  
  const AuthFailure({
    required this.message,
    required this.isOnline,
  });
  
  @override
  List<Object?> get props => [message, isOnline];
}