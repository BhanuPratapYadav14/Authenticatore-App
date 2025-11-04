// The Main Model
class ValidationModel {
  final String message;
  final String status;
  final User user;
  final String tokenName;

  ValidationModel({
    required this.message,
    required this.status,
    required this.user,
    required this.tokenName,
  });

  // Factory constructor to create a HomePageModel from a JSON map
  factory ValidationModel.fromJson(Map<String, dynamic> json) {
    return ValidationModel(
      message: json['message'] as String,
      status: json['status'] as String,
      // Map the nested 'user' object to the User model
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      tokenName: json['token_name'] as String,
    );
  }

  // Optional: Convert the model back to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'status': status,
      'user': user.toJson(),
      'token_name': tokenName,
    };
  }
}

// The Nested User Model
class User {
  final int id;
  final String username;
  final String email;
  final String lastLoginDevice;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.lastLoginDevice,
  });

  // Factory constructor to create a User from a JSON map
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      username: json['username'] as String,
      email: json['email'] as String,
      lastLoginDevice: json['last_login_device'] as String,
    );
  }

  // Optional: Convert the model back to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'last_login_device': lastLoginDevice,
    };
  }
}
