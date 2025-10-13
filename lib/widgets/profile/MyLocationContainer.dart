// widgets/profile/MyLocationContainer.dart
import 'package:pik/services/like_service.dart';
import 'package:pik/services/location_service.dart';
import 'package:pik/styles/styles.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';

class MyLocationContainer extends StatefulWidget {
  const MyLocationContainer({super.key});

  @override
  State<MyLocationContainer> createState() => _MyLocationContainerState();
}

class _MyLocationContainerState extends State<MyLocationContainer> {
  final likeService = LikeService();
  final locationService = LocationService();
  bool isLoading = true;
  String userName = '';
  String userId = '';
  String token = '';
  late SharedPreferences prefs;
  List<dynamic> likedPlaces = [];
  bool _showDetail = false;
  String? _currentAddress;
  bool _isLoading = true;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _loadCurrentAddress();
  }

  Future<void> _loadCurrentAddress() async {
    try {
      Position position = await _getCurrentLocation();

      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;

        setState(() {
          _currentPosition = position;
          _currentAddress =
              '${place.street}, ${place.locality}, ${place.administrativeArea} ${place.country}';
          _isLoading = false;
        });
      } else {
        setState(() {
          _currentPosition = position;
          _currentAddress = '주소 정보를 찾을 수 없습니다.';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("❗ 오류 발생: $e");
      setState(() {
        _currentAddress = '위치 정보를 가져올 수 없습니다.';
        _isLoading = false;
      });
    }
  }

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('위치 서비스 비활성화');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('위치 권한 거부됨');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('위치 권한 영구 거부됨');
    }

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
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
                    '내 위치',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.deepGrean,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              Container(
                margin: const EdgeInsets.only(right: 6),
                child: InkWell(
                  onTap: () async {
                    await Geolocator.openAppSettings();
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    height: 28,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.deepGrean,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "설정",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_showDetail)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.grey)
                  : Column(
                      children: [
                        // 주소 정보
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.lighterGreen.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.mainGreen.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 1),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 2, vertical: 1),
                              leading: const Icon(
                                Icons.place_outlined,
                                color: AppColors.mainGreen,
                                size: 18,
                              ),
                              title: Text(
                                _currentAddress ?? '주소 없음',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // 지도
                        if (_currentPosition != null)
                          Container(
                            height: 200,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.grey.shade300, width: 1),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: KakaoMap(
                              center: LatLng(_currentPosition!.latitude,
                                  _currentPosition!.longitude),
                              currentLevel: 4,
                              onMapCreated:
                                  (KakaoMapController controller) async {
                                await controller.addMarker(markers: [
                                  Marker(
                                    width: 24,
                                    height: 30,
                                    markerId: 'my_location',
                                    latLng: LatLng(_currentPosition!.latitude,
                                        _currentPosition!.longitude),
                                    infoWindowContent: '내 위치',
                                  ),
                                ]);
                              },
                            ),
                          ),
                      ],
                    ),
            )
        ],
      ),
    );
  }
}
