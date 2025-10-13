// pages/review/writeReviewPage.dart
import 'package:final_project/styles/styles.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:final_project/services/review_service.dart';

class WriteReviewPage extends StatefulWidget {
  final String placeId;
  final String token;
  final String placeName;

  const WriteReviewPage({
    Key? key,
    required this.placeId,
    required this.token,
    this.placeName = '',
  }) : super(key: key);

  @override
  _WriteReviewPageState createState() => _WriteReviewPageState();
}

class _WriteReviewPageState extends State<WriteReviewPage> {
  final TextEditingController _contentController = TextEditingController();
  String? myReview;
  String? myReviewId;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadMyReview();
  }

  Future<void> _loadMyReview() async {
    final reviewService = ReviewService();
    final placeId = widget.placeId;
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
        myReviewId = reviewData['reviewId'] ?? '';
        _isEditing = myReview!.isNotEmpty;
        _contentController.text = myReview!;
        _contentController.selection = TextSelection.fromPosition(
          TextPosition(offset: _contentController.text.length),
        );
      });

      debugPrint("📥 내 리뷰: $myReview");
    } catch (e) {
      debugPrint("❌ 리뷰 불러오기 실패: $e");
      setState(() {
        myReview = '';
      });
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  void _createReview() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final placeId = widget.placeId;
    final newText = _contentController.text.trim();

    if (newText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('내용이 비어있습니다.')),
      );
      return;
    }

    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다.')),
      );
      return;
    }

    try {
      final reviewService = ReviewService();
      final success = await reviewService.createReview(placeId, newText, token);

      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('리뷰 작성 완료'),
            backgroundColor: AppColors.mainGreen,
          ),
        );
        Navigator.pop(context, newText);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('리뷰 작성 실패. 다시 시도해주세요.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ 리뷰 작성 중 에러: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _updateReview() async {
    if (myReviewId == null || myReviewId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('리뷰 ID가 존재하지 않아 수정할 수 없습니다.')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final newText = _contentController.text.trim();

    if (newText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('내용이 비어있습니다.')),
      );
      return;
    }

    // Debug log before updating review
    debugPrint('🛠️ 리뷰 수정 요청 - ID: $myReviewId, 내용: $newText');

    final reviewService = ReviewService();

    final success =
        await reviewService.updateReview(myReviewId!, newText, token);

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('리뷰 수정 완료'),
          backgroundColor: AppColors.mainGreen,
        ),
      );
      Navigator.pop(context, newText);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('리뷰 수정 실패'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.lightWhite,
        centerTitle: true,
        title: Text(
          widget.placeName.isNotEmpty ? widget.placeName : '리뷰 작성',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        actions: [
          const SizedBox(width: 8.0),
          TextButton(
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.resolveWith<Color>(
                (Set<MaterialState> states) {
                  if (states.contains(MaterialState.pressed)) {
                    return AppColors.lightWhite;
                  }
                  return AppColors.lightWhite;
                },
              ),
            ),
            onPressed: _isEditing ? _updateReview : _createReview,
            child: Text(
              _isEditing ? '수정하기' : '작성하기',
              style: const TextStyle(color: AppColors.deepGrean),
            ),
          ),
          const SizedBox(width: 8.0),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TextField(
          controller: _contentController,
          onChanged: (value) {
            setState(() {});
          },
          maxLength: 100,
          maxLines: 10,
          textAlignVertical: TextAlignVertical.top,
          cursorColor: Colors.black,
          decoration: const InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(2.0)),
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(2.0)),
              borderSide: BorderSide(color: Colors.grey),
            ),
            hintText:
                '욕설, 비방 등 상대방을 불쾌하게 하는 의견은 남기지 말아주세요. 신고를 당하면 서비스 이용이 제한될 수 있어요.',
            hintMaxLines: 3,
          ),
        ),
      ),
    );
  }
}
