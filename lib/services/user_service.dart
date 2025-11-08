// services/user_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

final String baseUrl = Platform.isAndroid
    ? 'http://${dotenv.env['BASE_URL']}:8001'
    : 'http://localhost:8001';

class UserService {
  Future<List<String>> fetchUserKeywords(String userId) async {
    final response =
        await http.get(Uri.parse('$baseUrl/users/$userId/keywords'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseBody = json.decode(response.body);
      final List<dynamic> fetchedKeywords = responseBody['keywords'];
      return fetchedKeywords.map((k) => k['name'].toString()).toList();
    } else {
      throw Exception('🚨 사용자 키워드 불러오기 실패: ${response.statusCode}');
    }
  }

  // 사용자 정보 가져오기 (Shared Preference)
  Future<Map<String, String?>> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      debugPrint("SharedPreferences에서 토큰을 찾을 수 없음");
      return {};
    }

    final userId = prefs.getString('userId');
    final userName = prefs.getString('userName');

    debugPrint("loadUserData(): userId=$userId, userName=$userName");

    return {
      'userId': userId,
      'userName': userName,
    };
  }

  // 로그아웃: 모든 유저 관련 정보 제거
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");
    await prefs.remove("userName");
    await prefs.remove("userPreferences");
  }

  //검색 관련
  // 🔹 최근 검색 장소 추가 (location 객체 전체 전달)
  Future<bool> addRecentSearch(
      String userId, Map<String, dynamic> location) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/$userId/recentsearch'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'location': location}),
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        debugPrint("❗ 최근 장소 추가 실패: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      debugPrint("❗ 에러 발생 (addRecentSearch): $e");
      return false;
    }
  }

  // 🔹 최근 검색 장소 조회
  Future<List<Map<String, dynamic>>> fetchRecentSearch(String userId) async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/users/$userId/recentsearch'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data
            .map<Map<String, dynamic>>((item) => {
                  '_id': item['_id'],
                  'title': item['title'],
                  'image': item['firstimage']
                })
            .toList();
      } else {
        debugPrint("❗ 최근 검색어 조회 실패: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("❗ 에러 발생 (fetchRecentSearch): $e");
      return [];
    }
  }

  // 🔹 최근 검색 장소 삭제
  Future<bool> deleteRecentSearch(String userId, dynamic locationId) async {
    try {
      final response = await http.delete(
        Uri.parse(
            '$baseUrl/users/$userId/recentsearch/${locationId.toString()}'),
      );

      if (response.statusCode == 200) {
        debugPrint("❗ 삭제 성공: ${response.statusCode}");
        return true;
      } else {
        debugPrint("❗ 삭제 실패: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      debugPrint("❗ 에러 발생 (deleteRecentSearch): $e");
      return false;
    }
  }

  // 🔹 최근 검색 전체 초기화
  Future<bool> resetRecentSearch(String userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/users/$userId/recentsearch'),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint("❗ 전체 삭제 실패: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      debugPrint("❗ 에러 발생 (resetRecentSearch): $e");
      return false;
    }
  }

  // 🔹 사용자 키워드 업데이트
  Future<bool> updateUserKeyword(String userId, String subKeywordId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/$userId/keywords'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'subKeywordId': subKeywordId}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint("❗ 키워드 업데이트 실패: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      debugPrint("❗ 에러 발생 (updateUserKeyword): $e");
      return false;
    }
  }
}
