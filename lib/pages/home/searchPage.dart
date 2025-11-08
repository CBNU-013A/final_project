// pages/home/SearchPage.dart
import 'dart:io';
import 'package:pik/services/location_service.dart';
import 'package:pik/services/user_service.dart';
import 'package:pik/styles/styles.dart';
import 'package:flutter/material.dart';
import 'package:pik/widgets/search_bar.dart' as custom;
import 'package:pik/pages/location/detailPage.dart';
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
    final Set<String> matchedIds = {};
    final List<Map<String, dynamic>> matchedPlaces = [];

    // title과 overview 모두에서 검색
    allPlaces.forEach((location) {
      final locationId = location['_id'].toString();

      // 이미 매칭된 항목은 건너뛰기 (중복 방지)
      if (matchedIds.contains(locationId)) {
        return;
      }

      // title에서 검색어 포함 여부 확인
      final titleMatch = location['title'] != null &&
          location['title'].toString().toLowerCase().contains(searchQuery);

      // overview에서 검색어 포함 여부 확인
      final overviewMatch = location['overview'] != null &&
          location['overview'].toString().toLowerCase().contains(searchQuery);

      // title 또는 overview 중 하나라도 검색어가 포함되면 결과에 추가
      if (titleMatch || overviewMatch) {
        matchedIds.add(locationId);
        matchedPlaces.add(location);
      }
    });

    filteredPlaces = matchedPlaces;
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
          else if (recentsearches.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  '최근 검색 기록이 없습니다',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.85,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: recentsearches.length,
              itemBuilder: (context, index) {
                final place = recentsearches[index];
                final id = place['_id']?.toString() ?? '';

                // allPlaces에서 전체 장소 정보 찾기
                final fullPlace = allPlaces.firstWhere(
                  (loc) => loc['_id'].toString() == id,
                  orElse: () => place,
                );

                final imageUrl = fullPlace['firstimage'] ?? '';
                final title = fullPlace['title'] ?? '이름 없는 장소';

                return Stack(
                  children: [
                    GestureDetector(
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
                        await userService.deleteRecentSearch(userId, id);
                        await userService.addRecentSearch(userId, fullPlace);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 이미지
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                              child: imageUrl.isEmpty
                                  ? Container(
                                      height: 140,
                                      width: double.infinity,
                                      color: Colors.grey[300],
                                      child: const Center(
                                        child: Icon(
                                          Icons.image_not_supported_outlined,
                                          color: Colors.grey,
                                          size: 40,
                                        ),
                                      ),
                                    )
                                  : Image.network(
                                      imageUrl,
                                      height: 140,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                        if (loadingProgress == null)
                                          return child;
                                        return Container(
                                          height: 140,
                                          width: double.infinity,
                                          color: Colors.grey[200],
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppColors.deepGrean,
                                            ),
                                          ),
                                        );
                                      },
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Container(
                                          height: 140,
                                          width: double.infinity,
                                          color: Colors.grey[300],
                                          child: const Center(
                                            child: Icon(
                                              Icons
                                                  .image_not_supported_outlined,
                                              color: Colors.grey,
                                              size: 40,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                            // 장소 이름
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Align(
                                  alignment: Alignment.topLeft,
                                  child: Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // 삭제 버튼
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () async {
                          await userService.deleteRecentSearch(userId, id);
                          final recent =
                              await userService.fetchRecentSearch(userId);
                          if (mounted) {
                            setState(() {
                              recentsearches = recent;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
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
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: filteredPlaces.length,
                  itemBuilder: (context, index) {
                    final place = filteredPlaces[index];
                    final imageUrl = place['firstimage'] ?? '';
                    final title = place['title'] ?? '이름 없는 장소';

                    return GestureDetector(
                      onTap: () async {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailPage(
                              placeName: title,
                              placeId: place['_id'].toString(),
                            ),
                          ),
                        );
                        await userService.deleteRecentSearch(
                            userId, place['_id'].toString());
                        await userService.addRecentSearch(userId, place);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 이미지
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                              child: imageUrl.isEmpty
                                  ? Container(
                                      height: 140,
                                      width: double.infinity,
                                      color: Colors.grey[300],
                                      child: const Center(
                                        child: Icon(
                                          Icons.image_not_supported_outlined,
                                          color: Colors.grey,
                                          size: 40,
                                        ),
                                      ),
                                    )
                                  : Image.network(
                                      imageUrl,
                                      height: 140,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                        if (loadingProgress == null)
                                          return child;
                                        return Container(
                                          height: 140,
                                          width: double.infinity,
                                          color: Colors.grey[200],
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppColors.deepGrean,
                                            ),
                                          ),
                                        );
                                      },
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Container(
                                          height: 140,
                                          width: double.infinity,
                                          color: Colors.grey[300],
                                          child: const Center(
                                            child: Icon(
                                              Icons
                                                  .image_not_supported_outlined,
                                              color: Colors.grey,
                                              size: 40,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                            // 장소 이름
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Align(
                                  alignment: Alignment.topLeft,
                                  child: Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
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
