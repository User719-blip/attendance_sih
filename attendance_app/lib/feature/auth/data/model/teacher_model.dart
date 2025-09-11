import 'package:attendance_app/feature/auth/domain/entities/teacher_entities.dart';



class TeacherModel extends Teacher {
  const TeacherModel({
    required super.id,
    required super.name,
    required super.token,
    super.role, super.email,
  });
  
  factory TeacherModel.fromJson(Map<String, dynamic> json) {
    return TeacherModel(
       id: json['id'],
      name: json['name'],
      token: json['token'],
      email: json['email'],
      role: json['role'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'token': token,
      'email': email,
      'role': role,
    };
  }
}