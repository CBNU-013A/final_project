// widgets/detail/ReviewTab.dart
import 'package:pik/pages/review/writeReviewPage.dart';
import 'package:pik/services/location_service.dart';
import 'package:pik/services/review_service.dart';
import 'package:pik/services/sentiment_service.dart';
import 'package:flutter/material.dart';
import 'package:pik/styles/styles.dart';
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
  bool _isAnalyzing = false;
  List<dynamic> _allReviews = []; // 전체 리뷰 목록

  @override
  void initState() {
    super.initState();
    _loadMyReview();
    _loadAllReviews();
  }

  Future<void> _loadAllReviews() async {
    try {
      final locationService = LocationService();
      final placeId = widget.data['_id'];
      final data = await locationService.fetchLocation(placeId);

      if (data['review'] != null) {
        setState(() {
          _allReviews = data['review'] as List<dynamic>;
        });
        debugPrint("📥 전체 리뷰 ${_allReviews.length}개 불러옴");
      }
    } catch (e) {
      debugPrint("❌ 전체 리뷰 불러오기 실패: $e");
    }
  }

  Future<void> _loadMyReview() async {
    final reviewService = ReviewService();
    final placeId = widget.data['_id'];
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final userId = prefs.getString('userId') ?? '';

    try {
      // 감성 분석 결과가 포함된 상세 리뷰 조회
      final reviewData = await reviewService.getMyReviewWithSentiment(
        placeId,
        token,
        userId,
      );

      setState(() {
        myReview = reviewData['content'] ?? '';
        myReviewId = reviewData['reviewId'] ?? '';
      });

      debugPrint("📥 내 리뷰: $myReview");

      // 서버에서 받은 감성 분석 결과 사용
      if (myReview.isNotEmpty && reviewData['sentimentAspects'] != null) {
        final sentimentAspects =
            reviewData['sentimentAspects'] as List<dynamic>;

        debugPrint("📊 서버에서 받은 감성 분석 결과: $sentimentAspects");

        if (sentimentAspects.isNotEmpty) {
          // sentimentAspects를 sentiment 형태로 변환
          Map<String, dynamic> sentiments = {};

          for (var aspect in sentimentAspects) {
            final aspectName = aspect['aspect']?['name'] ?? '';
            final sentiment = aspect['sentiment'] ?? {};

            if (aspectName.isNotEmpty && sentiment is Map) {
              // sentiment 객체에서 pos, neg, none 값 확인
              String sentimentValue = 'none';
              if (sentiment['pos'] == 1) {
                sentimentValue = 'pos';
              } else if (sentiment['neg'] == 1) {
                sentimentValue = 'neg';
              }

              sentiments[aspectName] = sentimentValue;
            }
          }

          setState(() {
            sentimentResult = sentiments;
          });

          debugPrint("✅ 감성 분석 결과: $sentimentResult");
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
    // _allReviews를 사용 (없으면 widget.data['review'] 사용)
    final List<dynamic> reviews =
        _allReviews.isNotEmpty ? _allReviews : (widget.data['review'] ?? []);
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
                  Row(
                    children: [
                      Text(
                        "내가 쓴 리뷰",
                        style: TextStyles.mediumTextStyle
                            .copyWith(color: Colors.black, fontSize: 16),
                      ),
                      if (myReview.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.mainGreen,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            "작성완료",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  _myReview(),
                  if (_isAnalyzing) _analyzingIndicator(),
                  if (sentimentResult.isNotEmpty && !_isAnalyzing)
                    _sentimentResult(sentimentResult),
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
                      token: prefs.getString('token') ?? '',
                      placeName: widget.data['title'] ?? '',
                    ),
                  ),
                );
                if (result != null && result is String) {
                  // 서버에서 감성 분석이 완료될 시간을 주기 위해 약간 대기
                  setState(() {
                    _isAnalyzing = true;
                  });

                  await Future.delayed(const Duration(seconds: 2));

                  // 리뷰와 감성 분석 결과 다시 불러오기 (서버에서 분석된 결과 포함)
                  await _loadMyReview();
                  // 전체 리뷰 목록도 다시 불러오기
                  await _loadAllReviews();

                  setState(() {
                    _isAnalyzing = false;
                  });

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('리뷰 작성이 완료되었습니다!'),
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
                // 리뷰 내용
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    myReview,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.5,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // 수정 버튼
                    ElevatedButton.icon(
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => WriteReviewPage(
                              placeId: widget.data['_id'],
                              token: prefs.getString('token') ?? '',
                              placeName: widget.data['title'] ?? '',
                            ),
                          ),
                        );

                        if (result != null && result is String) {
                          // 서버에서 감성 분석이 완료될 시간을 주기 위해 약간 대기
                          setState(() {
                            _isAnalyzing = true;
                          });

                          await Future.delayed(const Duration(seconds: 2));

                          // 리뷰와 감성 분석 결과 다시 불러오기 (서버에서 분석된 결과 포함)
                          await _loadMyReview();
                          // 전체 리뷰 목록도 다시 불러오기
                          await _loadAllReviews();

                          setState(() {
                            _isAnalyzing = false;
                          });

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('리뷰 수정이 완료되었습니다!'),
                                backgroundColor: AppColors.mainGreen,
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.mainGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text(
                        '수정',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 삭제 버튼
                    ElevatedButton.icon(
                      onPressed: () async {
                        final reviewService = ReviewService();
                        final prefs = await SharedPreferences.getInstance();
                        final token = prefs.getString('token') ?? '';

                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: AppColors.lightWhite,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            insetPadding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 24),
                            titlePadding:
                                const EdgeInsets.fromLTRB(20, 18, 20, 0),
                            contentPadding:
                                const EdgeInsets.fromLTRB(20, 12, 20, 0),
                            actionsPadding:
                                const EdgeInsets.fromLTRB(12, 8, 12, 12),
                            title: const Text(
                              '리뷰 삭제',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w700),
                            ),
                            content: const Text(
                              '정말로 이 리뷰를 삭제하시겠습니까?',
                              style: TextStyle(
                                  fontSize: 15,
                                  height: 1.5,
                                  color: Colors.black87),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
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
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 18, vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text('확인',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700)),
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        foregroundColor: Colors.red.shade700,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.red.shade200),
                        ),
                        elevation: 0,
                      ),
                      icon: Icon(Icons.delete_outline,
                          size: 16, color: Colors.red.shade700),
                      label: Text(
                        '삭제',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade700,
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
                "리뷰 불러오는 중...",
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
            "서버에서 리뷰와 감성 분석 결과를 불러오고 있습니다.",
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

Widget _sentimentResult(Map<String, dynamic> sentiments) {
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
              width: 140, // 고정 너비 설정
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
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(
                    getIcon(value),
                    size: 16,
                    color: textColor(value),
                  ),
                  const SizedBox(width: 8),
                  RichText(
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: key,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: textColor(value),
                          ),
                        ),
                        TextSpan(
                          text: '  ${translate(value)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: textColor(value).withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    ),
  );
}
