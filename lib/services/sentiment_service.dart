// services/sentiment_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SentimentService {
  // 백엔드의 predict 엔드포인트 사용 (실제 라우터에 맞게 조정)
  final String apiUrl = 'http://localhost:8001/api/predict';

  // 입력 텍스트를 분석하고 감성 분석 결과를 반환
  Future<Map<String, dynamic>?> analyzeSentiment(String text) async {
    try {
      // 토큰 가져오기 (선택적)
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      // 헤더 설정 (토큰이 있으면 포함)
      final headers = <String, String>{
        'Content-Type': 'application/json; charset=utf-8',
      };

      if (token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      debugPrint('🔍 감성 분석 요청 URL: $apiUrl');
      debugPrint('🔍 요청 본문: ${jsonEncode({'text': text})}');
      debugPrint('🔍 요청 헤더: $headers');

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: jsonEncode({'text': text}),
      );

      debugPrint('🔍 응답 상태 코드: ${response.statusCode}');
      debugPrint('🔍 응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        final decoded =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        debugPrint('✅ 감성 분석 성공: $decoded');

        // 백엔드 응답 구조에 맞게 변환
        // sentimentAspects 배열을 sentiments 객체로 변환
        if (decoded['sentimentAspects'] != null) {
          final sentimentAspects = decoded['sentimentAspects'] as List<dynamic>;
          final sentiments = <String, String>{};

          for (final aspect in sentimentAspects) {
            final aspectId = aspect['aspect'] as String;
            final sentiment = aspect['sentiment'] as Map<String, dynamic>;

            // pos, neg, none 중 가장 높은 값을 찾아서 문자열로 변환
            String sentimentValue = 'none';
            if (sentiment['pos'] == 1) {
              sentimentValue = 'pos';
            } else if (sentiment['neg'] == 1) {
              sentimentValue = 'neg';
            }

            // aspect ID를 실제 이름으로 매핑 (임시로 ID 사용)
            sentiments[aspectId] = sentimentValue;
          }

          return {
            'sentiments': sentiments,
            'categories': decoded['categories'] ?? {},
          };
        }

        return decoded;
      } else {
        debugPrint('❌ 감성 분석 요청 실패: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('🚨 감성 분석 요청 오류: $e');
      return null;
    }
  }
}
