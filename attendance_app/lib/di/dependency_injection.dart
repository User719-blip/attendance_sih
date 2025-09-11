import 'package:attendance_app/feature/auth/data/datasources/local_datasource.dart';
import 'package:attendance_app/feature/auth/data/datasources/remote_datasources.dart';
import 'package:attendance_app/feature/auth/data/repo/repo_impl.dart';
import 'package:attendance_app/feature/auth/domain/repo/auth_repo.dart';
import 'package:attendance_app/feature/auth/domain/usecases/checkAuthStatus.dart';
import 'package:attendance_app/feature/auth/domain/usecases/loginWithPassKey_usecase.dart';
import 'package:attendance_app/feature/auth/domain/usecases/logout_usecase.dart';
import 'package:attendance_app/feature/auth/presentation/bloc/auth_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/network/network_info.dart';
final sl = GetIt.instance;

Future<void> init() async {
  // External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton(() => http.Client());
  sl.registerLazySingleton(() => Connectivity());
  sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);

  // Core
  sl.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(connectivity: sl()),
  );

  // Data sources
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(sharedPreferences: sl()),
  );
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(supabaseClient: sl()),
  );

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => LoginWithPasskey(sl()));
  sl.registerLazySingleton(() => Logout(sl()));
  sl.registerLazySingleton(() => CheckAuthStatus(sl()));

  // BLoCs
  sl.registerFactory(
    () => AuthBloc(
      loginWithPasskey: sl(),
      logout: sl(),
      checkAuthStatus: sl(),
      networkInfo: sl(),
    ),
  );
}
