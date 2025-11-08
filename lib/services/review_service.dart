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
        Uri.parse('$baseUrl/review/$locationId'),
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
            'categories': review['categories'] ?? [],
          };
        }
      }

      return {
        'content': '',
        'reviewId': '',
        'sentimentAspects': [],
        'categories': []
      };
    } catch (e) {
      print('❌ 내 리뷰 상세 조회 에러: $e');
      return {
        'content': '',
        'reviewId': '',
        'sentimentAspects': [],
        'categories': []
      };
    }
  }

  // 리뷰 생성
  Future<bool> createReview(
      String locationId, String content, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/review/$locationId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'content': content,
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
  Future<bool> updateReview(
      String reviewId, String content, String token) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/review/$reviewId'),
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
        Uri.parse('$baseUrl/review/$reviewId'),
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
        Uri.parse('$baseUrl/review/user/$userId'),
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

  // 카테고리 이름 가져오기
  Future<String> getCategoryName(String categoryId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/categories/$categoryId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['name'] ?? _getHardcodedCategoryName(categoryId);
      } else {
        return _getHardcodedCategoryName(categoryId);
      }
    } catch (e) {
      print('❌ 카테고리 이름 조회 에러: $e');
      return _getHardcodedCategoryName(categoryId);
    }
  }

  // 하드코딩된 카테고리 이름 매핑
  String _getHardcodedCategoryName(String categoryId) {
    switch (categoryId) {
      case '68cabaf0a9613e0e59a214cb':
        return '동반';
      case '68cabaf0a9613e0e59a214cc':
        return '계절';
      case '68cabaf0a9613e0e59a214cd':
        return '시간';
      case '68cabaf0a9613e0e59a214ce':
        return '장소';
      case '68cabaf0a9613e0e59a214cf':
        return '활동';
      default:
        return '알 수 없는 카테고리';
    }
  }

  // 태그 이름 가져오기
  Future<String> getTagName(String tagId) async {
    try {
      // 먼저 /tags 엔드포인트 시도
      var response = await http.get(
        Uri.parse('$baseUrl/tags/$tagId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('🔍 /tags 응답 데이터: $data');
        return data['name'] ?? _getHardcodedTagName(tagId);
      }

      // /tags가 실패하면 /subkeywords 엔드포인트 시도
      response = await http.get(
        Uri.parse('$baseUrl/subkeywords/$tagId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('🔍 /subkeywords 응답 데이터: $data');
        return data['name'] ?? _getHardcodedTagName(tagId);
      }

      // 둘 다 실패하면 하드코딩된 매핑 사용
      return _getHardcodedTagName(tagId);
    } catch (e) {
      print('❌ 태그 이름 조회 에러: $e');
      return _getHardcodedTagName(tagId);
    }
  }

  // 하드코딩된 태그 이름 매핑
  String _getHardcodedTagName(String tagId) {
    print('🔍 하드코딩된 매핑에서 태그 ID: $tagId');
    switch (tagId) {
      case '68cabaf0a9613e0e59a214d0':
        return '가족과 함께';
      case '68cabaf0a9613e0e59a214d1':
        return '연인';
      case '68cabaf0a9613e0e59a214d2':
        return '친구';
      case '68cabaf0a9613e0e59a214d3':
        return '반려동물';
      case '68cabaf0a9613e0e59a214d4':
        return '단체';
      case '68cabaf0a9613e0e59a214d5':
        return 'none';
      case '68cabaf0a9613e0e59a214d6':
        return '봄';
      case '68cabaf0a9613e0e59a214d7':
        return '여름';
      case '68cabaf0a9613e0e59a214d8':
        return '가을';
      case '68cabaf0a9613e0e59a214d9':
        return '겨울';
      case '68cabaf0a9613e0e59a214da':
        return '주간';
      case '68cabaf0a9613e0e59a214db':
        return '야간';
      case '68cabaf0a9613e0e59a214dc':
        return '자연경관';
      case '68cabaf0a9613e0e59a214dd':
        return '도시명소';
      case '68cabaf0a9613e0e59a214de':
        return '문화역사';
      case '68cabaf0a9613e0e59a214df':
        return '상업';
      case '68cabaf0a9613e0e59a214e0':
        return '휴양';
      case '68cabaf0a9613e0e59a214e1':
        return '탐방';
      case '68cabaf0a9613e0e59a214e2':
        return '관람 활동';
      case '68cabaf0a9613e0e59a214e3':
        return '참여';
      case '68cabaf0a9613e0e59a214e4':
        return '먹거리';
      case '68cabaf0a9613e0e59a214e5':
        return '쇼핑';
      case '68cabaf0a9613e0e59a214e6':
        return '포토존';
      default:
        return '알 수 없음';
    }
  }

  // 감성 분석만 수행 (리뷰 저장 없이)
  Future<Map<String, dynamic>?> analyzeReview(
      String content, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/review/analyze'),
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
