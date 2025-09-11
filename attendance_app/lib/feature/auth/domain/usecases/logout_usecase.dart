import 'package:attendance_app/core/errors/failure.dart';
import 'package:attendance_app/core/usecase/usecases.dart';
import 'package:attendance_app/feature/auth/domain/repo/auth_repo.dart';
import 'package:dartz/dartz.dart';


class Logout implements UseCase<void, NoParams> {
  final AuthRepository repository;
  
  Logout(this.repository);
  
  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    return await repository.logout();
  }
}