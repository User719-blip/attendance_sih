import 'package:attendance_app/core/errors/failure.dart';
import 'package:attendance_app/core/errors/server_execption.dart';
import 'package:attendance_app/feature/auth/data/datasources/local_datasource.dart';
import 'package:attendance_app/feature/auth/data/datasources/remote_datasources.dart';
import 'package:attendance_app/feature/auth/data/model/teacher_model.dart';
import 'package:attendance_app/feature/auth/domain/entities/teacher_entities.dart';
import 'package:attendance_app/feature/auth/domain/repo/auth_repo.dart';
import 'package:dartz/dartz.dart';
import 'package:attendance_app/core/network/network_info.dart';

class AuthRepositoryImpl implements  AuthRepository{
 
  final AuthLocalDataSource localDataSource;
  final AuthRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;
  AuthRepositoryImpl({required this.networkInfo,required this.localDataSource, required this.remoteDataSource});

 
  @override
  Future<Either<Failure, Teacher>> loginWithPassskey(String passkey) async {
    final isSetupComplete = await localDataSource.isInitialSetupComplete();
    
    // If first time, require internet
    if (!isSetupComplete) {
      if (await networkInfo.isConnected) {
        try {
          // Verify with server
          final teacher = await remoteDataSource.verifyTeacher(passkey);
          
          // Cache auth data locally
          await localDataSource.cacheAuthData(teacher.token, passkey);
          
          return Right(teacher);
        } on ServerException catch (e) {
          return Left(ServerFailure(message: e.message));
        } catch (e) {
          return Left(ServerFailure(message: e.toString()));
        }
      } else {
        return const Left(NetworkFailure(
          message: 'Internet connection required for initial setup'
        ));
      }
    } 
    else {
      try {
        // Validate passkey against local hash
        final isValid = await localDataSource.validatePasskey(passkey);
        
        if (isValid) {
          // Get cached token
          final token = await localDataSource.getCachedToken();
          
          // Try to sync with server if online, but don't block login if offline
          if (await networkInfo.isConnected) {
            try {
              final teacher = await remoteDataSource.verifyTeacher(passkey);
              // Update cached token if needed
              if (teacher.token != token) {
                await localDataSource.cacheAuthData(teacher.token, passkey);
              }
              return Right(teacher);
            } catch (_) {
              // Failed to sync, but allow offline login with cached data
              return Right(Teacher(
                id: 'cached_id',
                name: 'Teacher',
                token: token,
              ));
            }
          } else {
            // Offline login with cached data
            return Right(Teacher(
              id: 'cached_id',
              name: 'Teacher',
              token: token,
            ));
          }
        } else {
          return const Left(AuthFailure(message: 'Invalid passkey'));
        }
      } on CacheException catch (e) {
        return Left(CacheFailure(message: e.message));
      } catch (e) {
        return Left(CacheFailure(message: e.toString()));
      }
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await localDataSource.clearAuthData();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Teacher?>> checkAuthStatus() async {
    try {
      // Check if we have a valid token
      if (!await localDataSource.isInitialSetupComplete()) {
        return const Right(null); // Not logged in
      }
      
      // Check if token exists
      if (!await localDataSource.hasValidToken()) {
        return const Right(null); // Token expired or missing
      }
      
      // Get cached teacher data
      final token = await localDataSource.getCachedToken();
      final teacher = TeacherModel(
        id: await localDataSource.getCachedTeacherId(),
        name: await localDataSource.getCachedTeacherName(),
        token: token,
      );
      
      // If online, verify token with server
      if (await networkInfo.isConnected) {
        try {
          final isValid = await remoteDataSource.verifyToken(token);
          if (!isValid) {
            await localDataSource.clearAuthData();
            return const Right(null); // Token invalid according to server
          }
        } catch (_) {
          // Server error, but we still use cached data
        }
      }
      
      return Right(teacher);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }
}

