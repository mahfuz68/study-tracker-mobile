class User {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? shareToken;
  final String createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.shareToken,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'USER',
      shareToken: json['shareToken'],
      createdAt: json['createdAt'] ?? '',
    );
  }

  bool get isAdmin => role == 'ADMIN';

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
      };
}
