// services/like_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:pik/services/location_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LikeService {
  final String baseUrl = Platform.isAndroid
      ? 'http://${dotenv.env['BASE_URL']}:8001'
      : 'http://localhost:8001';

  bool _isLiked = false;

  Future<bool> isPlaceLikedByUser(
      String userId, String placeId, String token) async {
    final likedPlaces = await loadUserLikePlaces(userId, token);
    final isLiked = likedPlaces.any((place) => place['_id'] == placeId);
    _isLiked = isLiked;
    return isLiked;
  }

  Future<bool> addUserLike(String userId, String placeId) async {
    final url = Uri.parse('$baseUrl/users/$userId/likes');
    final response = await http.post(
      url,
      body: jsonEncode({"locationId": placeId}),
      headers: {'Content-Type': 'application/json'},
    );
    return response.statusCode == 200;
  }

  Future<bool> removeUserLike(String userId, String placeId) async {
    final url = Uri.parse('$baseUrl/users/$userId/likes');
    final response = await http.delete(
      url,
      body: jsonEncode({"locationId": placeId}),
      headers: {'Content-Type': 'application/json'},
    );
    return response.statusCode == 200;
  }

  Future<bool> toggleLike(
      String userId, String placeId, String token, bool isLiked) async {
    if (isLiked) {
      return await removeUserLike(userId, placeId);
    } else {
      return await addUserLike(userId, placeId);
    }
  }

  Future<List<dynamic>> loadUserLikePlaces(String userId, String token) async {
    final response = await http.get(Uri.parse('$baseUrl/users/$userId/likes'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['likes'] as List<dynamic>;
    }
    return [];
  }

  // Future<List<dynamic>> loadUserLikePlaces(String userId, String token) async {
  //   final response =
  //       await http.get(Uri.parse('$baseUrl/users/$userId/likes'));
  //   if (response.statusCode == 200) {
  //     final data = json.decode(response.body);
  //     final List<dynamic> likeList = data['likes'];
  //     final List<dynamic> result = [];

  //     for (var item in likeList) {
  //       final placeId = item['_id'];'
  //       try {
  //         final location = await LocationService().fetchLocation(placeId);
  //         result.add(location);
  //       } catch (e) {
  //         // Optionally log or skip
  //       }
  //     }

  //     return result;
  //   }
  //   return [];
  // }

  Future<bool> likeLocation(String placeName, String token) async {
    final url = Uri.parse('$baseUrl/location/$placeName/likes');
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    final response = await http.post(url, headers: headers);
    return response.statusCode == 201;
  }

  Future<int?> getLocationLikeCount(String placeName, String token) async {
    final url = Uri.parse('$baseUrl/location/$placeName/likes');
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['likeCount'] as int?;
    }
    return null;
  }
}
