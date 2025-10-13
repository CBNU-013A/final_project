// widgets/like_button.dart
import 'package:flutter/material.dart';
import 'package:pik/services/like_service.dart';

class LikeButton extends StatefulWidget {
  final String userId;
  final String placeId;
  final String token;

  const LikeButton({
    Key? key,
    required this.userId,
    required this.placeId,
    required this.token,
  }) : super(key: key);

  @override
  State<LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton> {
  final LikeService _likeService = LikeService();
  bool _isLoading = true;
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    _loadLikeStatus();
  }

  Future<void> _loadLikeStatus() async {
    final isLiked = await _likeService.isPlaceLikedByUser(
      widget.userId,
      widget.placeId,
      widget.token,
    );
    setState(() {
      _isLiked = isLiked;
      _isLoading = false;
    });
  }

  Future<void> _toggleLike() async {
    debugPrint("❤️ 좋아요 버튼 눌림");
    final success = await _likeService.toggleLike(
      widget.userId,
      widget.placeId,
      widget.token,
      _isLiked,
    );

    if (success) {
      setState(() {
        _isLiked = !_isLiked;
      });
    } else {
      debugPrint("❌ 좋아요 토글 실패");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("좋아요 요청 실패")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        width: 48,
        height: 48,
        child: Center(child: CircularProgressIndicator(color: Colors.grey)),
      );
    }

    return IconButton(
      icon: Icon(
        _isLiked ? Icons.favorite : Icons.favorite_border,
        color: _isLiked ? Colors.red : Colors.black,
      ),
      tooltip: _isLiked ? '즐겨찾기에서 제거' : '즐겨찾기에 추가',
      onPressed: _toggleLike,
    );
  }
}
