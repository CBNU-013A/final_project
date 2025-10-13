// widgets/home/TripPrompt.dart
import 'package:pik/pages/recommend/setTripPage.dart';
import 'package:pik/styles/styles.dart';
import 'package:pik/styles/text_styles.dart';
import 'package:flutter/material.dart';

//어디로 떠날까요? 프롬프트 섹션 위젯 추출
class TripPrompt extends StatefulWidget {
  final String userId;
  final String userName;

  const TripPrompt({super.key, required this.userId, required this.userName});

  @override
  State<TripPrompt> createState() => _TripPromptState();
}

class _TripPromptState extends State<TripPrompt> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 10),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "여행을 떠나볼까요?",
              style: AppTextStyles.sectionTitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 5),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => setTripPage(
                      userId: widget.userId,
                      userName: widget.userName,
                    ),
                  ),
                );
              },
              style: ButtonStyles.bigButtonStyle(context: context),
              child: Text(
                "추천 받으러 가기",
                style: TextStyles.mediumTextStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
