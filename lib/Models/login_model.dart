// lib/models/login_model.dart
import 'dart:convert';

class LoginModel {
  final String? email;
  final String? password;
  final String? device_id;

  LoginModel({this.email, this.password, this.device_id});

  // Method to convert the object to a JSON map for API requests
  Map<String, dynamic> toJson() {
    return {'login_id': email, 'password': password, "device_id": device_id};
  }
}

// Helper function to decode the JSON string if needed,
// though the example assumes the input is a Map<String, dynamic>
UserModel userModelFromJson(String str) => UserModel.fromJson(json.decode(str));

// Optional: Function to encode the model back to JSON
String userModelToJson(UserModel data) => json.encode(data.toJson());

class UserModel {
  // Fields for the User object
  final int id;
  final String username;
  final String email;
  final String? deviceId; // Marked as nullable in case it's not always present

  // Fields for the Authentication Token
  final String accessToken;
  final String tokenType;
  final String message;

  UserModel({
    required this.message,
    required this.id,
    required this.username,
    required this.email,
    this.deviceId,
    required this.accessToken,
    required this.tokenType,
  });

  /// Factory constructor to create a UserModel instance from a JSON map.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Extract the nested 'user' map
    final userMap = json['user'] as Map<String, dynamic>;

    return UserModel(
      message: json['message'] as String,
      // Extract properties from the nested 'user' map
      id: userMap['id'] as int,
      username: userMap['username'] as String,
      email: userMap['email'] as String,
      deviceId:
          userMap['device_id']
              as String?, // Note: using '?' handles nullability
      // Extract properties from the main JSON object
      accessToken: json['access_token'] as String,
      tokenType: json['token_type'] as String,
    );
  }

  /// Convert the UserModel instance back into a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'user': {
        'id': id,
        'username': username,
        'email': email,
        'device_id': deviceId,
      },
      'access_token': accessToken,
      'token_type': tokenType,
    };
  }

  @override
  String toString() {
    return 'UserModel(id: $id, username: $username, email: $email, accessToken: $accessToken)';
  }
}
