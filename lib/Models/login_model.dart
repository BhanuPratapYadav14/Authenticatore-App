// lib/models/login_model.dart

class LoginModel {
  final String? email;
  final String? password;
  final String? socialToken;

  LoginModel({this.email, this.password, this.socialToken});

  // Method to convert the object to a JSON map for API requests
  Map<String, dynamic> toJson() {
    return {'email': email, 'password': password, 'socialToken': socialToken};
  }
}

class UserModel {
  final String id;
  final String email;
  final String name;
  final String? profilePicture;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.profilePicture,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      profilePicture: json['profilePicture'],
    );
  }
}
