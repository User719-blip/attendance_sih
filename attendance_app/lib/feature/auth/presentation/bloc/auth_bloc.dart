import 'dart:async';
import 'package:attendance_app/core/usecase/usecases.dart';
import 'package:attendance_app/feature/auth/domain/usecases/checkAuthStatus.dart';
import 'package:attendance_app/feature/auth/domain/usecases/loginWithPassKey_usecase.dart';
import 'package:attendance_app/feature/auth/domain/usecases/logout_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/network_info.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginWithPasskey loginWithPasskey;
  final Logout logout;
  final CheckAuthStatus checkAuthStatus;
  final NetworkInfo networkInfo;
  late StreamSubscription<bool> _networkSubscription;
  
  AuthBloc({
    required this.loginWithPasskey,
    required this.logout,
    required this.checkAuthStatus,
    required this.networkInfo,
  }) : super(const AuthInitial(isOnline: false)) {
    on<LoginEvent>(_onLogin);
    on<LogoutEvent>(_onLogout);
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<NetworkStatusChangedEvent>(_onNetworkStatusChanged);
    
    // Listen to network changes
    _networkSubscription = networkInfo.connectionChanges.listen((isConnected) {
      add(NetworkStatusChangedEvent(isConnected: isConnected));
    });
    
    // Initialize by checking network status and auth status
    _init();
  }
  
  Future<void> _init() async {
    final isOnline = await networkInfo.isConnected;
    add(NetworkStatusChangedEvent(isConnected: isOnline));
    add(CheckAuthStatusEvent());
  }
  
  Future<void> _onLogin(LoginEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    
    final isOnline = await networkInfo.isConnected;
    final result = await loginWithPasskey(Params(passkey: event.passkey));
    
    result.fold(
      (failure) => emit(AuthFailure(message: failure.message, isOnline: isOnline)),
      (teacher) => emit(AuthSuccess(teacher: teacher, isOnline: isOnline)),
    );
  }
  
  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    
    final isOnline = await networkInfo.isConnected;
    final result = await logout(NoParams());
    
    result.fold(
      (failure) => emit(AuthFailure(message: failure.message, isOnline: isOnline)),
      (_) => emit(AuthInitial(isOnline: isOnline)),
    );
  }
  
  Future<void> _onCheckAuthStatus(
    CheckAuthStatusEvent event, 
    Emitter<AuthState> emit
  ) async {
    emit(AuthLoading());
    
    final isOnline = await networkInfo.isConnected;
    final result = await checkAuthStatus(NoParams());
    
    result.fold(
      (failure) => emit(AuthFailure(message: failure.message, isOnline: isOnline)),
      (teacher) {
        if (teacher != null) {
          emit(AuthSuccess(teacher: teacher, isOnline: isOnline));
        } else {
          emit(AuthInitial(isOnline: isOnline));
        }
      },
    );
  }
  
  Future<void> _onNetworkStatusChanged(
    NetworkStatusChangedEvent event, 
    Emitter<AuthState> emit
  ) async {
    final currentState = state;
    
    if (currentState is AuthInitial) {
      emit(AuthInitial(isOnline: event.isConnected));
    } else if (currentState is AuthSuccess) {
      emit(AuthSuccess(
        teacher: currentState.teacher,
        isOnline: event.isConnected,
      ));
    } else if (currentState is AuthFailure) {
      emit(AuthFailure(
        message: currentState.message,
        isOnline: event.isConnected,
      ));
    }
    
    // If we're online and were previously logged in, sync with server
    if (event.isConnected && currentState is AuthSuccess) {
      add(CheckAuthStatusEvent());
    }
  }
  
  @override
  Future<void> close() {
    _networkSubscription.cancel();
    return super.close();
  }
}