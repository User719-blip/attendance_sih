import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import '../core/errors/server_execption.dart';
import '../model/teacher_model.dart';
import 'dart:io';

class AuthService {
  final SupabaseClient _supabaseClient;

  AuthService(this._supabaseClient);

  ///Verify teacher passkey with remote server
  Future<Teacher?> verifyTeacherPasskey(String passkey) async {
    try {
      final response = await _supabaseClient
          .from('teachers')
          .select()
          .eq('passkey', passkey)
          .maybeSingle();

      if (response == null) {
        throw AuthException(message: 'Invalid passkey');
      }

      // Generate token
      final tokenResponse = await _supabaseClient.rpc(
        'generate_teacher_token',
        params: {'teacher_id': response['id'], 'teacher_passkey': passkey},
      );

      final token = tokenResponse as String? ?? '';
      if (token.isEmpty) {
        throw ServerException(message: 'Failed to generate auth token');
      }

      return Teacher(
        id: response['id'].toString(),
        name: response['name'] ?? 'Teacher',
        token: token,
        email: response['email'],
      );
    } on SocketException {
      throw NetworkException(
        message: 'Cannot connect to server. Check your internet connection.',
      );
    } on TimeoutException {
      throw NetworkException(
        message: 'Connection timed out. Please try again.',
      );
    } on PostgrestException catch (e) {
      throw ServerException(message: 'Database error: ${e.message}');
    } on AuthException catch (e) {
      throw e; // Rethrow auth exceptions
    } catch (e) {
      // Log the detailed error for debugging
      print('Unexpected error in verifyTeacherPasskey: $e');
      throw ServerException(
        message: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  /// Verify if token is still valid with server
  Future<bool> verifyToken(String token) async {
    try {
      final response = await _supabaseClient.rpc(
        'verify_teacher_token',
        params: {'token_to_verify': token},
      );

      return response as bool? ?? false;
    } catch (e) {
      return false;
    }
  }
}
