// services/keyword_service.dart
// services/keyword_service.dartㄱ
import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class KeywordService {
  final String baseUrl = Platform.isAndroid
      ? 'http://${dotenv.env['BASE_URL']}:8001'
      : 'http://localhost:8001';

  //대분류 키워드 조회
  Future<List<Map<String, dynamic>>> getAllKeywords() async {
    final url = Uri.parse('$baseUrl/api/keywords/all');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => item as Map<String, dynamic>).toList();
    } else {
      throw Exception('키워드 조회 실패: ${response.statusCode}');
    }
  }

  //소분류 키워드 조회
  Future<List<Map<String, dynamic>>> getSubKeywords(String categoryId) async {
    final url = Uri.parse('$baseUrl/api/categories/$categoryId/subkeywords');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> subcategories = data['subcategories'] ?? [];
      return subcategories.whereType<Map<String, dynamic>>().toList();
    } else {
      throw Exception('소분류 키워드 조회 실패: ${response.statusCode}');
    }
  }

  Future<List<Map<String, dynamic>>> getCategory() async {
    final url = Uri.parse('$baseUrl/api/keywords/category');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.whereType<Map<String, dynamic>>().toList();
    } else {
      throw Exception('키워드 조회 실패: ${response.statusCode}');
    }
  }
}
