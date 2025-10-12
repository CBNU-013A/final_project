// pages/home/ProfilePage.dart
import 'package:final_project/styles/styles.dart';
import 'package:final_project/widgets/BottomNavi.dart';
import 'package:final_project/widgets/profile/MyLikeContainer.dart';
import 'package:final_project/widgets/profile/MyLocationContainer.dart';
import 'package:final_project/widgets/profile/MyReviewContainer.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Profilepage extends StatefulWidget {
  const Profilepage({super.key});

  @override
  State<Profilepage> createState() => _ProfilepageState();
}

class _ProfilepageState extends State<Profilepage> {
  String userName = '';
  String userEmail = '';

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
    });
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
            // const SizedBox(height: 10),
            // const MyProfileContainer(infoTitle: "내 정보"),
            // 🧾 버튼들

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
