// widgets/detail/SummaryTab.dart
import 'package:pik/pages/review/summary.dart';
import 'package:pik/styles/styles.dart';
import 'package:flutter/material.dart';

class SummaryTab extends StatefulWidget {
  const SummaryTab({Key? key, required this.data}) : super(key: key);

  final Map<String, dynamic> data;

  @override
  _SummaryTabState createState() => _SummaryTabState();
}

class _SummaryTabState extends State<SummaryTab> {
  final List<String> _AnalysisOptions = ['전체', '내 취향'];
  int _selectedAnalysisIndex = 0;
  bool _isExpanded = false; // 요약/전체 토글 상태

  Container toggleAnalysis() {
    return Container(
      height: 35,
      margin: const EdgeInsets.fromLTRB(0, 10, 0, 10),
      decoration: BoxDecoration(
        color: TextFiledStyles.fillColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            alignment: _selectedAnalysisIndex == 0
                ? Alignment.centerLeft
                : Alignment.centerRight,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: Container(
              width: (MediaQuery.of(context).size.width - 80) / 2,
              height: 38,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              // margin: const EdgeInsets.symmetric(
              //     vertical: 5, horizontal: 2),
              decoration: BoxDecoration(
                color: AppColors.deepGrean,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_AnalysisOptions.length, (index) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedAnalysisIndex = index;
                  });
                  if (index == 1) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("사용자 취향이 없어요 😢"),
                      ),
                    );
                  }
                },
                child: Container(
                  width:
                      (MediaQuery.of(context).size.width - 80) / 2, // 버튼 크기 통일
                  height: 38,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 6), // 🔥 텍스트 주변 여백
                  child: Text(
                    _AnalysisOptions[index],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _selectedAnalysisIndex == index
                          ? Colors.white
                          : AppColors.deepGrean,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTopAspectsChart() {
    final aggregatedAnalysis = widget.data['aggregatedAnalysis'];
    if (aggregatedAnalysis == null) {
      return const SizedBox.shrink();
    }

    final sentimentAspects =
        aggregatedAnalysis['sentimentAspects'] as Map<String, dynamic>?;
    if (sentimentAspects == null || sentimentAspects.isEmpty) {
      return const SizedBox.shrink();
    }

    // 항목별 총 개수 계산 및 정렬 (AnalysisTab 로직 참고)
    final aspectCounts = <MapEntry<String, int>>[];

    for (var entry in sentimentAspects.entries) {
      final aspectName = entry.key;
      final sentiment = entry.value as Map<String, dynamic>;
      final pos = sentiment['pos'] ?? 0;
      final neg = sentiment['neg'] ?? 0;
      final none = sentiment['none'] ?? 0;
      final total = pos + neg + none;

      if (total > 0) {
        aspectCounts.add(MapEntry(aspectName, total));
      }
    }

    // 개수 기준 내림차순 정렬
    aspectCounts.sort((a, b) => b.value.compareTo(a.value));

    // 상위 5개만 선택
    final top5 = aspectCounts.take(5).toList();
    if (top5.isEmpty) {
      return const SizedBox.shrink();
    }

    // 최대값 구하기 (막대 높이 정규화용)
    final maxCount = top5.first.value;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
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
            '항목별 분석 개수 (상위 5개)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: top5.map((entry) {
                final aspectName = entry.key;
                final count = entry.value;
                final heightRatio = count / maxCount;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          count.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.deepGrean,
                          ),
                        ),
                        const SizedBox(height: 4),
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.0, end: heightRatio),
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return Container(
                              width: double.infinity,
                              height: 150 * value,
                              decoration: BoxDecoration(
                                color: AppColors.mainGreen,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          aspectName,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.lightWhite,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300, width: 1),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20),
            child: Builder(builder: (context) {
              // 요약 텍스트: llmoverview 사용
              final String shortText =
                  (widget.data['llmoverview'] ?? '정보가 없습니다.').toString();

              // 원본 텍스트: overview 사용
              final String fullText =
                  (widget.data['overview'] ?? '정보가 없습니다.').toString();

              final String headerTitle = _isExpanded ? "장소 정보" : "장소 정보 요약";
              final String toggleLabel = _isExpanded ? "요약 보기" : "원본 보기";

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        headerTitle,
                        style: TextStyles.mediumTextStyle
                            .copyWith(color: Colors.black),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isExpanded = !_isExpanded;
                          });
                        },
                        child: Text(
                          toggleLabel,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isExpanded ? fullText : shortText,
                    style: const TextStyle(
                        fontSize: 14, color: Colors.black87, height: 1.6),
                  ),
                  const SizedBox(height: 6),
                ],
              );
            }),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppColors.lightWhite,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300, width: 1),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20),
            child: Builder(builder: (context) {
              final title = (widget.data['title'] ?? '').toString();
              // 보살사 전용 하드코딩 리뷰 요약 문구
              const String bosalsaReviewSummary =
                  '보살사는 도심 속 조용하고 아늑한 작은 절로, 고요한 분위기와 역사적 의미가 돋보이는 장소예요.';
              // 기본/대체 문구
              const String defaultReviewSummary =
                  '방문자들은 전반적으로 조용한 분위기와 휴식에 좋은 환경으로 평가하고 있어요.';
              final String reviewSummary = title.contains('보살사')
                  ? bosalsaReviewSummary
                  : defaultReviewSummary;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "리뷰 요약",
                        style: TextStyles.mediumTextStyle
                            .copyWith(color: Colors.black),
                      ),
                      TextButton(
                        onPressed: () {
                          // 리뷰 탭으로 이동 콜백
                          final goReview = widget.data['onGoReview'];
                          if (goReview != null && goReview is Function) {
                            goReview();
                          } else if (widget.data['onTabChange'] != null &&
                              widget.data['onTabChange'] is Function) {
                            // 백업: 기존 콜백을 사용하는 경우가 있다면 시도
                            widget.data['onTabChange']();
                          } else {
                            debugPrint("리뷰 보러가기 클릭됨 - 탭 전환 콜백이 없습니다.");
                          }
                        },
                        child: Text(
                          "리뷰 보러가기",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    reviewSummary,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.6,
                    ),
                  ),
                ],
              );
            }),
          ),
          const SizedBox(
            height: 10,
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.lightWhite,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300, width: 1),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "분석 요약",
                    style: TextStyles.mediumTextStyle
                        .copyWith(color: Colors.black),
                  ),
                  toggleAnalysis(),
                  if (_selectedAnalysisIndex == 0) _buildTopAspectsChart(),
                  SummaryWidget(placeId: widget.data['_id'].toString()),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
                    child: SizedBox(
                      child: Divider(
                        color: Colors.grey,
                        thickness: 1,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      if (widget.data['onTabChange'] != null &&
                          widget.data['onTabChange'] is Function) {
                        widget.data['onTabChange']();
                      } else {
                        debugPrint("자세히 보기 클릭됨 - 탭 전환 콜백이 없습니다.");
                      }
                    },
                    child: Text(
                      textAlign: TextAlign.right,
                      "자세히 보기",
                      style: TextStyles.mediumTextStyle
                          .copyWith(color: Colors.grey),
                    ),
                  ),
                ]),
          ),
          //_buildKeywordsSection(_matchedPlace!),
        ],
      ),
    );
  }
}
