// services/review_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ReviewService {
  final String baseUrl = Platform.isAndroid
      ? 'http://${dotenv.env['BASE_URL']}:8001'
      : 'http://localhost:8001';

  Future<Map<String, String>> getReviewsByLocation(
      String locationId, String token, String userId) async {
    final url = Uri.parse('$baseUrl/api/review/$locationId');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> reviews = data['reviews'];

      // 현재 사용자(author)의 리뷰만 필터링
      final userReview = reviews.firstWhere(
        (review) => review['author'] == userId,
        orElse: () => null,
      );
      if (userReview != null &&
          userReview['content'] != null &&
          userReview['_id'] != null) {
        return {
          'content': userReview['content'] as String,
          'reviewId': userReview['_id'] as String,
        };
      }
    } else {
      throw Exception('리뷰 조회 실패');
    }
    return {};
  }

  Future<bool> createReview(
      String placeId, String content, String token) async {
    final url = Uri.parse('$baseUrl/api/review/$placeId');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'content': content,
      }),
    );

    return response.statusCode == 201;
  }

  Future<bool> deleteReview(String? reviewId, String? token) async {
    if (reviewId == null ||
        reviewId.isEmpty ||
        token == null ||
        token.isEmpty) {
      return false;
    }

    final url = Uri.parse('$baseUrl/api/review/$reviewId');
    final response = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    return response.statusCode == 200;
  }

  Future<bool> updateReview(
      String reviewId, String content, String token) async {
    final url = Uri.parse('$baseUrl/api/review/$reviewId');
    final response = await http.patch(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'content': content,
      }),
    );

    debugPrint('📡 PATCH 상태 코드: ${response.statusCode}');
    debugPrint('📨 응답 본문: ${response.body}');

    return response.statusCode == 200;
  }

  Future<List<Map<String, String>>> getReviewsByUser(
      String? token, String? userId) async {
    if (token == null || token.isEmpty || userId == null || userId.isEmpty) {
      return [];
    }

    final url = Uri.parse('$baseUrl/api/review/user/$userId');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> reviews = data['reviews'].reversed.toList();

      return reviews.map<Map<String, String>>((review) {
        final content = review['content'] ?? '';
        final location = review['location'];
        final id = review['_id'];
        final locationName =
            location is Map<String, dynamic> ? location['title'] ?? '' : '';
        final locationId =
            location is Map<String, dynamic> ? location['_id'] ?? '' : '';

        return {
          'id': id,
          'content': content,
          'location': locationName,
          'locationId': locationId,
        };
      }).toList();
    } else {
      throw Exception('리뷰 조회 실패');
    }
  }
}
