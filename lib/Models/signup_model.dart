// lib/models/signup_model.dart

class SignupRequestModel {
  final String fullName;
  final String email;
  final String password;

  SignupRequestModel({
    required this.fullName,
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {'fullName': fullName, 'email': email, 'password': password};
  }
}

class SignupResponseModel {
  final String token;
  final String message;

  SignupResponseModel({required this.token, required this.message});

  factory SignupResponseModel.fromJson(Map<String, dynamic> json) {
    return SignupResponseModel(token: json['token'], message: json['message']);
  }
}
