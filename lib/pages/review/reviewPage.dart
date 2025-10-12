// pages/review/reviewPage.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../styles/styles.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

final String baseUrl = Platform.isAndroid
    ? 'http://${dotenv.env['BASE_URL']}:8001'
    : 'http://localhost:8001';

class ReviewWidget extends StatefulWidget {
  final String place;

  const ReviewWidget({Key? key, required this.place}) : super(key: key);

  @override
  _ReviewWidgetState createState() => _ReviewWidgetState();
}

class _ReviewWidgetState extends State<ReviewWidget> {
  Map<String, dynamic>? _matchedPlace;

  @override
  void initState() {
    super.initState();
    _loadPlaceData();
  }

  Future<void> _loadPlaceData() async {
    try {
      final String placeName = Uri.encodeComponent(widget.place);
      final response = await http.get(
        Uri.parse('$baseUrl/api/location/$placeName'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        setState(() {
          _matchedPlace = data;
        });
      } else {
        throw Exception('Failed to load place data');
      }
    } catch (e) {
      debugPrint("❗ 서버 통신 중 오류 발생: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return _matchedPlace == null
        ? const Center(child: CircularProgressIndicator(color: Colors.grey))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildKeywordsSection(_matchedPlace!),
                //const SizedBox(height: 24),
                //_buildReviewsSection(_matchedPlace!),
              ],
            ),
          );
  }

  Widget _buildKeywordsSection(Map<String, dynamic> data) {
    final List<dynamic> keywords = data['keywords'] ?? [];
    final List<dynamic> reviews = data['review'] ?? [];
    keywords.sort((a, b) =>
        (b['sentiment']['total'] ?? 0).compareTo(a['sentiment']['total'] ?? 0));
    if (keywords.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('관련 키워드가 없습니다.', style: TextStyle(color: Colors.grey)),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ...keywords.map((keyword) {
          final String name = keyword['name'].toString();
          final int total = keyword['sentiment']['total'] ?? 0;
          final int pos = keyword['sentiment']['pos'] ?? 0;
          final int neg = keyword['sentiment']['neg'] ?? 0;
          final int neu = keyword['sentiment']['neu'] ?? 0;

          return Padding(
            padding: const EdgeInsets.only(
              top: 15.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  textAlign: TextAlign.center,
                  '$name  ($total 개)',
                  style: const TextStyle(fontSize: 12),
                ),
                //const SizedBox(height: 4),
                LayoutBuilder(builder: (context, constraints) {
                  double maxBarWidth = constraints.maxWidth;
                  double barFactor = total > 0 ? maxBarWidth / total : 0;
                  return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${(((neg + neu) / total) * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(
                              color: AppColors.errorRed, fontSize: 12),
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        Container(
                          width: (neg + neu) * barFactor * 0.75,
                          height: 16,
                          decoration: const BoxDecoration(
                            color: AppColors.errorRed,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(5),
                              bottomLeft: Radius.circular(5),
                            ),
                          ),
                        ),
                        Container(
                          width: pos * barFactor * 0.75,
                          height: 16,
                          decoration: const BoxDecoration(
                            color: AppColors.successGreen,
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(5),
                              bottomRight: Radius.circular(5),
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        Text(
                          '${((pos / total) * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(
                              color: AppColors.successGreen, fontSize: 12),
                        ),
                        // Container(
                        //   width: neu * barFactor,
                        //   height: 20,
                        //   color: Colors.grey,
                        // ),
                      ]);
                }),
                const SizedBox(height: 4),
                // Row(
                //   children: [
                //     Text(
                //       '긍정 $pos개',
                //       style: TextStyle(
                //           color: AppColors.successGreen, fontSize: 12),
                //     ),
                //     const SizedBox(width: 10),
                //     Text(
                //       '부정 $neg개',
                //       style: TextStyle(color: AppColors.errorRed, fontSize: 12),
                //     ),
                //     const SizedBox(width: 10),
                //     Text(
                //       '중립 $neu개',
                //       style: TextStyle(color: Colors.grey, fontSize: 12),
                //     ),
                //     const SizedBox(width: 10),
                //     Text(
                //       '전체 $total개',
                //       style: TextStyle(color: Colors.black, fontSize: 12),
                //     ),
                //   ],
                // ),
              ],
            ),
          );
        }).toList(),
        const SizedBox(height: 20),
      ]),
    );
  }

  Widget _buildReviewsSection(Map<String, dynamic> data) {
    final List<dynamic> reviews = data['review'] ?? [];
    if (reviews.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('관련 리뷰가 없습니다.', style: TextStyle(color: Colors.grey)),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 10.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          children: reviews.map((review) {
            return Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                review ?? '알 수 없음',
                style: const TextStyle(fontSize: 14),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSummarySection(Map<String, dynamic> data) {
    final List<dynamic> keywords = data['keywords'] ?? [];
    final List<dynamic> reviews = data['review'] ?? [];
    keywords.sort((a, b) =>
        (b['sentiment']['total'] ?? 0).compareTo(a['sentiment']['total'] ?? 0));
    if (keywords.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('관련 키워드가 없습니다.', style: TextStyle(color: Colors.grey)),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ...keywords.map((keyword) {
          final String name = keyword['name'].toString();
          final int total = keyword['sentiment']['total'] ?? 0;
          final int pos = keyword['sentiment']['pos'] ?? 0;
          final int neg = keyword['sentiment']['neg'] ?? 0;
          final int neu = keyword['sentiment']['neu'] ?? 0;

          return Padding(
            padding: const EdgeInsets.only(
              top: 15.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  textAlign: TextAlign.center,
                  '$name  ($total 개)',
                  style: const TextStyle(fontSize: 12),
                ),
                //const SizedBox(height: 4),
                LayoutBuilder(builder: (context, constraints) {
                  double maxBarWidth = constraints.maxWidth;
                  double barFactor = total > 0 ? maxBarWidth / total : 0;
                  return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${(((neg + neu) / total) * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(
                              color: AppColors.errorRed, fontSize: 12),
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        Container(
                          width: (neg + neu) * barFactor * 0.75,
                          height: 16,
                          decoration: const BoxDecoration(
                            color: AppColors.errorRed,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(5),
                              bottomLeft: Radius.circular(5),
                            ),
                          ),
                        ),
                        Container(
                          width: pos * barFactor * 0.75,
                          height: 16,
                          decoration: const BoxDecoration(
                            color: AppColors.successGreen,
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(5),
                              bottomRight: Radius.circular(5),
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        Text(
                          '${((pos / total) * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(
                              color: AppColors.successGreen, fontSize: 12),
                        ),
                        // Container(
                        //   width: neu * barFactor,
                        //   height: 20,
                        //   color: Colors.grey,
                        // ),
                      ]);
                }),
                const SizedBox(height: 4),
              ],
            ),
          );
        }).toList(),
        const SizedBox(height: 20),
      ]),
    );
  }
}
