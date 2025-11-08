// widgets/detail/InfoTab.dart
import 'package:pik/pages/location/DetailPage.dart';
import 'package:pik/services/location_service.dart';
import 'package:pik/services/random_location_service.dart';
import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_common/kakao_flutter_sdk_common.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:pik/styles/styles.dart';

class InfoTab extends StatefulWidget {
  final Map<String, dynamic> data;

  const InfoTab({Key? key, required this.data}) : super(key: key);

  @override
  State<InfoTab> createState() => _InfoTabState();
}

class _InfoTabState extends State<InfoTab> {
  KakaoMapController? _mapController;
  final locationService = LocationService();
  List<dynamic> nearbyPlaces = [];
  bool isLoadingNearby = true;

  @override
  void initState() {
    super.initState();
    KakaoSdk.init(
      nativeAppKey: '2a9e7d21868ff0932e17ad3708dcbe9b',
      javaScriptAppKey: 'c4e1eb2e4df9471dd1f08410194cfd13',
    );
    AuthRepository.initialize(appKey: 'c4e1eb2e4df9471dd1f08410194cfd13');
    _loadNearbyPlaces();
  }

  Future<void> _loadNearbyPlaces() async {
    setState(() {
      isLoadingNearby = true;
    });

    try {
      final allPlaces = await locationService.fetchAllLocations();
      final currentPlaceId = widget.data['_id'];
      final cityKey = widget.data['cityKey'];
      final sgg = widget.data['sgg'];

      // 같은 cityKey 또는 sgg를 가진 장소들 필터링 (현재 장소 제외)
      final nearby = allPlaces.where((place) {
        final placeId = place['_id'];
        if (placeId == currentPlaceId) return false;

        final placeCityKey = place['cityKey'];
        final placeSgg = place['sgg'];

        // cityKey 또는 sgg가 일치하는 경우
        return (cityKey != null && placeCityKey == cityKey) ||
            (sgg != null && placeSgg == sgg);
      }).toList();

      // 근처 여행지가 없으면 랜덤 여행지 가져오기
      if (nearby.isEmpty) {
        debugPrint('근처 여행지 없음 - 랜덤 여행지 로드');
        final randomPlaces = await RandomLocationService.getRandomLocations();

        // 현재 장소 제외
        final filteredRandom = randomPlaces.where((place) {
          final placeId = place['_id'] ?? place['id'];
          return placeId != currentPlaceId;
        }).toList();

        setState(() {
          nearbyPlaces = filteredRandom.take(6).toList();
          isLoadingNearby = false;
        });
      } else {
        // 랜덤으로 섞어서 6개만 표시
        nearby.shuffle();
        setState(() {
          nearbyPlaces = nearby.take(6).toList();
          isLoadingNearby = false;
        });
      }
    } catch (e) {
      debugPrint('근처 여행지 로드 실패: $e');
      setState(() {
        isLoadingNearby = false;
      });
    }
  }

  void setMapCenter(Map<String, dynamic> data) {
    if (_mapController != null) {
      _mapController!.setCenter(
        LatLng(
          data['location']['latitude'],
          data['location']['longitude'],
        ),
      );
    } else {
      debugPrint("⚠️ KakaoMapController가 아직 초기화되지 않았습니다.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;

    // mapx, mapy가 있으면 location을 생성
    if (data['location'] == null &&
        data['mapx'] != null &&
        data['mapy'] != null) {
      data['location'] = {
        'latitude': (data['mapy'] is String)
            ? double.tryParse(data['mapy']) ?? 0.0
            : data['mapy'],
        'longitude': (data['mapx'] is String)
            ? double.tryParse(data['mapx']) ?? 0.0
            : data['mapx'],
      };
    }

    if (data['location'] == null ||
        data['location']['latitude'] == null ||
        data['location']['longitude'] == null) {
      return const Center(child: Text("위치 정보 없음"));
    }

    debugPrint("📍 위치 데이터: ${data['location']}");

    try {
      double latitude = (data['location']['latitude'] is String)
          ? double.parse(data['location']['latitude'])
          : data['location']['latitude'];

      double longitude = (data['location']['longitude'] is String)
          ? double.parse(data['location']['longitude'])
          : data['location']['longitude'];

      LatLng location = LatLng(latitude, longitude);

      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 지도 섹션
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    SizedBox(
                      height: 220,
                      width: double.infinity,
                      child: KakaoMap(
                        center: location,
                        currentLevel: 4,
                        onMapCreated: (KakaoMapController controller) async {
                          debugPrint("🗺️ KakaoMap 컨트롤러 초기화 완료!");
                          _mapController = controller;

                          await controller.addMarker(markers: [
                            Marker(
                              width: 24,
                              height: 30,
                              markerId: data['id']?.toString() ?? 'default_id',
                              latLng: location,
                              infoWindowContent: data['title'],
                            ),
                          ]);
                        },
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: FloatingActionButton(
                        mini: true,
                        backgroundColor: Colors.white,
                        elevation: 2,
                        onPressed: () => setMapCenter(data),
                        child: const Icon(Icons.refresh, color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // 근처 여행지 섹션
              Container(
                decoration: BoxDecoration(
                  color: AppColors.lightWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(Icons.place, color: AppColors.mainGreen, size: 20),
                        SizedBox(width: 4),
                        Text(
                          '근처 여행지',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    if (isLoadingNearby)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(color: Colors.grey),
                        ),
                      )
                    else if (nearbyPlaces.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Center(
                          child: Text(
                            '근처에 추천할 여행지가 없습니다.',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.85,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: nearbyPlaces.length,
                        itemBuilder: (context, index) {
                          final place = nearbyPlaces[index];
                          return _buildNearbyPlaceCard(place);
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      debugPrint("❗ 위치 변환 중 오류 발생: $e");
      return const Center(child: Text("위치 정보를 불러오는 중 오류 발생"));
    }
  }

  Widget _buildNearbyPlaceCard(Map<String, dynamic> place) {
    final title = place['title'] ?? '제목 없음';
    final imageUrl = place['firstimage'] ?? '';
    final addr = place['addr1'] ?? '';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailPage(
              placeName: title,
              placeId: place['_id'].toString(),
            ),
          ),
        );
      },
      child: Container(
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
            // 이미지
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      height: 100,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 100,
                        color: Colors.grey[200],
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image_not_supported,
                                  size: 32, color: Colors.grey[400]),
                              const SizedBox(height: 4),
                              Text(
                                'No Image',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : Container(
                      height: 100,
                      color: Colors.grey[200],
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image_not_supported,
                                size: 32, color: Colors.grey[400]),
                            const SizedBox(height: 4),
                            Text(
                              'No Image',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
            // 정보
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    addr,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
