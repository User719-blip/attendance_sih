// filepath: lib/features/authentication/domain/usecases/check_auth_status.dart
import 'package:attendance_app/core/errors/failure.dart';
import 'package:attendance_app/core/usecase/usecases.dart';
import 'package:attendance_app/feature/auth/domain/entities/teacher_entities.dart';
import 'package:attendance_app/feature/auth/domain/repo/auth_repo.dart';
import 'package:dartz/dartz.dart';

class CheckAuthStatus implements UseCase<Teacher?, NoParams> {
  final AuthRepository repository;
  
  CheckAuthStatus(this.repository);
  
  @override
  Future<Either<Failure, Teacher?>> call(NoParams params) async {
    return await repository.checkAuthStatus();
  }
}