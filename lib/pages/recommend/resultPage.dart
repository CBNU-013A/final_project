// pages/recommend/resultPage.dart
import 'dart:convert';
import 'package:final_project/pages/location/DetailPage.dart';
import 'package:final_project/styles/styles.dart';
import 'package:final_project/widgets/BottomNavi.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:final_project/services/sentiment_service.dart';

class ResultPage extends StatefulWidget {
  const ResultPage({super.key});

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  bool isLoading = true;
  List<dynamic> recommendations = [];

  final TextEditingController _textController = TextEditingController();
  final SentimentService _predictService = SentimentService();
  Map<String, dynamic>? predictResult;

  @override
  void initState() {
    super.initState();
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
        setState(() {
          recommendations = data['recommendations'];
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

  Future<void> _runPredict() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    final result = await _predictService.analyzeSentiment(text);
    if (!mounted) return;
    setState(() {
      predictResult = result;
    });
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
                              '자연어 입력 (예: 여름에 할머니랑 산책하기 좋아요)',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _textController,
                                    decoration: const InputDecoration(
                                      hintText: '문장을 입력하세요',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: _runPredict,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.mainGreen,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('분석'),
                                )
                              ],
                            ),
                            if (predictResult != null) ...[
                              const SizedBox(height: 8),
                            ]
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      ...recommendations.map((rec) => GestureDetector(
                            onTap: () {
                              final placeId = rec['id'] ?? rec['_id'] ?? '';
                              final placeName = rec['title'] ?? '제목 없음';

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
                                            placeName: placeName,
                                          )));
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(0),
                              decoration: BoxDecoration(
                                color: AppColors.lighterGreen.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.mainGreen.withOpacity(0.1),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 18, vertical: 10),
                                title: Text(
                                  rec['title'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.deepGrean,
                                  ),
                                ),
                                subtitle: Row(
                                  children: [
                                    Text(
                                      '유사도: ${rec['similarity']}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      '점수: ${rec['finalScore']}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )),
                    ],
                  ),
                ),
              ),
        bottomNavigationBar: const BottomNavi());
  }
}
