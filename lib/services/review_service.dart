// services/review_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

final String baseUrl = Platform.isAndroid
    ? 'http://${dotenv.env['BASE_URL']}:8001'
    : 'http://localhost:8001';

class ReviewService {
  // 특정 장소의 리뷰 목록 조회
  Future<List<dynamic>> getReviewsByLocation(
      String locationId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/review/$locationId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ 리뷰 조회 성공: ${data['reviews']?.length ?? 0}개');
        return data['reviews'] ?? [];
      } else {
        print('❌ 리뷰 조회 실패: ${response.statusCode}');
        print('응답: ${response.body}');
        return []; // 빈 배열 반환하여 앱이 크래시되지 않도록 함
      }
    } catch (e) {
      print('❌ 리뷰 조회 에러: $e');
      return []; // 빈 배열 반환하여 앱이 크래시되지 않도록 함
    }
  }

  // 사용자의 특정 장소 리뷰 조회 (내 리뷰 찾기용)
  Future<Map<String, dynamic>> getMyReviewByLocation(
      String locationId, String token, String userId) async {
    try {
      final reviews = await getReviewsByLocation(locationId, token);

      // 현재 사용자의 리뷰 찾기
      for (var review in reviews) {
        if (review['author'] == userId) {
          return {
            'content': review['content'],
            'reviewId': review['_id'],
            'sentimentAspects': review['sentimentAspects'] ?? [],
          };
        }
      }

      return {'content': '', 'reviewId': '', 'sentimentAspects': []};
    } catch (e) {
      print('❌ 내 리뷰 조회 에러: $e');
      return {'content': '', 'reviewId': '', 'sentimentAspects': []};
    }
  }

  // 사용자의 특정 장소 리뷰 상세 조회 (감성 분석 결과 포함)
  Future<Map<String, dynamic>> getMyReviewWithSentiment(
      String locationId, String token, String userId) async {
    try {
      // 사용자 리뷰 전체 조회에서 해당 장소의 리뷰 찾기
      final userReviews = await getReviewsByUser(userId, token);

      for (var review in userReviews) {
        if (review['location']['_id'] == locationId ||
            review['location'] == locationId) {
          return {
            'content': review['content'],
            'reviewId': review['_id'],
            'sentimentAspects': review['sentimentAspects'] ?? [],
          };
        }
      }

      return {'content': '', 'reviewId': '', 'sentimentAspects': []};
    } catch (e) {
      print('❌ 내 리뷰 상세 조회 에러: $e');
      return {'content': '', 'reviewId': '', 'sentimentAspects': []};
    }
  }

  // 리뷰 생성
  Future<bool> createReview(String locationId, String content, String token,
      {List<String>? categories}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/review/$locationId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'content': content,
          'categories': categories ?? [],
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        print('✅ 리뷰 생성 성공: ${data['content']}');
        print('📊 감성 분석 결과: ${data['sentimentAspects']?.length ?? 0}개');
        return true;
      } else {
        print('❌ 리뷰 생성 실패: ${response.statusCode}');
        print('응답: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ 리뷰 생성 에러: $e');
      return false;
    }
  }

  // 리뷰 수정
  Future<bool> updateReview(String reviewId, String content, String token,
      {List<String>? categories}) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/review/$reviewId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'content': content,
          'categories': categories ?? [],
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ 리뷰 수정 성공: ${data['message']}');
        return true;
      } else {
        print('❌ 리뷰 수정 실패: ${response.statusCode}');
        print('응답: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ 리뷰 수정 에러: $e');
      return false;
    }
  }

  // 리뷰 삭제
  Future<bool> deleteReview(String reviewId, String token) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/review/$reviewId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ 리뷰 삭제 성공: ${data['message']}');
        return true;
      } else {
        print('❌ 리뷰 삭제 실패: ${response.statusCode}');
        print('응답: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ 리뷰 삭제 에러: $e');
      return false;
    }
  }

  // 사용자 작성 리뷰 전체 조회
  Future<List<dynamic>> getReviewsByUser(String userId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/review/user/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ 사용자 리뷰 조회 성공: ${data['reviews']?.length ?? 0}개');
        return data['reviews'] ?? [];
      } else {
        print('❌ 사용자 리뷰 조회 실패: ${response.statusCode}');
        print('응답: ${response.body}');
        return [];
      }
    } catch (e) {
      print('❌ 사용자 리뷰 조회 에러: $e');
      return [];
    }
  }

  // 감성 분석만 수행 (리뷰 저장 없이)
  Future<Map<String, dynamic>?> analyzeReview(
      String content, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/review/analyze'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'content': content,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ 감성 분석 성공: ${data['message']}');
        return {
          'rawSentiments': data['rawSentiments'],
          'processed': data['processed'],
        };
      } else {
        print('❌ 감성 분석 실패: ${response.statusCode}');
        print('응답: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ 감성 분석 에러: $e');
      return null;
    }
  }
}
