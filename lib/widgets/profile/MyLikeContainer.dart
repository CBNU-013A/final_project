// widgets/profile/MyLikeContainer.dart
import 'package:pik/pages/location/DetailPage.dart';
import 'package:pik/services/like_service.dart';
import 'package:pik/services/location_service.dart';
import 'package:pik/styles/styles.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyLikeContainer extends StatefulWidget {
  const MyLikeContainer({super.key});

  @override
  State<MyLikeContainer> createState() => _MyLikeContainerState();
}

class _MyLikeContainerState extends State<MyLikeContainer> {
  final likeService = LikeService();
  final locationService = LocationService();
  bool isLoading = true;
  String userName = '';
  String userId = '';
  String token = '';
  late SharedPreferences prefs;
  List<dynamic> likedPlaces = [];
  bool _showDetail = false;

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
    await loadLikedPlaces();
  }

  Future<void> loadLikedPlaces() async {
    setState(() {
      isLoading = true;
    });

    final idList = await likeService.loadUserLikePlaces(userId, token);
    final detailedPlaces = await locationService.fetchLocationsByIds(
      idList.map<String>((item) => item['_id'] as String).toList(),
    );
    setState(() {
      likedPlaces = detailedPlaces;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _showDetail = !_showDetail;
                      });
                    },
                    icon: Icon(
                      _showDetail ? Icons.expand_more : Icons.chevron_right,
                      color: AppColors.mainGreen,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '내가 좋아요한 장소',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.deepGrean,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.deepGrean, width: 1.2),
                ),
                child: Text(
                  '${likedPlaces.length}개',
                  style: const TextStyle(
                    color: AppColors.deepGrean,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          if (_showDetail)
            ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: likedPlaces.length,
              itemBuilder: (context, index) {
                final place = likedPlaces[index];
                final placeName = place['title'] ?? '알 수 없음';
                final placeId = place['_id'] ?? '';
                debugPrint('📍 장소명: $placeName, ID: $placeId');

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.lighterGreen.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.mainGreen.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: InkWell(
                      onTap: () {
                        if (placeId.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("❌ 장소 정보를 불러올 수 없습니다.")),
                          );
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailPage(
                              placeName: placeName,
                              placeId: placeId,
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 0),
                          minVerticalPadding: 0,
                          dense: true,
                          leading: const Icon(
                            Icons.favorite,
                            color: AppColors.errorRed,
                            size: 18,
                          ),
                          title: Text(
                            placeName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: const Icon(Icons.chevron_right,
                              color: Colors.grey, size: 20),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
