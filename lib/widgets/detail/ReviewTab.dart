// widgets/detail/ReviewTab.dart
import 'package:final_project/pages/review/writeReviewPage.dart';
import 'package:final_project/services/review_service.dart';
import 'package:final_project/services/sentiment_service.dart';
import 'package:flutter/material.dart';
import 'package:final_project/styles/styles.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReviewsTab extends StatefulWidget {
  final Map<String, dynamic> data;

  const ReviewsTab({Key? key, required this.data}) : super(key: key);

  @override
  State<ReviewsTab> createState() => _ReviewsTabState();
}

class _ReviewsTabState extends State<ReviewsTab> {
  String myReview = '';
  String myReviewId = '';
  final prefs = SharedPreferences.getInstance();
  final sentimentService = SentimentService();
  Map<String, dynamic> sentimentResult = {};
  Map<String, dynamic> categoryResult = {};
  bool _isAnalyzing = false;
  @override
  void initState() {
    super.initState();
    _loadMyReview();
  }

  Future<void> _loadMyReview() async {
    final reviewService = ReviewService();
    final placeId = widget.data['_id'];
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final userId = prefs.getString('userId') ?? '';

    try {
      final reviewData = await reviewService.getReviewsByLocation(
        placeId,
        token,
        userId,
      );

      setState(() {
        myReview = reviewData['content'] ?? '';
        myReviewId = reviewData['_id'] ?? '';
      });

      debugPrint("📥 내 리뷰: $myReview");

      // 리뷰가 있으면 감성 분석 수행
      if (myReview.isNotEmpty) {
        setState(() {
          _isAnalyzing = true;
        });
        final result = await sentimentService.analyzeSentiment(myReview);
        setState(() {
          _isAnalyzing = false;
        });

        debugPrint("감성 분석 결과: $result");
        if (result != null && result['sentiments'] != null) {
          setState(() {
            sentimentResult = Map<String, dynamic>.from(result['sentiments']);
            if (result['categories'] != null) {
              categoryResult = Map<String, dynamic>.from(result['categories']);
            }
          });
          debugPrint("감성 분석 결과: ${result['sentiments']}");
          debugPrint("카테고리 분석 결과: ${result['categories']}");
        }
      }
    } catch (e) {
      debugPrint("❌ 리뷰 불러오기 실패: $e");
      setState(() {
        myReview = '';
      });
    }
  }

  Future<void> _confirmReportDialog(String reviewId) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.lightWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          actionsPadding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          title: const Text(
            '신고하기',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          content: const Text(
            '부적절한 내용으로 신고하시겠습니까?',
            style: TextStyle(fontSize: 15, height: 1.5, color: Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              child: Text(
                '취소',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.deepGrean.withOpacity(0.8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.mainGreen,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text('확인',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );

    if (result == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('신고가 접수되었습니다. 검토까지 시간이 소요될 수 있어요.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      debugPrint('📨 신고확인 reviewId=$reviewId');
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<dynamic> reviews = widget.data['review'] ?? [];
    final List<dynamic> reversedReviews = List<dynamic>.from(reviews.reversed);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.lightWhite,
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300, width: 1),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "내가 쓴 리뷰",
                    style: TextStyles.mediumTextStyle
                        .copyWith(color: Colors.black, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  _myReview(),
                  if (_isAnalyzing) _analyzingIndicator(),
                  if (sentimentResult.isNotEmpty && !_isAnalyzing)
                    _sentimentResult(sentimentResult, categoryResult),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: AppColors.lightWhite,
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300, width: 1),
              ),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: reversedReviews.map((review) {
                  return Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 상단: 작성자(가능 시) + 신고하기
                        Builder(builder: (context) {
                          String? authorName;
                          String? reviewId;
                          if (review is Map) {
                            final m = Map<String, dynamic>.from(review);
                            reviewId = (m['_id'] ?? m['id'])?.toString();
                            if (m['user'] is Map) {
                              final u = Map<String, dynamic>.from(m['user']);
                              authorName =
                                  (u['name'] ?? u['userName'] ?? u['nickname'])
                                      ?.toString();
                            } else if (m['author'] is Map) {
                              final u = Map<String, dynamic>.from(m['author']);
                              authorName =
                                  (u['name'] ?? u['userName'] ?? u['nickname'])
                                      ?.toString();
                            } else {
                              authorName = (m['userName'] ?? m['authorName'])
                                  ?.toString();
                            }
                          }
                          final hasUser = (authorName != null &&
                              authorName.trim().isNotEmpty);

                          return Row(
                            children: [
                              if (hasUser) ...[
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor:
                                      AppColors.mainGreen.withOpacity(0.1),
                                  child: Icon(Icons.person,
                                      size: 16, color: AppColors.mainGreen),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    authorName,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ] else
                                const Expanded(child: SizedBox()),
                              TextButton(
                                onPressed: () =>
                                    _confirmReportDialog(reviewId ?? 'unknown'),
                                style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  "신고하기",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[500],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                        const SizedBox(height: 10),
                        if (review is Map && (review['content'] != null))
                          Text(
                            review['content'].toString(),
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: Colors.black87,
                              letterSpacing: -0.2,
                            ),
                          )
                        else
                          Text(
                            review != null ? review.toString() : '리뷰 내용 없음',
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: Colors.black87,
                              letterSpacing: -0.2,
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _myReview() {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.lighterGreen.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppColors.mainGreen.withOpacity(0.2), width: 1),
      ),
      child: myReview.isEmpty
          ? InkWell(
              onTap: () async {
                debugPrint("widget.data['_id']: ${widget.data['_id']}");

                final prefs = await SharedPreferences.getInstance();
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WriteReviewPage(
                      placeId: widget.data['_id'],
                      token: prefs.getString('') ?? '',
                    ),
                  ),
                );
                if (result != null && result is String) {
                  setState(() {
                    myReview = result;
                  });

                  setState(() {
                    _isAnalyzing = true;
                  });

                  await _loadMyReview();

                  setState(() {
                    _isAnalyzing = false;
                  });

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('리뷰 작성 및 감성 분석이 완료되었습니다!'),
                        backgroundColor: AppColors.mainGreen,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                }
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.edit_outlined,
                      size: 18, color: AppColors.deepGrean),
                  const SizedBox(width: 6),
                  const Text(
                    "리뷰 작성하기",
                    style: TextStyle(
                      color: AppColors.deepGrean,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  myReview,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.5,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () async {
                        final reviewService = ReviewService();
                        final prefs = await SharedPreferences.getInstance();
                        final token = prefs.getString('token') ?? '';

                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('리뷰 삭제'),
                            content: const Text('정말로 이 리뷰를 삭제하시겠습니까?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('취소'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('삭제',
                                    style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true) {
                          try {
                            await reviewService.deleteReview(myReviewId, token);
                            setState(() {
                              myReview = '';
                              myReviewId = '';
                              sentimentResult = {};
                              categoryResult = {};
                            });
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('리뷰가 삭제되었습니다.'),
                                  backgroundColor: Colors.grey,
                                ),
                              );
                            }
                          } catch (e) {
                            debugPrint('리뷰 삭제 실패: $e');
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('리뷰 삭제에 실패했습니다.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        }
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        '삭제하기',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _analyzingIndicator() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                "리뷰 감성 분석 중...",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "AI가 리뷰 내용을 분석하여 감성을 파악하고 있습니다.",
            style: TextStyle(
              fontSize: 13,
              color: Colors.black54,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

Widget _sentimentResult(
    Map<String, dynamic> sentiments, Map<String, dynamic> categories) {
  String translate(String key) {
    switch (key) {
      case 'pos':
        return '긍정';
      case 'neg':
        return '부정';
      case 'none':
      default:
        return '중립';
    }
  }

  Color backgroundColor(String value) {
    switch (value) {
      case 'pos':
        return AppColors.mainGreen.withOpacity(0.1);
      case 'neg':
        return AppColors.mustedBlush.withOpacity(0.1);
      case 'none':
      default:
        return Colors.grey[200]!;
    }
  }

  Color textColor(String value) {
    switch (value) {
      case 'pos':
        return AppColors.mainGreen;
      case 'neg':
        return AppColors.mustedBlush;
      case 'none':
      default:
        return Colors.grey[600]!;
    }
  }

  IconData getIcon(String value) {
    switch (value) {
      case 'pos':
        return Icons.sentiment_very_satisfied;
      case 'neg':
        return Icons.sentiment_very_dissatisfied;
      case 'none':
      default:
        return Icons.sentiment_neutral;
    }
  }

  return Container(
    margin: const EdgeInsets.only(top: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: Colors.grey[300]!),
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.analytics_outlined,
              color: AppColors.mainGreen,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text(
              "리뷰 감성 분석 결과",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          "리뷰에서 언급된 각 항목에 대한 감성을 분석했습니다.",
          style: TextStyle(
            fontSize: 13,
            color: Colors.black54,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: sentiments.entries.map((entry) {
            final key = entry.key;
            final value = entry.value;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: backgroundColor(value),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: textColor(value).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    getIcon(value),
                    size: 16,
                    color: textColor(value),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "$key",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textColor(value),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    translate(value),
                    style: TextStyle(
                      fontSize: 12,
                      color: textColor(value).withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        // 카테고리 분석 결과 표시
        if (categories.isNotEmpty) ...[
          const Text(
            "카테고리 분석",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categories.entries.map((entry) {
              final key = entry.key;
              final value = entry.value;
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.mainGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.mainGreen.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.category,
                      size: 14,
                      color: AppColors.mainGreen,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "$key: $value",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mainGreen,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
        ],
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.lightWhite,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: AppColors.mainGreen,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "분석 결과는 AI가 리뷰 내용을 바탕으로 자동으로 생성됩니다.",
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.mainGreen.withOpacity(0.8),
                    height: 1.3,
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
