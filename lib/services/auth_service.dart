// services/auth_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

final String baseUrl = Platform.isAndroid
    ? 'http://${dotenv.env['BASE_URL']}:8001'
    : 'http://localhost:8001';

class AuthService {
  //로그인 서비스
  Future<bool> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/login'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password.trim()}),
    );
    debugPrint("응답 본문: ${response.body}");
    if (response.statusCode == 200) {
      //로그인 성공
      final data = json.decode(response.body);

      final token = data["token"]; //토큰 저장
      final user = data["user"]; //유저 정보 저장

      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("token", token); //토큰
        await prefs.setString("userId", user["_id"] ?? ""); //유저 오브젝트 아이디
        await prefs.setString("userName", user["name"] ?? ""); //유저 네임
        await prefs.setString(
            "userEmail", user["email"] ?? email); //유저 이메일 추가 저장
      }
      return true;
    } else {
      return false; // 로그인 실패
    }
  }

// 회원가입 API
  Future<bool> register(
      String name, String email, String password, DateTime birthdate) async {
    String formattedBirthdate =
        DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'").format(birthdate);
    final response = await http.post(
      Uri.parse('$baseUrl/api/register'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "name": name,
        "email": email,
        "password": password,
        "birthdate": formattedBirthdate,
      }),
    );

    debugPrint("[회원가입 요청] 서버 응답 코드: ${response.statusCode}");
    debugPrint("[회원가입 요청] 서버 응답 본문: ${response.body}");

    if (response.statusCode == 201) {
      return true;
    } else {
      debugPrint("서버 응답 본문: ${response.body}");
      return false;
    }
  }

  // 회원탈퇴 API
  Future<Map<String, dynamic>> deactivate(
      String userId, String password) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/$userId/deactivate'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"password": password}),
      );

      debugPrint("🗑️ [회원탈퇴 요청] 서버 응답 코드: ${response.statusCode}");
      debugPrint("🗑️ [회원탈퇴 요청] 서버 응답 본문: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? '회원탈퇴가 완료되었습니다.',
        };
      } else {
        final data = json.decode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? '회원탈퇴에 실패했습니다.',
        };
      }
    } catch (e) {
      debugPrint("❌ 회원탈퇴 중 오류: $e");
      return {
        'success': false,
        'message': '네트워크 오류가 발생했습니다.',
      };
    }
  }
}
