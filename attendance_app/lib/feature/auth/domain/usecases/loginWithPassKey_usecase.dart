import 'package:attendance_app/core/errors/failure.dart';
import 'package:attendance_app/core/usecase/usecases.dart';
import 'package:attendance_app/feature/auth/domain/entities/teacher_entities.dart';
import 'package:attendance_app/feature/auth/domain/repo/auth_repo.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class LoginWithPasskey implements UseCase<Teacher, Params> {
  final AuthRepository repository;
  
  LoginWithPasskey(this.repository);
  
  @override
  Future<Either<Failure, Teacher>> call(Params params) async {
    return await repository.loginWithPassskey(params.passkey);
  }
}

class Params extends Equatable {
  final String passkey;
  
  const Params({required this.passkey});
  
  @override
  List<Object> get props => [passkey];
}