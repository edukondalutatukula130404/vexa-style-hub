class UserModel {
  final String id;
  final String name;
  final String companyName;
  final String email;
  final String role;
  final String? token;
  final String? avatarUrl;

  UserModel({
    required this.id,
    required this.name,
    this.companyName = 'VEXA Style Hub',
    required this.email,
    required this.role,
    this.token,
    this.avatarUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, {String? token}) {
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? 'User',
      companyName: json['companyName'] ?? json['company'] ?? 'VEXA Style Hub',
      email: json['email'] ?? '',
      role: json['role'] ?? 'user',
      token: token ?? json['token'],
      avatarUrl: json['avatarUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'companyName': companyName,
      'email': email,
      'role': role,
      'token': token,
      'avatarUrl': avatarUrl,
    };
  }
}
