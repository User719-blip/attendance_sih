import 'package:attendance_app/core/errors/failure.dart';
import 'package:attendance_app/feature/auth/domain/entities/teacher_entities.dart';
import 'package:dartz/dartz.dart';

abstract class AuthRepository {
  Future<Either<Failure, Teacher>> loginWithPassskey(String passkey);
  Future<Either<Failure, void>> logout();
  Future<Either<Failure, Teacher?>> checkAuthStatus();
}
