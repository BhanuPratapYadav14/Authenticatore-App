// lib/models/signup_model.dart

class SignupRequestModel {
  final String fullName;
  final String email;
  final String password;
  final String confirmPassword;
  final String device_ID;

  SignupRequestModel({
    required this.fullName,
    required this.email,
    required this.password,
    required this.confirmPassword,
    required this.device_ID,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': fullName,
      'email': email,
      'password': password,
      "password_confirmation": confirmPassword,
      "device_id": device_ID,
    };
  }
}

// 1. The Main Response Model
class SignUpResponseModel {
  final String message;
  final String status;
  final SignUpUser user; // Nested User object
  final String accessToken;
  final String tokenType;

  SignUpResponseModel({
    required this.message,
    required this.status,
    required this.user,
    required this.accessToken,
    required this.tokenType,
  });

  // Factory method to deserialize JSON to the model
  factory SignUpResponseModel.fromJson(Map<String, dynamic> json) {
    return SignUpResponseModel(
      message: json['message'] as String,
      status: json['status'] as String,
      // Deserialize the nested 'user' map using the SignUpUser model
      user: SignUpUser.fromJson(json['user'] as Map<String, dynamic>),
      accessToken: json['access_token'] as String,
      tokenType: json['token_type'] as String,
    );
  }

  // Method to serialize the model back to JSON (for debugging/caching)
  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'user': user.toJson(),
      'access_token': accessToken,
      'token_type': tokenType,
    };
  }
}

// 2. The Nested User Model
class SignUpUser {
  final int id;
  final String username;
  final String email;
  final String deviceId;

  SignUpUser({
    required this.id,
    required this.username,
    required this.email,
    required this.deviceId,
  });

  // Factory method to deserialize JSON to the user model
  factory SignUpUser.fromJson(Map<String, dynamic> json) {
    return SignUpUser(
      id: json['id'] as int,
      username: json['username'] as String,
      email: json['email'] as String,
      // Note the key 'device_id' from the JSON
      deviceId: json['device_id'] as String,
    );
  }

  // Method to serialize the user model back to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'device_id': deviceId,
    };
  }
}
