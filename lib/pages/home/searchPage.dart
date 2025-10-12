// pages/home/SearchPage.dart
import 'dart:io';
import 'package:final_project/services/location_service.dart';
import 'package:final_project/services/user_service.dart';
import 'package:final_project/styles/styles.dart';
import 'package:flutter/material.dart';
import 'package:final_project/widgets/search_bar.dart' as custom;
import 'package:final_project/pages/location/detailPage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/BottomNavi.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final String baseUrl = Platform.isAndroid
    ? 'http://${dotenv.env['BASE_URL']}:8001'
    : 'http://localhost:8001';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final userService = UserService();
  final locationService = LocationService();
  String userId = '';
  String userName = '';
  String token = '';
  List<dynamic> allPlaces = [];
  List<dynamic> filteredPlaces = [];
  List<dynamic> recentsearches = [];
  bool isLoadingRecentSearches = true;
  final TextEditingController _controller = TextEditingController();
  late SharedPreferences prefs;

  @override
  void initState() {
    super.initState();
    loadPrefs();
  }

  Future<void> loadPrefs() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userId') ?? '';
      userName = prefs.getString('userName') ?? '';
      token = prefs.getString('token') ?? '';
    });

    loadRecentSearches();
    loadPlaces();
  }

  void loadPlaces() async {
    final placeData = await locationService.fetchAllLocations();
    if (placeData.isNotEmpty) {
      setState(() {
        allPlaces = placeData;
      });
    } else {
      debugPrint("모든 장소 정보 없음");
    }
  }

  void loadRecentSearches() async {
    if (!mounted) return; // ✅ 위젯이 살아있는지 확인

    setState(() {
      isLoadingRecentSearches = true;
    });

    final placeData = await userService.fetchRecentSearch(userId);
    if (placeData.isNotEmpty) {
      setState(() {
        recentsearches = placeData
            .map<Map<String, dynamic>>((item) => {
                  '_id': item['_id'],
                  'title': item['title'],
                })
            .toList();
        isLoadingRecentSearches = false;
      });
    } else {
      setState(() {
        isLoadingRecentSearches = false;
      });
      ("최근 검색 기록 없음");
    }
  }

  void filterPlaces(String query) {
    if (query.isEmpty) {
      filteredPlaces = [];
      return;
    }

    // 검색어를 소문자로 변환
    final searchQuery = query.toLowerCase();
    final List<Map<String, dynamic>> titleMatches = [];
    final List<Map<String, dynamic>> overviewMatches = [];

    // 1순위: 여행지 이름(title)에서 검색
    allPlaces.forEach((location) {
      if (location['title'] != null &&
          location['title'].toString().toLowerCase().contains(searchQuery)) {
        titleMatches.add(location);
      }
    });

    // 2순위: 소개글(overview)에서 검색 (이미 title에서 매칭된 것 제외)
    final titleIds = Set.from(titleMatches.map((loc) => loc['_id']));
    allPlaces.forEach((location) {
      if (!titleIds.contains(location['_id']) &&
          location['overview'] != null &&
          location['overview'].toString().toLowerCase().contains(searchQuery)) {
        overviewMatches.add(location);
      }
    });

    // title 매칭 결과 + overview 매칭 결과
    filteredPlaces = [...titleMatches, ...overviewMatches];
  }

  Widget _buildRecentSearches() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "최근 검색 기록",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    await userService.resetRecentSearch(userId);
                    final recent = await userService.fetchRecentSearch(userId);
                    if (mounted) {
                      setState(() {
                        recentsearches = recent;
                      });
                    }
                  },
                  child: const Text(
                    '모두 삭제',
                    style: TextStyle(
                      color: AppColors.deepGrean,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (isLoadingRecentSearches)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(color: Colors.grey),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentsearches.length,
              itemBuilder: (context, index) {
                final place = recentsearches[index];
                final title = place['title'] ?? '이름 없는 장소';
                final id = place['_id']?.toString() ?? '';

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    title: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.close_outlined,
                          color: Colors.grey, size: 20),
                      onPressed: () async {
                        await userService.deleteRecentSearch(userId, id);
                        final recent =
                            await userService.fetchRecentSearch(userId);
                        if (mounted) {
                          setState(() {
                            recentsearches = recent;
                          });
                        }
                      },
                    ),
                    onTap: () async {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailPage(
                            placeName: title,
                            placeId: id,
                          ),
                        ),
                      );
                      await userService.deleteRecentSearch(
                          userId, place['_id'].toString());
                      await userService.addRecentSearch(userId, place);
                    },
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: custom.SearchBar(
                      controller: _controller,
                      onChanged: (value) {
                        filterPlaces(value);
                        setState(() {});
                      },
                      onClear: () {
                        setState(() {
                          _controller.clear();
                          filteredPlaces = [];
                        });
                      },
                      onSubmitted: (query) async {
                        if (query.isNotEmpty) {
                          setState(() {
                            _controller.clear();
                            filterPlaces(query);
                          });
                          await userService.addRecentSearch(
                              userId, filteredPlaces[0]['_id']);
                          final recent =
                              await userService.fetchRecentSearch(userId);
                          if (mounted) {
                            setState(() {
                              recentsearches = recent;
                            });
                          }
                          await Future.delayed(Duration.zero);
                          if (!mounted) return;

                          if (filteredPlaces.isNotEmpty) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DetailPage(
                                  placeName: filteredPlaces[0]['title'],
                                  placeId: filteredPlaces[0]['_id'].toString(),
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('해당 장소가 없어요 😢'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ),
                  // if (_controller.text.isNotEmpty)
                  //   TextButton(
                  //     onPressed: () {
                  //       setState(() {
                  //         _controller.clear();
                  //         filteredPlaces = [];
                  //         loadRecentSearches();
                  //       });
                  //     },
                  //     child: Text(
                  //       '취소',
                  //       style: TextStyle(
                  //         color: AppColors.deepGrean,
                  //         fontWeight: FontWeight.w500,
                  //         fontSize: 15,
                  //       ),
                  //     ),
                  //   ),
                ],
              ),
              const SizedBox(height: 16),
              if (_controller.text.isNotEmpty && filteredPlaces.isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredPlaces.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final place = filteredPlaces[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        title: Text(
                          place['title'],
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onTap: () async {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailPage(
                                placeName: place['title'],
                                placeId: place['_id'].toString(),
                              ),
                            ),
                          );
                          await userService.deleteRecentSearch(
                              userId, place['_id'].toString());
                          await userService.addRecentSearch(userId, place);
                        },
                      );
                    },
                  ),
                ),
              if (_controller.text.isEmpty) _buildRecentSearches(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavi(currentIndex: 2),
    );
  }
}
