// pages/recommend/RecommendHistoryPage.dart
import 'package:pik/pages/location/DetailPage.dart';
import 'package:pik/services/recommendation_service.dart';
import 'package:pik/services/location_service.dart';
import 'package:pik/styles/styles.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecommendHistoryPage extends StatefulWidget {
  const RecommendHistoryPage({Key? key}) : super(key: key);

  @override
  State<RecommendHistoryPage> createState() => _RecommendHistoryPageState();
}

class _RecommendHistoryPageState extends State<RecommendHistoryPage> {
  final RecommendationService _recommendService = RecommendationService();
  final LocationService _locationService = LocationService();

  bool _isLoading = true;
  List<dynamic> _historyList = [];
  String _errorMessage = '';
  Map<String, Map<String, dynamic>> _locationDetails = {};
  Set<String> _loadingLocations = {};

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId') ?? '';
      final token = prefs.getString('token') ?? '';

      final result = await _recommendService.getRecommendationHistory(
        userId: userId,
        token: token,
      );

      debugPrint('📝 Full API result: $result');

      if (result['success'] == true) {
        final data = result['data'];
        debugPrint('📝 History data type: ${data.runtimeType}');
        debugPrint('📝 History data: $data');

        setState(() {
          if (data != null) {
            // data가 Map인지 List인지 확인
            if (data is Map<String, dynamic>) {
              // 단일 객체인 경우 - API는 recommendations 키를 사용
              final recommendations = data['recommendations'] as List?;

              if (recommendations != null && recommendations.isNotEmpty) {
                debugPrint(
                    '📝 Found ${recommendations.length} recommendations');

                final categories = data['categories'] as List? ?? [];
                final userSelections = <String, dynamic>{};

                // categories에서 선택 조건 추출
                if (data['city'] != null && (data['city'] as List).isNotEmpty) {
                  userSelections['city'] = data['city'];
                }

                for (var cat in categories) {
                  final category = cat['category'] ?? '';
                  if (category.isNotEmpty) {
                    userSelections[category] = cat['tag'] ?? '';
                  }
                }

                if (data['conveniences'] != null &&
                    (data['conveniences'] as List).isNotEmpty) {
                  userSelections['conveniences'] = data['conveniences'];
                }

                _historyList = [
                  {
                    'id': data['id'] ??
                        DateTime.now().millisecondsSinceEpoch.toString(),
                    'userSelections': userSelections,
                    'results': recommendations,
                    'createdAt':
                        data['time'] ?? DateTime.now().toIso8601String(),
                  }
                ];
              } else {
                debugPrint('📝 No recommendations in data');
                _historyList = [];
              }
            } else if (data is List) {
              // 배열인 경우
              debugPrint('📝 Data is List with length: ${data.length}');
              if (data.isEmpty) {
                _historyList = [];
              } else {
                // 첫 번째 항목 사용
                final firstItem = data[0] as Map<String, dynamic>;
                final recommendations = firstItem['recommendations'] as List?;

                if (recommendations != null && recommendations.isNotEmpty) {
                  final categories = firstItem['categories'] as List? ?? [];
                  final userSelections = <String, dynamic>{};

                  if (firstItem['city'] != null &&
                      (firstItem['city'] as List).isNotEmpty) {
                    userSelections['city'] = firstItem['city'];
                  }

                  for (var cat in categories) {
                    final category = cat['category'] ?? '';
                    if (category.isNotEmpty) {
                      userSelections[category] = cat['tag'] ?? '';
                    }
                  }

                  if (firstItem['conveniences'] != null &&
                      (firstItem['conveniences'] as List).isNotEmpty) {
                    userSelections['conveniences'] = firstItem['conveniences'];
                  }

                  _historyList = [
                    {
                      'id': firstItem['id'] ??
                          DateTime.now().millisecondsSinceEpoch.toString(),
                      'userSelections': userSelections,
                      'results': recommendations,
                      'createdAt':
                          firstItem['time'] ?? DateTime.now().toIso8601String(),
                    }
                  ];
                }
              }
            } else {
              debugPrint('📝 Unexpected data type');
              _historyList = [];
            }
          } else {
            debugPrint('📝 Data is null');
            _historyList = [];
          }

          _isLoading = false;
        });
      } else {
        debugPrint(
            '📝 API call failed: ${result['message'] ?? 'Unknown error'}');
        setState(() {
          _errorMessage = result['message'] ?? '추천 내역을 불러올 수 없습니다.';
          _isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        _errorMessage = '오류가 발생했습니다: $error';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.deepGrean),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '이전 추천 여행지',
          style: TextStyle(
            color: AppColors.deepGrean,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.mainGreen,
              ),
            )
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : _historyList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.history,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '추천 받은 여행지가 없습니다',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _historyList.length,
                      itemBuilder: (context, index) {
                        final history = _historyList[index];
                        final userSelections = history['userSelections'] ?? {};
                        final results = history['results'] as List? ?? [];
                        final createdAt = history['createdAt'] ?? '';

                        return _buildHistoryCard(
                          userSelections: userSelections,
                          results: results,
                          createdAt: createdAt,
                        );
                      },
                    ),
    );
  }

  Widget _buildHistoryCard({
    required Map<String, dynamic> userSelections,
    required List<dynamic> results,
    required String createdAt,
  }) {
    // 날짜 포맷팅
    String formattedDate = '';
    try {
      final date = DateTime.parse(createdAt);
      formattedDate = '${date.year}.${date.month}.${date.day}';
    } catch (e) {
      formattedDate = createdAt;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 날짜
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  formattedDate,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 선택한 조건 태그
            const Text(
              '선택한 조건',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.deepGrean,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _buildSelectionTags(userSelections),
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // 추천 결과
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '추천 결과 (${results.length}개)',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.deepGrean,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 추천 장소 목록
            ...results.take(3).map((place) {
              final placeId = place['id'] ?? place['_id'] ?? '';
              if (placeId.isNotEmpty) {
                // 빌드 후에 호출하도록 수정
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _fetchLocationDetails(placeId);
                });
              }
              return _buildPlaceItem(place);
            }).toList(),

            if (results.length > 3)
              TextButton(
                onPressed: () {
                  // 전체 결과 보기
                  _showAllResults(results);
                },
                child: Text(
                  '${results.length - 3}개 더 보기',
                  style: const TextStyle(
                    color: AppColors.mainGreen,
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSelectionTags(Map<String, dynamic> userSelections) {
    final tags = <Widget>[];

    // 카테고리별 아이콘 매핑
    final iconMap = {
      'city': Icons.location_on,
      '동행': Icons.people,
      '계절': Icons.wb_sunny,
      '장소': Icons.place,
      '활동': Icons.directions_run,
      'conveniences': Icons.hotel,
    };

    userSelections.forEach((key, value) {
      if (value == null) return;

      if (key == 'city' && value is List && value.isNotEmpty) {
        tags.add(
            _buildTag('지역: ${value.join(", ")}', iconMap[key] ?? Icons.label));
      } else if (key == 'conveniences' && value is List && value.isNotEmpty) {
        tags.add(_buildTag('편의시설', iconMap[key] ?? Icons.label));
      } else if (value is String && value.isNotEmpty) {
        tags.add(_buildTag('$key: $value', iconMap[key] ?? Icons.label));
      }
    });

    return tags;
  }

  Widget _buildTag(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.mainGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.mainGreen.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: AppColors.deepGrean,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.deepGrean,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // 장소 상세 정보 가져오기
  Future<void> _fetchLocationDetails(String locationId) async {
    if (_locationDetails.containsKey(locationId) ||
        _loadingLocations.contains(locationId)) {
      return;
    }

    setState(() {
      _loadingLocations.add(locationId);
    });

    try {
      final locationData = await _locationService.fetchLocation(locationId);
      setState(() {
        _locationDetails[locationId] = locationData;
      });
    } catch (error) {
      debugPrint('❌ 장소 상세 정보 가져오기 실패 ($locationId): $error');
    } finally {
      setState(() {
        _loadingLocations.remove(locationId);
      });
    }
  }

  Widget _buildPlaceItem(dynamic place) {
    final placeId = place['id'] ?? place['_id'] ?? '';
    final locationDetail = _locationDetails[placeId];

    // 이미지 URL 가져오기
    final imageUrl = locationDetail?['firstimage'] ??
        locationDetail?['firstimage2'] ??
        place['image'] ??
        place['firstimage'] ??
        place['firstimage2'] ??
        '';

    // 여행지 이름
    final title = locationDetail?['title'] ?? place['title'] ?? '이름 없는 장소';

    // 주소
    final address = locationDetail?['address'] ??
        locationDetail?['addr1'] ??
        place['address'] ??
        place['addr1'] ??
        '주소 정보 없음';

    final isLoadingDetail = _loadingLocations.contains(placeId);

    return GestureDetector(
      onTap: () {
        if (placeId.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailPage(
                placeId: placeId,
                placeName: title,
              ),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 사진
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: imageUrl.isEmpty
                  ? Container(
                      width: 120,
                      height: 120,
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
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: 120,
                          height: 120,
                          color: Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.deepGrean,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 120,
                          height: 120,
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              color: Colors.grey,
                              size: 40,
                            ),
                          ),
                        );
                      },
                    ),
            ),
            // 여행지 이름과 주소
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // 여행지 이름
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // 주소
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            address,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (isLoadingDetail) ...[
                      const SizedBox(height: 8),
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.mainGreen,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAllResults(List<dynamic> results) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '전체 추천 결과 (${results.length}개)',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.deepGrean,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final place = results[index];
                      final placeId = place['id'] ?? place['_id'] ?? '';
                      if (placeId.isNotEmpty) {
                        // 빌드 후에 호출하도록 수정
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _fetchLocationDetails(placeId);
                        });
                      }
                      return _buildPlaceItem(place);
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
