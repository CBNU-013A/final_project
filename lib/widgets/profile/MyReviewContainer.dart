// widgets/profile/MyReviewContainer.dart
import 'package:pik/pages/location/DetailPage.dart';
import 'package:pik/services/review_service.dart';
import 'package:pik/services/user_service.dart';
import 'package:pik/styles/styles.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyReviewContainer extends StatefulWidget {
  const MyReviewContainer({super.key});

  @override
  State<MyReviewContainer> createState() => _MyReviewContainerState();
}

class _MyReviewContainerState extends State<MyReviewContainer> {
  final userService = UserService();
  final reviewService = ReviewService();
  String userId = '';
  String token = '';
  late SharedPreferences prefs;
  List<dynamic> reviews = [];
  bool _showDetail = false;

  @override
  void initState() {
    super.initState();
    loadPrefs();
  }

  Future<void> loadPrefs() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userId') ?? '';
      token = prefs.getString('token') ?? '';
    });
    loadUsersReview();
  }

  void loadUsersReview() async {
    try {
      final userReview = await reviewService.getReviewsByUser(token, userId);
      setState(() {
        reviews = userReview;
      });
    } catch (e) {
      setState(() {
        reviews = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ 리뷰를 불러오지 못했습니다.")),
      );
    }
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
                    '내가 작성한 리뷰',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.deepGrean,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.deepGrean, width: 1.2),
                ),
                child: Text(
                  '${reviews.length}개',
                  style: const TextStyle(
                    color: AppColors.deepGrean,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          if (_showDetail)
            // reviews.isEmpty
            //     ? Padding(
            //         padding:
            //             const EdgeInsets.only(left: 12.0, top: 10, bottom: 10),
            //         child: Row(
            //           children: [
            //             Icon(
            //               Icons.info_outline,
            //               color: Colors.grey[400],
            //               size: 16,
            //             ),
            //             const SizedBox(width: 8),
            //             Text(
            //               "작성한 리뷰가 없습니다.",
            //               style: TextStyle(
            //                 color: Colors.grey[500],
            //                 fontSize: 14,
            //               ),
            //             ),
            //           ],
            //         ),
            //       )
            //    :
            ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reviews.length,
              itemBuilder: (context, index) {
                final review = reviews[index];
                final content = review['content'] ?? '';
                final location = review['location'] ?? '알 수 없음';
                final locationId = review['locationId'] ?? '';

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.lighterGreen.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.mainGreen.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: InkWell(
                      onTap: () {
                        if (locationId.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("❌ 장소 정보를 불러올 수 없습니다.")),
                          );
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailPage(
                              placeName: location,
                              placeId: locationId,
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 0),
                          minVerticalPadding: 0,
                          dense: true,
                          title: Text(
                            content,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                              color: Colors.black87,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.place_outlined,
                                  color: AppColors.mainGreen,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    location,
                                    style: const TextStyle(
                                      color: AppColors.deepGrean,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          trailing: IconButton(
                            tooltip: '삭제',
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.grey, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () async {
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
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700),
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
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(false),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 10),
                                      ),
                                      child: Text(
                                        '취소',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppColors.deepGrean
                                              .withOpacity(0.8),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 18, vertical: 10),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
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
                                  await reviewService.deleteReview(
                                      review['id'], token);
                                  loadUsersReview();
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text("❌ 리뷰 삭제에 실패했습니다.")),
                                  );
                                }
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
