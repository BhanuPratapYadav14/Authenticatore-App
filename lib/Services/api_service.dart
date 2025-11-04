// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Models/login_model.dart';
import '../Models/signup_model.dart';

final String baseUrl = "http://192.168.0.4:8000/api";

Future<UserModel> loginWithCredentials(LoginModel loginData) async {
  final response = await http.post(
    Uri.parse('$baseUrl/login'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(loginData.toJson()),
  );

  if (response.statusCode == 200) {
    return UserModel.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to log in');
  }
}

Future<http.Response> signupWithEmail(SignupRequestModel request) async {
  final response = await http.post(
    Uri.parse('$baseUrl/signUp'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(request.toJson()),
  );
  return response;
}

Future<http.Response> validateUser(String Accesstoken) async {
  final response = await http.get(
    Uri.parse('$baseUrl/home'),
    headers: {"Authorization": "Bearer $Accesstoken"},
  );
  return response;
}
