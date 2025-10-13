// services/recommendation_service.dart
// services/recommendation_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class RecommendationService {
  final String baseUrl = Platform.isAndroid
      ? 'http://${dotenv.env['BASE_URL']}:8001'
      : 'http://localhost:8001';

  // 서버 연결 테스트
  Future<bool> testConnection() async {
    try {
      debugPrint('🔍 서버 연결 테스트 중...');
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/recommend/history/test'),
          )
          .timeout(const Duration(seconds: 5));

      debugPrint('✅ 서버 연결 상태: ${response.statusCode}');
      return response.statusCode == 200 || response.statusCode == 404;
    } catch (error) {
      debugPrint('❌ 서버 연결 실패: $error');
      return false;
    }
  }

  // 지역 기반 추천 (도시만 선택)
  Future<Map<String, dynamic>> recommendByRegion({
    required String userId,
    required String token,
    List<String> cities = const [],
    int limit = 10,
  }) async {
    try {
      debugPrint('=== 지역 기반 추천 ===');
      debugPrint('사용자 ID: $userId');
      debugPrint('선택된 도시들: $cities');
      debugPrint('제한 개수: $limit');

      final response = await http.post(
        Uri.parse('$baseUrl/api/recommend'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'userId': userId,
          'cities': cities,
          'limit': limit,
        }),
      );

      debugPrint('지역 기반 추천 응답 상태: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        debugPrint('✅ 지역 기반 추천 성공: $data');
        return {'success': true, 'data': data};
      } else {
        final errorText = response.body;
        debugPrint('❌ 지역 기반 추천 실패: $errorText');
        return {'success': false, 'error': errorText};
      }
    } catch (error) {
      debugPrint('❌ 지역 기반 추천 오류: $error');
      return {'success': false, 'error': error.toString()};
    }
  }

  // 사용자 기반 추천 (도시 + 사용자 선호도)
  Future<Map<String, dynamic>> recommendByUser({
    required String userId,
    required String token,
    List<String> cities = const [],
    int limit = 20,
  }) async {
    try {
      debugPrint('=== 사용자 기반 추천 ===');
      debugPrint('사용자 ID: $userId');
      debugPrint('선택된 도시들: $cities');
      debugPrint('제한 개수: $limit');

      final response = await http.post(
        Uri.parse('$baseUrl/api/recommend/user/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'cities': cities,
          'limit': limit,
        }),
      );

      debugPrint('사용자 기반 추천 응답 상태: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        debugPrint('✅ 사용자 기반 추천 성공');
        return {'success': true, 'data': data};
      } else {
        final errorText = response.body;
        debugPrint('❌ 사용자 기반 추천 실패: $errorText');
        return {'success': false, 'error': errorText};
      }
    } catch (error) {
      debugPrint('❌ 사용자 기반 추천 오류: $error');
      return {'success': false, 'error': error.toString()};
    }
  }

  // 다단계 필터 추천 (도시 + 카테고리 + 편의시설)
  Future<Map<String, dynamic>> multiStepFilter({
    required String userId,
    required String token,
    required Map<String, dynamic> filterData,
  }) async {
    try {
      debugPrint('=== 다단계 필터 추천 ===');
      debugPrint('사용자 ID: $userId');
      debugPrint('필터 데이터: $filterData');

      final response = await http.post(
        Uri.parse('$baseUrl/api/recommend/filter'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'userId': userId,
          ...filterData,
        }),
      );

      debugPrint('다단계 필터 추천 응답 상태: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        debugPrint('✅ 다단계 필터 추천 성공');
        return {'success': true, 'data': data};
      } else {
        final errorText = response.body;
        debugPrint('❌ 다단계 필터 추천 실패: $errorText');
        return {'success': false, 'error': errorText};
      }
    } catch (error) {
      debugPrint('❌ 다단계 필터 추천 오류: $error');
      return {'success': false, 'error': error.toString()};
    }
  }

  // 사용자 선택 기반 추천
  Future<Map<String, dynamic>> getRecommendationsByUserSelection({
    required String userId,
    required String token,
    required Map<String, dynamic> userSelections,
  }) async {
    try {
      debugPrint('=== 사용자 선택 기반 추천 ===');
      debugPrint('사용자 ID: $userId');
      debugPrint('사용자 선택사항: $userSelections');

      final payload = <String, dynamic>{
        'userId': userId,
        'city': userSelections['city'] ?? [],
      };

      // 선택된 값만 payload에 추가 (빈 값 제외)
      if (userSelections.containsKey('accompany')) {
        payload['accompany'] = userSelections['accompany'];
      }
      if (userSelections.containsKey('season')) {
        payload['season'] = userSelections['season'];
      }
      if (userSelections.containsKey('place')) {
        payload['place'] = userSelections['place'];
      }
      if (userSelections.containsKey('activity')) {
        payload['activity'] = userSelections['activity'];
      }
      if (userSelections.containsKey('conveniences')) {
        debugPrint(
            '🔍 [서비스] userSelections에서 가져온 conveniences: ${userSelections['conveniences']}');
        debugPrint(
            '🔍 [서비스] 타입: ${userSelections['conveniences'].runtimeType}');
        payload['conveniences'] = userSelections['conveniences'];
        debugPrint('🔍 [서비스] payload에 저장 후: ${payload['conveniences']}');
      }

      debugPrint('📤 추천 요청 payload: $payload');
      debugPrint('📤 편의시설 payload: ${payload['conveniences']}');
      debugPrint('📤 전체 payload JSON: ${jsonEncode(payload)}');

      final response = await http.post(
        Uri.parse('$baseUrl/api/recommend/filter'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      debugPrint('사용자 선택 기반 추천 응답 상태: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        debugPrint('✅ 사용자 선택 기반 추천 성공');
        debugPrint('추천 결과 개수: ${data['recommendations']?.length ?? 0}');
        return {'success': true, 'data': data};
      } else {
        final errorText = response.body;
        debugPrint('❌ 사용자 선택 기반 추천 실패: $errorText');
        return {
          'success': false,
          'error': errorText,
          'status': response.statusCode
        };
      }
    } catch (error) {
      debugPrint('❌ 사용자 선택 기반 추천 오류: $error');
      return {'success': false, 'error': error.toString()};
    }
  }

  // 추천 히스토리 조회
  Future<Map<String, dynamic>> getRecommendationHistory({
    required String userId,
    required String token,
  }) async {
    try {
      debugPrint('=== 사용자 추천 히스토리 조회 ===');
      debugPrint('사용자 ID: $userId');

      final response = await http.get(
        Uri.parse('$baseUrl/api/recommend/history/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('추천 히스토리 조회 응답 상태: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        debugPrint('✅ 추천 히스토리 조회 성공');
        debugPrint('히스토리 결과 개수: ${data['results']?.length ?? 0}');

        // 히스토리 데이터를 추천 결과 형식으로 변환
        final recommendations = (data['results'] as List?)
                ?.map((result) => {
                      'id': result['id'],
                      'title': result['title'],
                      'city': result['city'],
                      'convenienceScore': null,
                    })
                .toList() ??
            [];

        return {
          'success': true,
          'data': {
            'message': data['message'],
            'recommendations': recommendations,
            'history': data,
          }
        };
      } else {
        final errorText = response.body;
        debugPrint('❌ 추천 히스토리 조회 실패: $errorText');
        return {
          'success': false,
          'error': errorText,
          'status': response.statusCode
        };
      }
    } catch (error) {
      debugPrint('❌ 추천 히스토리 조회 오류: $error');
      return {'success': false, 'error': error.toString()};
    }
  }
}
