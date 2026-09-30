class User {
  final String email;
  final String token;

  const User({required this.email, required this.token});

  factory User.fromJson(Map<String, dynamic> json) => User(
        email: json['email'] as String,
        token: json['token'] as String,
      );

  Map<String, dynamic> toJson() => {
        'email': email,
        'token': token,
      };
}