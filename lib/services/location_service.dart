// services/location_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

final String baseUrl = Platform.isAndroid
    ? 'http://${dotenv.env['BASE_URL']}:8001'
    : 'http://localhost:8001';

class LocationService {
  Future<List<dynamic>> fetchAllLocations() async {
    final response = await http.get(Uri.parse('$baseUrl/location/all'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load all locations');
    }
  }

  Future<Map<String, dynamic>> fetchLocation(String placeId) async {
    if (placeId.isEmpty) {
      throw Exception('placeId is empty');
    }

    final response = await http.get(Uri.parse('$baseUrl/location/id/$placeId'));

    if (response.statusCode == 200) {
      final body = response.body;
      try {
        return jsonDecode(body);
      } catch (e) {
        throw Exception('Failed to decode location data: $e');
      }
    } else {
      throw Exception('Failed to load location data: ${response.statusCode}');
    }
  }

  Future<List<Map<String, dynamic>>> fetchLocationsByIds(
      List<String> placeIds) async {
    List<Map<String, dynamic>> locations = [];
    for (final id in placeIds) {
      try {
        final location = await fetchLocation(id);
        locations.add(location);
      } catch (e) {
        // ignore: avoid_print
      }
    }
    return locations;
  }
}
