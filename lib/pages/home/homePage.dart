// pages/home/HomePage.dart
import 'dart:io';
import 'package:pik/widgets/home/ShowPreferences.dart';
import 'package:pik/widgets/home/TripPrompt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:pik/styles/styles.dart';
import 'package:pik/widgets/main_app_bar.dart';
import 'package:pik/widgets/home/RecentSearch.dart';
import 'package:pik/widgets/BottomNavi.dart';
import 'package:pik/widgets/home/Recommend.dart';
import 'package:pik/services/user_service.dart';
import 'package:pik/pages/auth/loginPage.dart';
import 'package:shared_preferences/shared_preferences.dart';

final String baseUrl = Platform.isAndroid
    ? 'http://${dotenv.env['BASE_URL']}:8001'
    : 'http://localhost:8001';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  String userId = '';
  String userName = '';
  final userService = UserService();

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  void loadUser() async {
    final userData = await userService.loadUserData();

    if (userData.isNotEmpty) {
      setState(() {
        userId = userData['userId'] ?? '';
        userName = userData['userName'] ?? '';
      });
    } else {
      debugPrint("❌ 사용자 정보 없음 (재접속)");
    }
  }

  void logout() async {
    await userService.logout();
    // Clear all SharedPreferences except 'savedEmail'
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('savedEmail');
    await prefs.clear();
    if (savedEmail != null) {
      await prefs.setString('savedEmail', savedEmail);
    }
    // 로그아웃 후 로그인 페이지로 이동 등 추가 처리 가능
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lighterGreen,
      extendBodyBehindAppBar: false,
      appBar: MainAppBar(title: 'Pik', actions: [
        IconButton(
            icon: const Icon(Icons.logout),
            tooltip: '로그아웃',
            onPressed: () async {
              logout();
            })
      ]),
      body: Container(
        decoration: BoxStyles.backgroundBox(),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      //const SizedBox(height: 20.0),
                      // ... 님의 주요 여행 취향r
                     // ShowPreferences(userName: userName, userId: userId),
                      const SizedBox(height: 20),
                      // 어디로 떠날까요?
                      TripPrompt(userId: userId, userName: userName),
                      const SizedBox(height: 20),
                      Recommend(userId: userId, userName: userName),
                      const SizedBox(height: 20),
                      RecentSearch(userName: userName, userId: userId),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavi(currentIndex: 0),
    );
  }
}
