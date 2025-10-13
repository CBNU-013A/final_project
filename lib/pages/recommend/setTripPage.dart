// pages/recommend/setTripPage.dart
import 'package:pik/pages/home/HomePage.dart';
import 'package:pik/pages/recommend/InteractiveRecommendPage.dart';
import 'package:pik/pages/recommend/RecommendHistoryPage.dart';
import 'package:pik/styles/styles.dart';
import 'package:flutter/material.dart';

class setTripPage extends StatefulWidget {
  final String userId;
  final String userName;

  const setTripPage({super.key, required this.userId, required this.userName});

  @override
  State<setTripPage> createState() => _setTripPageState();
}

class _setTripPageState extends State<setTripPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightWhite,
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        actionsPadding: const EdgeInsets.only(right: 3.0),
        backgroundColor: AppColors.lightWhite,
        automaticallyImplyLeading: false,
        centerTitle: false,
        actions: [
          TextButton(
            child: const Text(
              "돌아가기",
              style: TextStyle(color: AppColors.lightGray),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HomePage(),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 80),
            SizedBox(
                height: 147,
                child: Image.asset(
                  'assets/bag.png',
                )),
            const Text('여행을 떠나 볼까요?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            const Text('피크가 간단한 질문으로\n 딱 맞는 여행지를 추천해 드릴게요',
                style: TextStyle(
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center),
            const SizedBox(height: 40),
            Text('${widget.userName} 님의 데이터를 통해 \n 빠르게 추천 받을 수도 있어요 🚀',
                style: const TextStyle(
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center),
            const SizedBox(height: 40),
            TextButton(
              onPressed: () {
                // 인터랙티브 추천 페이지로 이동
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const InteractiveRecommendPage(),
                  ),
                );
              },
              child: const Text("빠른 추천 받기"),
              style: ButtonStyles.bigButtonStyle(context: context),
            ),
            const SizedBox(height: 8),
            // 이전 추천 여행지 버튼
            OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RecommendHistoryPage(),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.mainGreen,
                backgroundColor: Colors.white,
                minimumSize: Size(MediaQuery.of(context).size.width * 0.9, 40),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                side: const BorderSide(
                  color: AppColors.mainGreen,
                  width: 0.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text("이전 추천 여행지"),
            ),
          ],
        ),
      ),
    );
  }
}
