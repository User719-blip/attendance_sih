import 'package:equatable/equatable.dart';

class Teacher extends Equatable {
  final String id;
  final String name;
  final String token;
  final String? email;
  final String? role;

  const Teacher({
    required this.id,
    required this.name,
    required this.token,
    this.role, this.email, 
  });

  @override
  List<Object> get props => [id, name, token, ?email, ?role];
}
