// lib/services/api_service.dart

import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../Models/login_model.dart';
import '../Models/signup_model.dart';

class ApiService extends GetxService {
  final String baseUrl = "https://your-api-url.com/api";

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

  Future<SignupResponseModel> signupWithEmail(
    SignupRequestModel request,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/signup'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(request.toJson()),
    );
    if (response.statusCode == 200) {
      return SignupResponseModel.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to sign up');
    }
  }
}
