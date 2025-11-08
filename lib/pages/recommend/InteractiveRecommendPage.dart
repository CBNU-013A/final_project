// pages/recommend/InteractiveRecommendPage.dart
import 'dart:async';
import 'package:pik/pages/location/DetailPage.dart';
import 'package:pik/services/location_service.dart';
import 'package:pik/services/recommendation_service.dart';
import 'package:pik/styles/styles.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InteractiveRecommendPage extends StatefulWidget {
  const InteractiveRecommendPage({Key? key}) : super(key: key);

  @override
  State<InteractiveRecommendPage> createState() =>
      _InteractiveRecommendPageState();
}

class _InteractiveRecommendPageState extends State<InteractiveRecommendPage>
    with TickerProviderStateMixin {
  final RecommendationService _recommendService = RecommendationService();
  final LocationService _locationService = LocationService();

  int _currentStep = 0;
  bool _isLoading = false;

  // 선택된 값들
  List<String> _selectedCities = [];
  String _selectedAccompany = '';
  String _selectedSeason = '';
  String _selectedPlace = '';
  String _selectedActivity = '';
  List<String> _selectedConveniences = [];

  // 실시간 추천 관련
  bool _isLoadingLive = false;
  List<dynamic> _liveRecommendations = [];
  Timer? _debounceTimer;
  Map<String, Map<String, dynamic>> _locationDetails = {};
  Set<String> _loadingLocations = {};

  // ObjectId 매핑 (텍스트 -> ObjectId)
  final Map<String, String> _accompanyIds = {
    '혼자': '68cabaf0a9613e0e59a214cf',
    '친구': '68cabaf0a9613e0e59a214d0',
    '연인': '68cabaf0a9613e0e59a214d1',
    '가족': '68cabaf0a9613e0e59a214d2',
    '반려동물': '68cabaf0a9613e0e59a214d3',
  };

  final Map<String, String> _seasonIds = {
    '봄': '68cabaf0a9613e0e59a214d4',
    '여름': '68cabaf0a9613e0e59a214d5',
    '가을': '68cabaf0a9613e0e59a214d6',
    '겨울': '68cabaf0a9613e0e59a214d7',
  };

  final Map<String, String> _placeIds = {
    '자연': '68cabaf0a9613e0e59a214d8',
    '문화': '68cabaf0a9613e0e59a214d9',
    '역사': '68cabaf0a9613e0e59a214da',
    '쇼핑': '68cabaf0a9613e0e59a214db',
    '맛집': '68cabaf0a9613e0e59a214dc',
  };

  final Map<String, String> _activityIds = {
    '관람': '68cabaf0a9613e0e59a214dd',
    '체험': '68cabaf0a9613e0e59a214de',
    '휴식': '68cabaf0a9613e0e59a214df',
    '운동': '68cabaf0a9613e0e59a214e0',
    '사진촬영': '68cabaf0a9613e0e59a214e1',
  };

  final Map<String, String> _convenienceIds = {
    '주차': '6835e145a853cdd2f586acbd',
    '혼잡도': '6835e145a853cdd2f586acc1',
    '교통': '6835e145a853cdd2f586acc8',
    '청결/관리': '6835e145a853cdd2f586acc9',
    '가격': '6835e145a853cdd2f586acc3',
  };

  // 애니메이션 컨트롤러
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _cleanupCitySelections();
  }

  // 도시 선택 목록 정리
  void _cleanupCitySelections() {
    final validCities = [
      '청주',
      '충주',
      '제천',
      '보은',
      '옥천',
      '영동',
      '증평',
      '진천',
      '괴산',
      '음성',
      '단양'
    ];

    // 유효한 도시만 필터링 (짧은 이름 형식으로)
    final newSelectedCities = <String>[];
    for (var city in _selectedCities) {
      // "충북 청주" -> "청주"로 변환
      final shortName = city.replaceFirst('충북 ', '');
      if (validCities.contains(shortName)) {
        newSelectedCities.add(shortName);
      }
    }

    setState(() {
      _selectedCities = newSelectedCities;
    });

    debugPrint('🔄 도시 선택 정리 완료: $_selectedCities');
  }

  void _setupAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  // 실시간 추천 가져오기
  Future<void> _fetchLiveRecommendations() async {
    // 선택이 하나도 없으면 결과를 비우고 종료
    final noSelection = _selectedCities.isEmpty &&
        _selectedAccompany.isEmpty &&
        _selectedSeason.isEmpty &&
        _selectedPlace.isEmpty &&
        _selectedActivity.isEmpty &&
        _selectedConveniences.isEmpty;

    if (noSelection) {
      setState(() {
        _isLoadingLive = false;
        _liveRecommendations = [];
      });
      debugPrint('🧹 선택 없음 → 실시간 추천 결과 비움');
      return;
    }

    setState(() {
      _isLoadingLive = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId') ?? '';
      final token = prefs.getString('token') ?? '';

      final userSelections = <String, dynamic>{};

      // city도 선택했을 때만 추가
      if (_selectedCities.isNotEmpty) {
        userSelections['city'] = _selectedCities;
      }

      // 선택된 값만 추가 (빈 값은 제외) - ObjectId로 변환
      if (_selectedAccompany.isNotEmpty) {
        userSelections['accompany'] =
            _accompanyIds[_selectedAccompany] ?? _selectedAccompany;
      }
      if (_selectedSeason.isNotEmpty) {
        userSelections['season'] =
            _seasonIds[_selectedSeason] ?? _selectedSeason;
      }
      if (_selectedPlace.isNotEmpty) {
        userSelections['place'] = _placeIds[_selectedPlace] ?? _selectedPlace;
      }
      if (_selectedActivity.isNotEmpty) {
        userSelections['activity'] =
            _activityIds[_selectedActivity] ?? _selectedActivity;
      }
      if (_selectedConveniences.isNotEmpty) {
        debugPrint('🔍 선택된 편의시설: $_selectedConveniences');
        final convenienceIds = _selectedConveniences.map((c) {
          final id = _convenienceIds[c];
          debugPrint('🔍 "$c" → ${id ?? "매핑 없음 (원본 사용)"}');
          return id ?? c;
        }).toList();
        userSelections['conveniences'] = convenienceIds;
        debugPrint('🔍 변환된 ObjectIds: $convenienceIds');
        debugPrint(
            '🔍 userSelections에 저장 후: ${userSelections['conveniences']}');
      }

      // API 요청 전 디버그 로그
      debugPrint('📤 API 요청 전 전체 userSelections: $userSelections');
      debugPrint('📤 편의시설 필드 확인: ${userSelections['conveniences']}');
      debugPrint('📤 타입 확인: ${userSelections['conveniences'].runtimeType}');

      final result = await _recommendService.getRecommendationsByUserSelection(
        userId: userId,
        token: token,
        userSelections: userSelections,
      );

      if (result['success'] == true) {
        final recommendations =
            result['data']['recommendations'] as List? ?? [];
        setState(() {
          _liveRecommendations = recommendations;
        });

        // 각 추천 장소의 상세 정보 가져오기
        for (var rec in _liveRecommendations) {
          final locationId = rec['id'] ?? rec['_id'] ?? '';
          if (locationId.isNotEmpty) {
            _fetchLocationDetails(locationId);
          }
        }
      } else {
        setState(() {
          _liveRecommendations = [];
        });
      }
    } catch (error) {
      setState(() {
        _liveRecommendations = [];
      });
    } finally {
      setState(() {
        _isLoadingLive = false;
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
      debugPrint('🔍 장소 상세 정보 조회 시작: $locationId');
      final locationData = await _locationService.fetchLocation(locationId);
      debugPrint('✅ 장소 상세 정보 조회 성공: ${locationData['title']}');
      debugPrint('📷 이미지 URL: ${locationData['firstimage'] ?? '없음'}');
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

  void _nextStep() {
    if (!_canProceed()) return;

    if (_currentStep < 5) {
      setState(() {
        _currentStep++;
      });
      _slideController.reset();
      _slideController.forward();
    } else {
      _getRecommendations();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _slideController.reset();
      _slideController.forward();
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _getRecommendations() async {
    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '';
    final token = prefs.getString('token') ?? '';

    final userSelections = <String, dynamic>{};

    // city도 선택했을 때만 추가
    if (_selectedCities.isNotEmpty) {
      userSelections['city'] = _selectedCities;
    }

    // 선택된 값만 추가 (빈 값은 제외) - ObjectId로 변환
    if (_selectedAccompany.isNotEmpty) {
      userSelections['accompany'] =
          _accompanyIds[_selectedAccompany] ?? _selectedAccompany;
    }
    if (_selectedSeason.isNotEmpty) {
      userSelections['season'] = _seasonIds[_selectedSeason] ?? _selectedSeason;
    }
    if (_selectedPlace.isNotEmpty) {
      userSelections['place'] = _placeIds[_selectedPlace] ?? _selectedPlace;
    }
    if (_selectedActivity.isNotEmpty) {
      userSelections['activity'] =
          _activityIds[_selectedActivity] ?? _selectedActivity;
    }
    if (_selectedConveniences.isNotEmpty) {
      debugPrint('🔍 [최종] 선택된 편의시설: $_selectedConveniences');
      final convenienceIds = _selectedConveniences.map((c) {
        final id = _convenienceIds[c];
        debugPrint('🔍 [최종] "$c" → ${id ?? "매핑 없음 (원본 사용)"}');
        return id ?? c;
      }).toList();
      userSelections['conveniences'] = convenienceIds;
      debugPrint('🔍 [최종] 변환된 ObjectIds: $convenienceIds');
      debugPrint(
          '🔍 [최종] userSelections에 저장 후: ${userSelections['conveniences']}');
    }

    // API 요청 전 디버그 로그
    debugPrint('📤 [최종] API 요청 전 전체 userSelections: $userSelections');
    debugPrint('📤 [최종] 편의시설 필드 확인: ${userSelections['conveniences']}');
    debugPrint('📤 [최종] 타입 확인: ${userSelections['conveniences'].runtimeType}');

    final result = await _recommendService.getRecommendationsByUserSelection(
      userId: userId,
      token: token,
      userSelections: userSelections,
    );

    setState(() {
      _isLoading = false;
    });

    if (result['success'] == true) {
      // 사람이 읽기 쉬운 선택 요약
      final selectedSummary = {
        '지역': List<String>.from(_selectedCities),
        '동행': _selectedAccompany,
        '계절': _selectedSeason,
        '장소 유형': _selectedPlace,
        '활동': _selectedActivity,
        '편의시설': List<String>.from(_selectedConveniences),
      };

      Navigator.pushReplacementNamed(
        context,
        '/recommendation/result',
        arguments: {
          'data': result['data'],
          'selections': selectedSummary,
        },
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('추천을 가져오는데 실패했습니다: ${result['error']}')),
        );
      }
    }
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _selectedCities.isNotEmpty;
      case 1:
        return _selectedAccompany.isNotEmpty;
      case 2:
        return _selectedSeason.isNotEmpty;
      case 3:
        return _selectedPlace.isNotEmpty;
      case 4:
        return _selectedActivity.isNotEmpty;
      case 5:
        return true;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        scrolledUnderElevation: 0,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.deepGrean),
          onPressed: _previousStep,
        ),
        title: Column(
          children: [
            Text(
              '추천 받기',
              style: TextStyle(
                color: AppColors.deepGrean,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.home_outlined, color: AppColors.deepGrean),
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/homepage',
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.grey),
                ],
              ),
            )
          : Column(
              children: [
                // 상단: 진행률 바
                _buildProgressBar(),
                // 메인 컨텐츠
                Expanded(
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: _buildCurrentStep(),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildProgressSidebar() {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: AppColors.mainGreen.withOpacity(0.05),
        border: Border(right: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '진행 상황',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepGrean,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.mainGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_currentStep + 1}/6',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildStepItem(0, '🏙️', '지역 선택', _selectedCities.join(', ')),
                _buildStepItem(1, '👥', '동행 선택', _selectedAccompany),
                _buildStepItem(2, '🌤️', '계절 선택', _selectedSeason),
                _buildStepItem(3, '🏛️', '장소 유형', _selectedPlace),
                _buildStepItem(4, '🎯', '활동 선택', _selectedActivity),
                _buildStepItem(
                    5,
                    '✨',
                    '편의시설',
                    _selectedConveniences.isEmpty
                        ? ''
                        : _selectedConveniences.join(', ')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(int step, String icon, String title, String selection) {
    final isCompleted = step < _currentStep;
    final isCurrent = step == _currentStep;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrent ? AppColors.mainGreen.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrent
              ? AppColors.mainGreen
              : isCompleted
                  ? Colors.grey[300]!
                  : Colors.grey[200]!,
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                    color: isCurrent ? AppColors.mainGreen : Colors.black87,
                  ),
                ),
                if (selection.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    selection,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (isCompleted)
            Icon(Icons.check_circle, color: AppColors.mainGreen, size: 20),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final steps = [
      {'icon': '🏙️', 'title': '지역'},
      {'icon': '👥', 'title': '동행'},
      {'icon': '🌤️', 'title': '계절'},
      {'icon': '🏛️', 'title': '장소'},
      {'icon': '🎯', 'title': '활동'},
      {'icon': '✨', 'title': '편의시설'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 진행률 텍스트
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //   children: [
          //     Text(
          //       '진행 단계',
          //       style: TextStyle(
          //         fontSize: 16,
          //         fontWeight: FontWeight.w700,
          //         color: AppColors.deepGrean,
          //       ),
          //     ),
          //     Container(
          //       padding:
          //           const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          //       decoration: BoxDecoration(
          //         color: AppColors.mainGreen,
          //         borderRadius: BorderRadius.circular(12),
          //       ),
          //       child: Text(
          //         '${_currentStep + 1}/6',
          //         style: const TextStyle(
          //           color: Colors.white,
          //           fontSize: 12,
          //           fontWeight: FontWeight.w600,
          //         ),
          //       ),
          //     ),
          //   ],
          // ),
          // 진행률 바
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (index) {
              // 각 단계별 선택 여부 확인
              bool isCompleted = false;
              switch (index) {
                case 0: // 지역
                  isCompleted = _selectedCities.isNotEmpty;
                  break;
                case 1: // 동행
                  isCompleted = _selectedAccompany.isNotEmpty;
                  break;
                case 2: // 계절
                  isCompleted = _selectedSeason.isNotEmpty;
                  break;
                case 3: // 장소
                  isCompleted = _selectedPlace.isNotEmpty;
                  break;
                case 4: // 활동
                  isCompleted = _selectedActivity.isNotEmpty;
                  break;
                case 5: // 편의시설
                  isCompleted = _selectedConveniences.isNotEmpty;
                  break;
              }
              final isCurrent = index == _currentStep;
              final step = steps[index];

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (index != _currentStep) {
                      setState(() {
                        _currentStep = index;
                      });
                      _slideController.reset();
                      _slideController.forward();
                    }
                  },
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Column(
                      children: [
                        // 아이콘과 체크
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? Colors.white
                                : isCompleted
                                    ? AppColors.mainGreen.withOpacity(0.2)
                                    : Colors.grey[200],
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isCurrent || isCompleted
                                  ? AppColors.mainGreen
                                  : Colors.grey[300]!,
                              width: isCurrent ? 3 : 2,
                            ),
                          ),
                          child: Center(
                            child: isCompleted
                                ? Icon(
                                    Icons.check,
                                    color: AppColors.mainGreen,
                                    size: 20,
                                  )
                                : Text(
                                    step['icon']!,
                                    style: const TextStyle(
                                      fontSize: 20,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // 단계 이름
                        Text(
                          step['title']!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                isCurrent ? FontWeight.w600 : FontWeight.w400,
                            color: isCurrent
                                ? AppColors.mainGreen
                                : isCompleted
                                    ? Colors.black87
                                    : Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          // 연결선
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Stack(
              children: [
                // 전체 배경선
                Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                // 진행된 부분
                FractionallySizedBox(
                  widthFactor: (_currentStep) / 5,
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      color: AppColors.mainGreen,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildCitySelection();
      case 1:
        return _buildAccompanySelection();
      case 2:
        return _buildSeasonSelection();
      case 3:
        return _buildPlaceSelection();
      case 4:
        return _buildActivitySelection();
      case 5:
        return _buildConvenienceSelection();
      default:
        return const SizedBox();
    }
  }

  // 도시 선택 단계
  Widget _buildCitySelection() {
    // 충청북도 시/군 목록
    final cities = [
      '청주',
      '충주',
      '제천',
      '보은',
      '옥천',
      '영동',
      '증평',
      '진천',
      '괴산',
      '음성',
      '단양',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '어떤 지역의 장소를 추천받고 싶나요?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.deepGrean,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '최대 3개까지 선택 가능합니다. (${_selectedCities.length}/3)',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: cities.map((city) {
              final isSelected = _selectedCities.contains(city);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedCities.remove(city);
                      debugPrint('🗑️ 도시 제거: $city');
                    } else {
                      if (_selectedCities.length < 3) {
                        _selectedCities.add(city);
                        debugPrint('✅ 도시 추가: $city');
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('최대 3개까지만 선택할 수 있습니다.'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    }
                    debugPrint(
                        '📍 현재 선택된 도시들: $_selectedCities (${_selectedCities.length}개)');
                    // 실시간 추천 업데이트
                    _fetchLiveRecommendations();
                  });
                },
                child: Container(
                  width: (MediaQuery.of(context).size.width - 72) / 3,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.mainGreen.withOpacity(0.1)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color:
                          isSelected ? AppColors.mainGreen : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Text(
                          city,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? AppColors.deepGrean
                                : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          // 실시간 추천 결과
          if (_liveRecommendations.isNotEmpty) ...[
            const SizedBox(height: 32),
            Divider(color: Colors.grey[300]),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '실시간 추천 결과',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepGrean,
                  ),
                ),
                if (_isLoadingLive)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.mainGreen,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _buildLiveRecommendationsList(),
          ],
        ],
      ),
    );
  }

  // 실시간 추천 리스트 (검색 페이지 UI 스타일)
  Widget _buildLiveRecommendationsList() {
    if (_isLoadingLive) {
      return const SizedBox();
    }

    if (_liveRecommendations.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            '추천 결과가 없습니다',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _liveRecommendations.length,
      itemBuilder: (context, index) {
        final rec = _liveRecommendations[index];
        final locationId = rec['id'] ?? rec['_id'] ?? '';

        // 장소 상세 정보에서 이미지 가져오기
        final locationDetail = _locationDetails[locationId];
        final imageUrl = locationDetail?['firstimage'] ??
            locationDetail?['firstimage2'] ??
            rec['image'] ??
            rec['firstimage'] ??
            rec['firstimage2'] ??
            '';
        final title = locationDetail?['title'] ?? rec['title'] ?? '이름 없는 장소';

        return GestureDetector(
          onTap: () {
            if (locationId.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailPage(
                    placeId: locationId,
                    placeName: title,
                  ),
                ),
              );
            }
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
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
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
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
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
    );
  }

  // 동행 선택 단계
  Widget _buildAccompanySelection() {
    final options = ['혼자', '친구', '연인', '가족', '반려동물'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '누구와 함께 가나요?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.deepGrean,
            ),
          ),

          const SizedBox(height: 22),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: options.map((option) {
              final isSelected = _selectedAccompany == option;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    // 같은 옵션을 클릭하면 선택 해제 (토글)
                    // 다른 옵션을 클릭하면 이전 선택이 풀리고 새로운 옵션 선택
                    if (isSelected) {
                      _selectedAccompany = '';
                    } else {
                      _selectedAccompany = option;
                    }
                    // 실시간 추천 업데이트
                    _fetchLiveRecommendations();
                  });
                },
                child: Container(
                  width: (MediaQuery.of(context).size.width - 72) / 3,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.mainGreen.withOpacity(0.1)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color:
                          isSelected ? AppColors.mainGreen : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Text(
                          option,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? AppColors.deepGrean
                                : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          // 실시간 추천 결과
          if (_liveRecommendations.isNotEmpty) ...[
            const SizedBox(height: 32),
            Divider(color: Colors.grey[300]),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '실시간 추천 결과',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepGrean,
                  ),
                ),
                if (_isLoadingLive)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.mainGreen,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _buildLiveRecommendationsList(),
          ],
        ],
      ),
    );
  }

  // 계절 선택 단계
  Widget _buildSeasonSelection() {
    final options = ['봄', '여름', '가을', '겨울'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '선호하는 계절이 있나요?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.deepGrean,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '하나를 선택해주세요',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: options.map((option) {
              final isSelected = _selectedSeason == option;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    // 토글: 같은 옵션 클릭 시 선택 해제
                    if (isSelected) {
                      _selectedSeason = '';
                    } else {
                      _selectedSeason = option;
                    }
                    // 실시간 추천 업데이트
                    _fetchLiveRecommendations();
                  });
                },
                child: Container(
                  width: (MediaQuery.of(context).size.width - 72) / 3,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.mainGreen.withOpacity(0.1)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color:
                          isSelected ? AppColors.mainGreen : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      option,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color:
                            isSelected ? AppColors.deepGrean : Colors.black87,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          // 실시간 추천 결과
          if (_liveRecommendations.isNotEmpty) ...[
            const SizedBox(height: 32),
            Divider(color: Colors.grey[300]),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '실시간 추천 결과',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepGrean,
                  ),
                ),
                if (_isLoadingLive)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.mainGreen,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _buildLiveRecommendationsList(),
          ],
        ],
      ),
    );
  }

  // 장소 유형 선택 단계
  Widget _buildPlaceSelection() {
    final options = ['자연', '문화', '역사', '쇼핑', '맛집'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '어떤 장소를 선호하시나요?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.deepGrean,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '하나를 선택해주세요',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: options.map((option) {
              final isSelected = _selectedPlace == option;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    // 토글: 같은 옵션 클릭 시 선택 해제
                    if (isSelected) {
                      _selectedPlace = '';
                    } else {
                      _selectedPlace = option;
                    }
                    // 실시간 추천 업데이트
                    _fetchLiveRecommendations();
                  });
                },
                child: Container(
                  width: (MediaQuery.of(context).size.width - 72) / 3,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.mainGreen.withOpacity(0.1)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color:
                          isSelected ? AppColors.mainGreen : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      option,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color:
                            isSelected ? AppColors.deepGrean : Colors.black87,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          // 실시간 추천 결과
          if (_liveRecommendations.isNotEmpty) ...[
            const SizedBox(height: 32),
            Divider(color: Colors.grey[300]),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '실시간 추천 결과',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepGrean,
                  ),
                ),
                if (_isLoadingLive)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.mainGreen,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _buildLiveRecommendationsList(),
          ],
        ],
      ),
    );
  }

  // 활동 선택 단계
  Widget _buildActivitySelection() {
    final options = ['관람', '체험', '휴식', '운동', '사진촬영'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '주로 어떤 활동을 하시나요?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.deepGrean,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '하나를 선택해주세요',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: options.map((option) {
              final isSelected = _selectedActivity == option;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    // 토글: 같은 옵션 클릭 시 선택 해제
                    if (isSelected) {
                      _selectedActivity = '';
                    } else {
                      _selectedActivity = option;
                    }
                    // 실시간 추천 업데이트
                    _fetchLiveRecommendations();
                  });
                },
                child: Container(
                  width: (MediaQuery.of(context).size.width - 72) / 3,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.mainGreen.withOpacity(0.1)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color:
                          isSelected ? AppColors.mainGreen : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      option,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color:
                            isSelected ? AppColors.deepGrean : Colors.black87,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          // 실시간 추천 결과
          if (_liveRecommendations.isNotEmpty) ...[
            const SizedBox(height: 32),
            Divider(color: Colors.grey[300]),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '실시간 추천 결과',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepGrean,
                  ),
                ),
                if (_isLoadingLive)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.mainGreen,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _buildLiveRecommendationsList(),
          ],
        ],
      ),
    );
  }

  // 편의시설 선택 단계
  Widget _buildConvenienceSelection() {
    final options = ['주차', '혼잡도', '교통', '청결/관리', '가격'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '필요한 편의시설을 선택해주세요',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.deepGrean,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '여러 개 선택 가능합니다',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: options.map((option) {
              final isSelected = _selectedConveniences.contains(option);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedConveniences.remove(option);
                    } else {
                      _selectedConveniences.add(option);
                    }
                    // 실시간 추천 업데이트
                    _fetchLiveRecommendations();
                  });
                },
                child: Container(
                  width: (MediaQuery.of(context).size.width - 72) / 3,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.mainGreen.withOpacity(0.1)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color:
                          isSelected ? AppColors.mainGreen : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      option,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color:
                            isSelected ? AppColors.deepGrean : Colors.black87,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          // 실시간 추천 결과
          if (_liveRecommendations.isNotEmpty) ...[
            const SizedBox(height: 32),
            Divider(color: Colors.grey[300]),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '실시간 추천 결과',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepGrean,
                  ),
                ),
                Row(
                  children: [
                    if (_isLoadingLive)
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.mainGreen,
                        ),
                      ),
                    if (_isLoadingLive && _selectedConveniences.isNotEmpty)
                      const SizedBox(width: 12),
                    // 편의시설 선택 시 최종 결과 보기 버튼
                    if (_selectedConveniences.isNotEmpty)
                      ElevatedButton(
                        onPressed: _isLoading ? null : _getRecommendations,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.mainGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          disabledBackgroundColor: Colors.grey[300],
                        ),
                        child: _isLoading
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                '최종 결과 보기',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildLiveRecommendationsList(),
          ],
        ],
      ),
    );
  }

  // 공통 선택 UI 위젯
  Widget _buildSelectionStep({
    required String title,
    required String subtitle,
    required List<String> options,
    required String selectedValue,
    required Function(String) onSelect,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.deepGrean,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: options.map((option) {
              final isSelected = selectedValue == option;
              return GestureDetector(
                onTap: () => onSelect(option),
                child: Container(
                  width: (MediaQuery.of(context).size.width - 72) / 2,
                  height: 100,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.mainGreen : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color:
                          isSelected ? AppColors.mainGreen : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      option,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: AppColors.mainGreen),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  '이전',
                  style: TextStyle(
                    color: AppColors.mainGreen,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _canProceed() ? _nextStep : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.mainGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: Colors.grey[300],
              ),
              child: Text(
                _currentStep < 5 ? '다음' : '결과 보기',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveRecommendationsSidebar() {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              '실시간 추천 미리보기',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.deepGrean,
              ),
            ),
          ),
          Expanded(
            child: _isLoadingLive
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppColors.mainGreen,
                    ),
                  )
                : _liveRecommendations.isEmpty
                    ? Center(
                        child: Text(
                          '선택을 완료하면\n추천 결과를 미리 볼 수 있어요',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _liveRecommendations.length,
                        itemBuilder: (context, index) {
                          final rec = _liveRecommendations[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              dense: true,
                              title: Text(
                                rec['title'] ?? '장소 이름',
                                style: const TextStyle(fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                rec['city'] ?? '',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              trailing: Icon(
                                Icons.arrow_forward_ios,
                                size: 14,
                                color: Colors.grey[400],
                              ),
                              onTap: () {
                                if (rec['id'] != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DetailPage(
                                        placeId: rec['id'],
                                        placeName: rec['title'] ?? '',
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
