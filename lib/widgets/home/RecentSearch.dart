// widgets/home/RecentSearch.dart

import 'dart:convert';
import 'dart:io';
import 'package:pik/services/user_service.dart';
import 'package:pik/styles/styles.dart';
import 'package:pik/services/user_service.dart';
import 'package:pik/styles/text_styles.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pik/pages/location/DetailPage.dart';
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final String baseUrl = Platform.isAndroid
    ? 'http://${dotenv.env['BASE_URL']}:8001'
    : 'http://localhost:8001';

class RecentSearch extends StatefulWidget {
  final String userId;
  final String userName;

  const RecentSearch({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  RecentSearchState createState() => RecentSearchState();
}

class RecentSearchState extends State<RecentSearch> {
  final PageController _pageController = PageController(viewportFraction: 0.85);
  bool isLoading = true;
  String userName = "";
  String userId = "";
  String token = "";
  Timer? _timer;
  final userService = UserService();
  List<Map<String, dynamic>> recentsearches = []; // 최근 검색 기록

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _timer?.cancel(); // 🔥 화면 나갈 때 타이머 정리 필수
    _pageController.dispose();
    super.dispose();
  }

// 사용자 데이터 로드 (SharedPreferences에서 불러오기)
  void _loadUser() async {
    final userData = await userService.loadUserData();
    final prefs = await SharedPreferences.getInstance();
    final storedToken = prefs.getString('token') ?? '';

    if (userData.isNotEmpty) {
      setState(() {
        userId = userData['userId'] ?? '';
        userName = userData['userName'] ?? '';
        token = storedToken;
        loadRecentPlace();
      });
    } else {
      debugPrint("사용자 정보 없음");
    }
  }

  void loadRecentPlace() async {
    try {
      final placeData = await userService.fetchRecentSearch(userId);

      setState(() {
        // placeData가 비어 있거나 null이어도 안전하게 처리
        recentsearches = (placeData is List)
            ? placeData.whereType<Map<String, dynamic>>().toList()
            : <Map<String, dynamic>>[];
        isLoading = false; // ✅ 항상 로딩 종료
      });
    } catch (e) {
      debugPrint("최근 검색 기록 불러오기 실패: $e");
      setState(() {
        recentsearches = [];
        isLoading = false; // ✅ 실패해도 로딩 종료
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.grey));
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 10),
            spreadRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          '최근 검색한 여행지',
          style: AppTextStyles.sectionTitle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        if (recentsearches.isEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon(
                  //   Icons.history_outlined,
                  //   size: 48,
                  //   color: Colors.grey[400],
                  // ),
                  // const SizedBox(height: 12),
                  Text(
                    "최근 검색 기록이 없어요",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          SizedBox(
            height: 200,
            width: MediaQuery.of(context).size.width,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: recentsearches.length,
              controller: _pageController,
              itemBuilder: (context, index) {
                final search = recentsearches[index];
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  child: Container(
                    height: 171,
                    width: 160,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.grey,
                          blurRadius: 4,
                          offset: Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: GestureDetector(
                            onTap: () async {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DetailPage(
                                    placeName: search['title'],
                                    placeId: search['_id'].toString(),
                                  ),
                                ),
                              );
                              await userService.deleteRecentSearch(
                                  userId, search['_id'].toString());
                              await userService.addRecentSearch(userId, search);
                            },
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(15),
                                bottom: Radius.circular(15),
                              ),
                              child: Builder(
                                builder: (context) {
                                  final imageUrl = search['image'] as String?;
                                  return imageUrl != null && imageUrl.isNotEmpty
                                      ? Image.network(
                                          imageUrl,
                                          height: 140,
                                          width: 140,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Container(
                                            height: 140,
                                            width: 140,
                                            color: Colors.grey[300],
                                            child: const Center(
                                              child: Icon(Icons.broken_image,
                                                  size: 40, color: Colors.grey),
                                            ),
                                          ),
                                        )
                                      : Container(
                                          height: 140,
                                          width: 140,
                                          color: Colors.grey[300],
                                          child: const Center(
                                            child: Text(
                                              "No Image",
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.grey,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        );
                                },
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16.0, 5, 16.0, 5),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () async {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => DetailPage(
                                          placeName: search['title'],
                                          placeId: search['_id'].toString(),
                                        ),
                                      ),
                                    );
                                    await userService.deleteRecentSearch(
                                        userId, search['_id'].toString());
                                    await userService.addRecentSearch(
                                        userId, search);
                                  },
                                  child: Text(
                                    search['title'],
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    softWrap: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ]),
    );
  }
}
