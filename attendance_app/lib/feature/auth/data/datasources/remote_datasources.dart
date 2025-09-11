import 'package:attendance_app/core/errors/server_execption.dart';
import 'package:attendance_app/feature/auth/data/model/teacher_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


abstract class AuthRemoteDataSource {
  /// Verifies teacher credentials with server
  Future<TeacherModel> verifyTeacher(String passkey);
  
  /// Verifies if a token is still valid
  Future<bool> verifyToken(String token);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient supabaseClient;
  
  AuthRemoteDataSourceImpl({
    required this.supabaseClient,
  });
  
  @override
  Future<TeacherModel> verifyTeacher(String passkey) async {
    try {
      // First, check if this is a teacher's passkey in the database
      final response = await supabaseClient
          .from('teachers')
          .select()
          .eq('passkey', passkey)
          .single();
      
      if (response == null) {
        throw ServerException(message: 'Invalid passkey');
      }
      
      // Get a session token
      final tokenResponse = await supabaseClient
          .rpc('generate_teacher_token', params: {
            'teacher_id': response['id'],
            'teacher_passkey': passkey,
          });
          
      final token = tokenResponse as String? ?? '';
      
      if (token.isEmpty) {
        throw ServerException(message: 'Failed to generate auth token');
      }
      
      // Return the teacher model with token
      return TeacherModel(
        id: response['id'].toString(),
        name: response['name'],
        token: token,
        email: response['email'],
        role: response['role'],
      );
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }
  
  @override
  Future<bool> verifyToken(String token) async {
    try {
      final response = await supabaseClient
          .rpc('verify_teacher_token', params: {
            'token_to_verify': token,
          });
      
      return response as bool? ?? false;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }
}