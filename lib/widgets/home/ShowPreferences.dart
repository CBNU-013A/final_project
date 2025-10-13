// widgets/home/ShowPreferences.dart
// 사용자 취향 섹션 위젯 추출
import 'package:pik/styles/styles.dart';
import 'package:pik/styles/text_styles.dart';
import 'package:pik/widgets/home/ShowKeywords.dart';
import 'package:pik/widgets/home/setKeywordsPage.dart';
import 'package:flutter/material.dart';

class ShowPreferences extends StatefulWidget {
  final String userId;
  final String userName;
  //final VoidCallback onEdit;

  const ShowPreferences({
    super.key,
    required this.userId,
    required this.userName,
    //required this.onEdit,
  });

  @override
  State<ShowPreferences> createState() => _ShowPreferencesState();
}

class _ShowPreferencesState extends State<ShowPreferences> {
  @override
  Widget build(BuildContext context) {    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                '${widget.userName} 님의 주요 여행 취향',
                style: AppTextStyles.sectionTitle,
                textAlign: TextAlign.center,
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SetKeywordsPage(
                        userId: widget.userId,
                        userName: widget.userName,
                      ),
                    ),
                  );
                },
                child: Text(
                  "설정",
                  textAlign: TextAlign.start,
                  style: TextStyles.smallTextStyle
                      .copyWith(color: AppColors.deepGrean),
                ),
              ),
            ],
          ),
          const ShowKeywords(),
        ],
      ),
    );
  }
}
