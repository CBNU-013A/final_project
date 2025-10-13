// pages/home/ProfilePage.dart
import 'package:final_project/services/auth_service.dart';
import 'package:final_project/styles/styles.dart';
import 'package:final_project/widgets/BottomNavi.dart';
import 'package:final_project/widgets/profile/MyLikeContainer.dart';
import 'package:final_project/widgets/profile/MyLocationContainer.dart';
import 'package:final_project/widgets/profile/MyReviewContainer.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/LoginPage.dart';

class Profilepage extends StatefulWidget {
  const Profilepage({super.key});

  @override
  State<Profilepage> createState() => _ProfilepageState();
}

class _ProfilepageState extends State<Profilepage> {
  String userName = '';
  String userEmail = '';
  String userId = '';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('userName') ?? '';
      userEmail = prefs.getString('userEmail') ?? '';
      userId = prefs.getString('userId') ?? '';
    });
  }

  Future<void> _showDeactivateDialog() async {
    final TextEditingController passwordController = TextEditingController();

    await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.lightWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        actionsPadding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        title: const Text(
          '회원탈퇴',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '정말로 탈퇴하시겠습니까?\n탈퇴 시 모든 데이터가 삭제됩니다.',
              style:
                  TextStyle(fontSize: 15, height: 1.5, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: '비밀번호 입력',
                labelStyle: const TextStyle(color: AppColors.deepGrean),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.deepGrean, width: 2),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              cursorColor: AppColors.deepGrean,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop(false);
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
            onPressed: () async {
              final password = passwordController.text.trim();

              if (password.isEmpty) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('비밀번호를 입력해주세요.'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.of(ctx).pop(true);

              // 회원탈퇴 처리
              if (!mounted) return;
              await _processDeactivate(password);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              '탈퇴',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processDeactivate(String password) async {
    // 로딩 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.mainGreen),
      ),
    );

    final authService = AuthService();
    final result = await authService.deactivate(userId, password);

    // 로딩 닫기
    if (mounted) Navigator.of(context).pop();

    if (!mounted) return;

    if (result['success'] == true) {
      // 성공: 로그아웃 처리 후 로그인 페이지로 이동
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? '회원탈퇴가 완료되었습니다.'),
          backgroundColor: AppColors.mainGreen,
        ),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    } else {
      // 실패: 에러 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? '회원탈퇴에 실패했습니다.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _section(String title, List<String> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...items.map(
            (text) => Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(text),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: 페이지 이동
                  },
                ),
                const Divider(height: 1),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightWhite,
      extendBodyBehindAppBar: false,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 100),

            // 👤 프로필 영역
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.grey[200],
              child: Icon(Icons.person, size: 50, color: Colors.grey[600]),
            ),
            const SizedBox(height: 10),
            Text(
              userName.isNotEmpty ? userName : '사용자',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              userEmail.isNotEmpty ? userEmail : '@unknown',
              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 20),

            //내 정보 컨테이너

            const SizedBox(height: 10),
            const MyReviewContainer(),
            //const MyReviewContainer(infoTitle: "내가 쓴 리뷰"),
            const SizedBox(height: 10),
            const MyLikeContainer(),
            const SizedBox(height: 10),
            const MyLocationContainer(),

            const SizedBox(height: 30),

            // 회원탈퇴 버튼
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: TextButton(
                onPressed: _showDeactivateDialog,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  minimumSize: const Size(double.infinity, 0),
                ),
                child: Text(
                  '회원탈퇴',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // // 📌 섹션 리스트
            // _section('활동', ['리워드 사용 내역', '나의 활동', '내 정보']),
            // _section('고객센터', ['자주 묻는 질문', '공지사항']),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavi(currentIndex: 3),
    );
  }
}
