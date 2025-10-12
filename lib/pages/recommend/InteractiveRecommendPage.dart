// pages/recommend/InteractiveRecommendPage.dart
import 'dart:async';
import 'package:final_project/pages/location/DetailPage.dart';
import 'package:final_project/services/location_service.dart';
import 'package:final_project/services/recommendation_service.dart';
import 'package:final_project/styles/styles.dart';
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
  String? _liveError;
  Timer? _debounceTimer;
  Map<String, Map<String, dynamic>> _locationDetails = {};
  Set<String> _loadingLocations = {};

  // 애니메이션 컨트롤러
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  // 도시 목록
  final List<String> _cities = [
    '서울', '부산', '대구', '인천', '광주', '대전', '울산', '세종',
    '경기', '강원', '충북', '충남', '전북', '전남', '경북', '경남', '제주'
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
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
    if (_selectedCities.isEmpty) {
      setState(() {
        _liveRecommendations = [];
      });
      return;
    }

    setState(() {
      _isLoadingLive = true;
      _liveError = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId') ?? '';
      final token = prefs.getString('token') ?? '';

      final userSelections = {
        'city': _selectedCities,
        'accompany': _selectedAccompany,
        'season': _selectedSeason,
        'place': _selectedPlace,
        'activity': _selectedActivity,
        'conveniences': _selectedConveniences,
      };

      var result = await _recommendService.getRecommendationsByUserSelection(
        userId: userId,
        token: token,
        userSelections: userSelections,
      );

      if (result['success'] != true) {
        result = await _recommendService.getRecommendationHistory(
          userId: userId,
          token: token,
        );
      }

      if (result['success'] == true) {
        final recommendations = result['data']['recommendations'] as List? ?? [];
        setState(() {
          _liveRecommendations = recommendations.take(6).toList();
        });

        for (var rec in _liveRecommendations) {
          if (rec['id'] != null) {
            _fetchLocationDetails(rec['id']);
          }
        }
      } else {
        setState(() {
          _liveError = '추천 결과를 불러올 수 없습니다.';
          _liveRecommendations = [];
        });
      }
    } catch (error) {
      setState(() {
        _liveError = '추천 요청 중 오류가 발생했습니다.';
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
      final locationData = await _locationService.fetchLocation(locationId);
      setState(() {
        _locationDetails[locationId] = locationData;
      });
    } catch (error) {
      debugPrint('장소 상세 정보 가져오기 실패: $error');
    } finally {
      setState(() {
        _loadingLocations.remove(locationId);
      });
    }
  }

  void _updateLiveRecommendations() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 1), () {
      _fetchLiveRecommendations();
    });
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

    final userSelections = {
      'city': _selectedCities,
      'accompany': _selectedAccompany,
      'season': _selectedSeason,
      'place': _selectedPlace,
      'activity': _selectedActivity,
      'conveniences': _selectedConveniences,
    };

    final result = await _recommendService.getRecommendationsByUserSelection(
      userId: userId,
      token: token,
      userSelections: userSelections,
    );

    setState(() {
      _isLoading = false;
    });

    if (result['success'] == true) {
      Navigator.pushReplacementNamed(
        context,
        '/recommendation/result',
        arguments: result['data'],
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
            Text(
              '당신에게 맞는 완벽한 장소를 찾아드릴게요',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.grey),
                  const SizedBox(height: 20),
                  Text(
                    '당신을 위한 장소를 찾고 있어요...',
                    style: TextStyle(
                      color: AppColors.deepGrean,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          : Row(
              children: [
                // 왼쪽: 진행률 사이드바
                _buildProgressSidebar(),
                // 중앙: 메인 컨텐츠
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildProgressIndicator(),
                      Expanded(
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: _buildCurrentStep(),
                        ),
                      ),
                      _buildNavigationButtons(),
                    ],
                  ),
                ),
                // 오른쪽: 실시간 추천 사이드바
                if (_selectedCities.isNotEmpty)
                  _buildLiveRecommendationsSidebar(),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                _buildStepItem(0, '🏙️', '도시 선택', _selectedCities.join(', ')),
                _buildStepItem(1, '👥', '동행 선택', _selectedAccompany),
                _buildStepItem(2, '🌤️', '계절 선택', _selectedSeason),
                _buildStepItem(3, '🏛️', '장소 유형', _selectedPlace),
                _buildStepItem(4, '🎯', '활동 선택', _selectedActivity),
                _buildStepItem(5, '✨', '편의시설', _selectedConveniences.isEmpty ? '' : '${_selectedConveniences.length}개 선택'),
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
        color: isCurrent
            ? AppColors.mainGreen.withOpacity(0.1)
            : isCompleted
                ? Colors.white
                : Colors.grey[50],
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
