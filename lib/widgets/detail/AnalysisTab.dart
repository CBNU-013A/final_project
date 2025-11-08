// widgets/detail/AnalysisTab.dart
import 'package:flutter/material.dart';
import 'package:pik/styles/styles.dart';

class AnalysisTab extends StatefulWidget {
  final Map<String, dynamic> data;

  const AnalysisTab({Key? key, required this.data}) : super(key: key);

  @override
  State<AnalysisTab> createState() => _AnalysisTabState();
}

class _AnalysisTabState extends State<AnalysisTab> {
  Widget _buildSentimentAnalysis() {
    final aggregatedAnalysis = widget.data['aggregatedAnalysis'];
    if (aggregatedAnalysis == null) {
      return const Center(
        child: Text('분석 데이터가 없습니다.'),
      );
    }

    final sentimentAspects =
        aggregatedAnalysis['sentimentAspects'] as Map<String, dynamic>?;
    if (sentimentAspects == null || sentimentAspects.isEmpty) {
      return const Center(
        child: Text('감성 분석 데이터가 없습니다.'),
      );
    }

    // 동반, 장소, 활동을 제외한 항목들만 필터링
    final filteredAspects = sentimentAspects.entries
        .where((entry) => !['동반', '장소', '활동'].contains(entry.key))
        .toList();

    if (filteredAspects.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: const Center(
          child: Text(
            '분석할 수 있는 항목이 없습니다.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '항목별 감성 분석',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ...filteredAspects.map((entry) {
            final aspectName = entry.key;
            final sentiment = entry.value as Map<String, dynamic>;
            final pos = sentiment['pos'] ?? 0;
            final neg = sentiment['neg'] ?? 0;
            final total = pos + neg;

            if (total == 0) return const SizedBox.shrink();

            // 긍정/부정 비율 계산
            final posPercent = ((pos / total) * 100).toInt();
            final negPercent = ((neg / total) * 100).toInt();

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    aspectName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        '부정 $negPercent%',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                height: 8,
                                child: Stack(
                                  children: [
                                    // 배경 (긍정 - 초록)
                                    Container(
                                      width: double.infinity,
                                      color: AppColors.mainGreen,
                                    ),
                                    // 부정 (빨강) - 왼쪽부터 애니메이션
                                    FractionallySizedBox(
                                      widthFactor: (neg / total) * value,
                                      alignment: Alignment.centerLeft,
                                      child: Container(
                                        color: AppColors.mustedBlush,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '긍정 $posPercent%',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
      child: Column(
        children: [
          _buildSentimentAnalysis(),
        ],
      ),
    );
  }
}
