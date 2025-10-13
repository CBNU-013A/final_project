// services/random_location_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class RandomLocationService {
  static const String baseUrl = 'http://localhost:8001';

  /// 랜덤 장소 10개 가져오기 (충청도 우선)
  static Future<List<dynamic>> getRandomLocations() async {
    try {
      final url = Uri.parse('$baseUrl/api/location/random');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List<dynamic>;

        // 충청도 지역 목록
        final chungcheongRegions = ['충북', '충남', '대전', '세종'];

        // 충청도 장소와 기타 장소를 분리
        final chungcheongPlaces = data.where((place) {
          final city = place['city'] ?? place['address'] ?? '';
          return chungcheongRegions.any((region) => city.contains(region));
        }).toList();

        final otherPlaces = data.where((place) {
          final city = place['city'] ?? place['address'] ?? '';
          return !chungcheongRegions.any((region) => city.contains(region));
        }).toList();

        // 충청도 장소를 앞에, 기타 장소를 뒤에 배치
        return [...chungcheongPlaces, ...otherPlaces];
      } else {
        print('Random locations API error: ${response.statusCode}');
        print('Response: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error fetching random locations: $e');
      return [];
    }
  }
}
