// pages/onboarding/RandomLocationPage.dart
// pages/onboarding/RandomLocationPage.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/random_location_service.dart';
import '../../services/like_service.dart';
import '../../styles/styles.dart';
import 'package:final_project/pages/home/HomePage.dart';

class RandomLocationPage extends StatefulWidget {
  const RandomLocationPage({super.key});

  @override
  State<RandomLocationPage> createState() => _RandomLocationPageState();
}

class _RandomLocationPageState extends State<RandomLocationPage> {
  List<dynamic> randomLocations = [];
  List<dynamic> likedPlaces = []; // 좋아요한 장소들을 저장
  bool isLoading = true;
  String userId = '';
  String token = '';
  Set<String> likedLocations = {};

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchRandomLocations();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userId') ?? '';
      token = prefs.getString('token') ?? '';
    });
  }

  Future<void> _fetchRandomLocations() async {
    setState(() {
      isLoading = true;
    });

    try {
      final locations = await RandomLocationService.getRandomLocations();
      // 좋아요한 장소들을 제외한 새로운 장소들만 추가
      final newLocations = locations.where((location) {
        final placeId = location['_id'] ?? location['id'] ?? '';
        return !likedLocations.contains(placeId);
      }).toList();

      setState(() {
        randomLocations = newLocations;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching random locations: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _toggleLike(
      String placeId, String placeName, dynamic location) async {
    if (userId.isEmpty) return;

    try {
      final likeService = LikeService();
      final isLiked = likedLocations.contains(placeId);

      if (isLiked) {
        // 좋아요 취소
        final success = await likeService.removeUserLike(userId, placeId);
        if (success) {
          setState(() {
            // 상단 좋아요 상태에서 제거
            likedLocations.remove(placeId);
            likedPlaces.removeWhere(
              (place) => (place['_id'] ?? place['id']) == placeId,
            );

            // 랜덤 목록에 다시 추가 (이미 있지 않다면)
            final existsInRandom = randomLocations.any((item) {
              final id = item['_id'] ?? item['id'] ?? '';
              return id == placeId;
            });
            if (!existsInRandom) {
              // 어디에 둘지는 취향—상단에 보이게 맨 앞에 삽입
              randomLocations.insert(0, location);
            }
          });
          print('좋아요 취소 성공: $placeName');
        } else {
          print('좋아요 취소 실패: $placeName');
        }
      } else {
        // 좋아요 추가
        final success = await likeService.addUserLike(userId, placeId);
        if (success) {
          setState(() {
            // 상단 좋아요 리스트에 추가
            likedLocations.add(placeId);
            likedPlaces.add(location);

            // 하단 랜덤 목록에서 제거 → 중복 표시 방지
            randomLocations.removeWhere((item) {
              final id = item['_id'] ?? item['id'] ?? '';
              return id == placeId;
            });
          });
          print('좋아요 추가 성공: $placeName');
        } else {
          print('좋아요 추가 실패: $placeName');
        }
      }
    } catch (e) {
      print('Error toggling like: $e');
    }
  }

  void _skipToHome() async {
    // 온보딩 완료 플래그 저장
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasCompletedOnboarding', true);

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false, // 바깥 터치로 닫히지 않음
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // const Text(
                //   "완료",
                //   style: TextStyle(
                //     fontSize: 20,
                //     fontWeight: FontWeight.bold,
                //     color: Colors.black87,
                //   ),
                //   textAlign: TextAlign.center,
                // ),
                const SizedBox(height: 12),
                const Text(
                  "관심있는 여행지 선택이 완료되었습니다!\n홈 화면으로 이동합니다.",
                  style: TextStyle(
                      fontSize: 16, color: Colors.black54, height: 1.4),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // 다이얼로그 닫기
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const HomePage()),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.mainGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      "확인",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLocationCard(dynamic location, bool isLiked) {
    final placeId = location['_id'] ?? location['id'] ?? '';
    final placeName = location['title'] ?? location['name'] ?? '알 수 없는 장소';
    final address = location['addr1'] ?? location['address'] ?? '';
    final imageUrl = location['firstimage'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // 이미지
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 80,
                height: 80,
                child: imageUrl.isEmpty
                    ? Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: Text(
                            'No Image',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      )
                    : Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.grey,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: Text(
                              'No Image',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            // 장소 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    placeName,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.deepGrean,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    address,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // 좋아요 버튼
            InkWell(
              onTap: () => _toggleLike(placeId, placeName, location),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isLiked
                      ? AppColors.mainGreen.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? AppColors.mainGreen : Colors.grey[400],
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        extendBodyBehindAppBar: false,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false, // 뒤로가기 버튼 제거
          title: Text(
            '관심 있는 장소를 선택해주세요',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.deepGrean,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              onPressed: _fetchRandomLocations,
              icon: Icon(
                Icons.refresh,
                color: AppColors.deepGrean,
              ),
              tooltip: '새로고침',
            ),
          ],
        ),
        body: Container(
          color: Colors.white,
          child: SafeArea(
            top: false,
            bottom: false,
            child: isLoading
                ? Container(
                    color: Colors.white,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Colors.grey,
                      ),
                    ),
                  )
                : randomLocations.isEmpty && likedPlaces.isEmpty
                    ? Container(
                        color: Colors.white,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.location_off,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '랜덤 장소를 불러올 수 없습니다',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: _skipToHome,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.mainGreen,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('완료'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.white,
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                '마음에 드는 장소에 좋아요를 눌러주세요!\n나중에 추천에 도움이 됩니다.',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[800],
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              child: ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                itemCount:
                                    likedPlaces.length + randomLocations.length,
                                itemBuilder: (context, index) {
                                  // 좋아요한 장소들을 먼저 표시
                                  if (index < likedPlaces.length) {
                                    return _buildLocationCard(
                                        likedPlaces[index], true);
                                  } else {
                                    // 그 다음에 랜덤 장소들 표시
                                    final location = randomLocations[
                                        index - likedPlaces.length];
                                    final placeId =
                                        location['_id'] ?? location['id'] ?? '';
                                    final isLiked =
                                        likedLocations.contains(placeId);
                                    return _buildLocationCard(
                                        location, isLiked);
                                  }
                                },
                              ),
                            ),
                            // 완료 버튼
                            Container(
                              padding: const EdgeInsets.all(20),
                              color: Colors.white,
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _skipToHome,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.mainGreen,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 13),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    '완료 (${likedLocations.length}개 선택됨)',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
          ),
        ),
      ),
    );
  }
}
