class Teacher {
  final String id;
  final String name;
  final String token;
  final String? email;
  final String? role;
  
  Teacher({
    required this.id, 
    required this.name, 
    required this.token, 
    this.email,
    this.role = 'teacher',
  });

  factory Teacher.fromJson(Map<String, dynamic> json) {
    return Teacher(
      id: json['id'] as String,
      name: json['name'] as String,
      token: json['token'] as String,
      email: json['email'] as String?,
      role: json['role'] as String? ?? 'teacher',
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