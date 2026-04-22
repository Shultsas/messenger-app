class User {
  final int id;
  final String username;
  final String? passwordHash;  // 👈 Делаем nullable
  final String? token;         // 👈 Делаем nullable

  User({
    required this.id,
    required this.username,
    this.passwordHash,         // 👈 Не required
    this.token,                // 👈 Не required
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      passwordHash: json['passwordHash'],
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'passwordHash': passwordHash,
      'token': token,
    };
  }
}