// pages/recommend/setFeaturesPage.dart
import 'package:pik/pages/home/HomePage.dart';
import 'package:pik/styles/styles.dart';
import 'package:pik/widgets/BottomNavi.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pik/pages/recommend/resultPage.dart';

class FeaturesPage extends StatefulWidget {
  const FeaturesPage({super.key});

  @override
  State<FeaturesPage> createState() => _FeaturesPageState();
}

class _FeaturesPageState extends State<FeaturesPage> {
  List<Map<String, dynamic>> features = [];
  Set<String> selectedFeatures = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchFeatures();
  }

  Future<void> fetchFeatures() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final response = await http.get(
        Uri.parse('http://localhost:8001/api/features'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          features = List<Map<String, dynamic>>.from(data['features'])
              .where((feature) =>
                  feature['name'] != '장소' && feature['name'] != '활동')
              .toList();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load features');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ 편의성 항목을 불러오는데 실패했습니다.')),
      );
    }
  }

  Future<void> saveCategorySelections(List<String> selectedIds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final response = await http.post(
        Uri.parse('http://localhost:8001/api/categories/selections'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'selections': selectedIds,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // data['selections']는 리스트 형태
        debugPrint('카테고리 선택 결과: $data');
        // 필요하다면 결과를 SharedPreferences 등에 저장하거나 화면 이동 등 처리
      } else {
        throw Exception('Failed to save category selections');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ 카테고리 선택 저장에 실패했습니다.')),
      );
    }
  }

  Future<void> saveSelectedFeatures() async {
    if (selectedFeatures.isEmpty) {
      debugPrint('No features selected.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❗ 최소 1개 이상의 항목을 선택해주세요.')),
      );
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final userId = prefs.getString('userId') ?? '';
      final orderedSelections =
          prefs.getStringList('selectedFeatures') ?? selectedFeatures.toList();
      debugPrint('Ordered selected features: $orderedSelections');
      // 1. features POST (배열로 전달)
      final response = await http.post(
        Uri.parse(
            'http://localhost:8001/api/users/$userId/keyword-preferences'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "keywordPreferences": orderedSelections
        }), // key를 keywordPreferences로 변경
      );
      debugPrint('Features POST status: ${response.statusCode}');
      debugPrint('Features POST response: ${response.body}');
      // 2. categories POST (배열로 전달)
      final String withId = prefs.getString('selectedWithKeywordId') ?? '';
      final String themeId = prefs.getString('selectedThemeKeywordId') ?? '';
      final String activityId =
          prefs.getString('selectedActivityKeywordId') ?? '';
      final String seasonId = prefs.getString('selectedSeasonKeywordId') ?? '';
      final List<String> selections = [withId, themeId, activityId, seasonId]
          .where((id) => id.isNotEmpty)
          .toList();
      debugPrint('Category selections: $selections');
      final catResponse = await http.post(
        Uri.parse('http://localhost:8001/api/users/$userId/preferences'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({"preferences": selections}), // key를 preferences로 변경
      );
      debugPrint('catResponse: $selections');
      debugPrint('Categories POST status: ${catResponse.statusCode}');
      debugPrint('Categories POST response: ${catResponse.body}');
      if (response.statusCode == 200) {
        await prefs.setStringList('selectedFeatures', orderedSelections);
        debugPrint('Selected features saved to prefs.');
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ResultPage()),
          );
        }
      } else {
        debugPrint('Failed to save selections: ${response.body}');
        throw Exception('Failed to save selections');
      }
    } catch (e) {
      debugPrint('Error in saveSelectedFeatures: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ 선택 저장에 실패했습니다.')),
      );
    }
  }

  void toggleFeature(String featureId) {
    setState(() {
      if (selectedFeatures.contains(featureId)) {
        selectedFeatures.remove(featureId);
      } else {
        if (selectedFeatures.length < 3) {
          selectedFeatures.add(featureId);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❗ 최대 3개까지만 선택할 수 있습니다.')),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actionsPadding: const EdgeInsets.only(right: 3.0),
        backgroundColor: AppColors.lightWhite,
        automaticallyImplyLeading: false,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.lightGray),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            child: const Text(
              "돌아가기",
              style: TextStyle(color: AppColors.lightGray),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HomePage(),
                ),
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.grey))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '이번 여행에서 중요하게 생각하는게 있나요?',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.deepGrean,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '최대 3개까지 선택 가능합니다. (${selectedFeatures.length}/3)',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 2.5,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: features.length,
                    itemBuilder: (context, index) {
                      final feature = features[index];
                      final isSelected =
                          selectedFeatures.contains(feature['_id']);
                      return InkWell(
                        onTap: () => toggleFeature(feature['_id']),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.mainGreen.withOpacity(0.2)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.mainGreen
                                  : Colors.grey[300]!,
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              feature['name'],
                              style: TextStyle(
                                color: isSelected
                                    ? AppColors.deepGrean
                                    : Colors.grey[800],
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: saveSelectedFeatures,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.mainGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '결과 보러가기',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: const BottomNavi(),
    );
  }
}
