// pages/recommend/resultPage.dart
import 'dart:convert';
import 'package:pik/pages/location/DetailPage.dart';
import 'package:pik/styles/styles.dart';
import 'package:pik/widgets/BottomNavi.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:pik/services/sentiment_service.dart';
import 'package:pik/services/location_service.dart';

class ResultPage extends StatefulWidget {
  const ResultPage({super.key});

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  bool isLoading = true;
  List<dynamic> recommendations = [];
  Map<String, dynamic>? selectionsSummary; // 사용자가 선택한 옵션 요약

  final TextEditingController _textController = TextEditingController();
  final SentimentService _predictService = SentimentService();
  final LocationService _locationService = LocationService();
  Map<String, dynamic>? predictResult;
  Map<String, Map<String, dynamic>> _locationDetails = {};
  Set<String> _loadingLocations = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 라우트 인자 사용: { data, selections }
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      final data = args['data'];
      final sel = args['selections'];
      if (data is Map && mounted) {
        final list = (data['recommendations'] as List?) ?? [];
        // 점수 높은 순으로 정렬 (finalScore, 없으면 similarity)
        list.sort((a, b) {
          final sa = (a['finalScore'] ?? a['similarity'] ?? 0) as num;
          final sb = (b['finalScore'] ?? b['similarity'] ?? 0) as num;
          return sb.compareTo(sa);
        });
        setState(() {
          recommendations = List<dynamic>.from(list);
          selectionsSummary =
              sel is Map ? Map<String, dynamic>.from(sel) : null;
          isLoading = false;
        });

        // 각 추천 장소의 상세 정보 가져오기
        for (var rec in recommendations) {
          final locationId = rec['id'] ?? rec['_id'] ?? '';
          if (locationId.isNotEmpty) {
            _fetchLocationDetails(locationId);
          }
        }
        return;
      }
    }
    // 인자가 없으면 기존 방식으로 페치
    fetchRecommendations();
  }

  Future<void> fetchRecommendations() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '';
    final token = prefs.getString('token') ?? '';
    final url = 'http://localhost:8001/api/recommend/$userId';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> allRecommendations = data['recommendations'] ?? [];

        // 충청도 지역 목록
        final chungcheongRegions = ['충북', '충남', '대전', '세종'];

        // 충청도 장소와 기타 장소를 분리
        final chungcheongPlaces = allRecommendations.where((rec) {
          final city = rec['city'] ?? rec['address'] ?? '';
          return chungcheongRegions.any((region) => city.contains(region));
        }).toList();

        final otherPlaces = allRecommendations.where((rec) {
          final city = rec['city'] ?? rec['address'] ?? '';
          return !chungcheongRegions.any((region) => city.contains(region));
        }).toList();

        // 충청도 장소를 앞에, 기타 장소를 뒤에 배치
        setState(() {
          recommendations = [...chungcheongPlaces, ...otherPlaces];
        });
      }
    } catch (_) {
    } finally {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
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

  Future<void> _runPredict() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    final result = await _predictService.analyzeSentiment(text);
    if (!mounted) return;
    setState(() {
      predictResult = result;
    });
  }

  // 선택 요약 칩 그룹 빌더
  Widget _chipGroup(String title, List<String> items) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.lightWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$title: ',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.deepGrean,
            ),
          ),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: items
                .map((e) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        e,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text(
            '추천 결과',
            style: TextStyle(
              color: AppColors.deepGrean,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppColors.deepGrean),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.grey))
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (selectionsSummary != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '선택한 조건',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  if (selectionsSummary!['지역'] != null &&
                                      (selectionsSummary!['지역'] as List)
                                          .isNotEmpty)
                                    _chipGroup(
                                        '지역',
                                        List<String>.from(
                                            selectionsSummary!['지역'])),
                                  if ((selectionsSummary!['동행'] ?? '')
                                      .toString()
                                      .isNotEmpty)
                                    _chipGroup('동행',
                                        [selectionsSummary!['동행'].toString()]),
                                  if ((selectionsSummary!['계절'] ?? '')
                                      .toString()
                                      .isNotEmpty)
                                    _chipGroup('계절',
                                        [selectionsSummary!['계절'].toString()]),
                                  if ((selectionsSummary!['장소 유형'] ?? '')
                                      .toString()
                                      .isNotEmpty)
                                    _chipGroup('장소 유형', [
                                      selectionsSummary!['장소 유형'].toString()
                                    ]),
                                  if ((selectionsSummary!['활동'] ?? '')
                                      .toString()
                                      .isNotEmpty)
                                    _chipGroup('활동',
                                        [selectionsSummary!['활동'].toString()]),
                                  if (selectionsSummary!['편의시설'] != null &&
                                      (selectionsSummary!['편의시설'] as List)
                                          .isNotEmpty)
                                    _chipGroup(
                                        '편의시설',
                                        List<String>.from(
                                            selectionsSummary!['편의시설'])),
                                ],
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 20),
                      ...recommendations.map((rec) {
                        final placeId = rec['id'] ?? rec['_id'] ?? '';
                        final locationDetail = _locationDetails[placeId];

                        // 이미지 URL 가져오기
                        final imageUrl = locationDetail?['firstimage'] ??
                            locationDetail?['firstimage2'] ??
                            rec['image'] ??
                            rec['firstimage'] ??
                            rec['firstimage2'] ??
                            '';

                        // 여행지 이름
                        final title = locationDetail?['title'] ??
                            rec['title'] ??
                            '이름 없는 장소';

                        // 주소
                        final address = locationDetail?['address'] ??
                            locationDetail?['addr1'] ??
                            rec['address'] ??
                            rec['addr1'] ??
                            '주소 정보 없음';

                        final isLoadingDetail =
                            _loadingLocations.contains(placeId);

                        return GestureDetector(
                          onTap: () {
                            if (placeId.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("❌ 장소 정보를 불러올 수 없습니다."),
                                ),
                              );
                              return;
                            }

                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => DetailPage(
                                          placeId: placeId,
                                          placeName: title,
                                        )));
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
                                              Icons
                                                  .image_not_supported_outlined,
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
                                          loadingBuilder: (context, child,
                                              loadingProgress) {
                                            if (loadingProgress == null)
                                              return child;
                                            return Container(
                                              width: 120,
                                              height: 120,
                                              color: Colors.grey[200],
                                              child: const Center(
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: AppColors.deepGrean,
                                                ),
                                              ),
                                            );
                                          },
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Container(
                                              width: 120,
                                              height: 120,
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
                                // 여행지 이름과 주소
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
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
                      }),
                    ],
                  ),
                ),
              ),
        bottomNavigationBar: const BottomNavi());
  }
}
