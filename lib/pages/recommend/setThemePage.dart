// pages/recommend/setThemePage.dart
import 'package:pik/pages/home/HomePage.dart';
import 'package:pik/pages/recommend/setActivityPage.dart';
import 'package:pik/services/keyword_service.dart';
import 'package:pik/styles/styles.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Setthempage extends StatefulWidget {
  const Setthempage({super.key});

  @override
  State<Setthempage> createState() => _SetthempageState();
}

class _SetthempageState extends State<Setthempage> {
  String category = '';
  List<String> keywords = [];
  String selectedKeyword = '';
  String previousSelectedCompanion = '';

  final keywordService = KeywordService();

  @override
  void initState() {
    super.initState();
    _loadCategory();
    _loadPreviousSelection();
  }

  void _loadPreviousSelection() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString('selectedWithKeyword') ?? '';
    setState(() {
      previousSelectedCompanion = value;
    });
  }

  void _loadKeywords() async {
    final keywords = await keywordService.getAllKeywords();

    final filtered = keywords
        .where((item) => item['category']?.toString() == category)
        .map((item) => item['name'].toString())
        .toList();

    setState(() {
      this.keywords = filtered;
    });
  }

  void _loadCategory() async {
    final categoryList = await keywordService.getCategory();
    final placeCategory = categoryList.firstWhere(
      (item) => item['name'] == '장소',
      orElse: () => {},
    );
    setState(() {
      category = (placeCategory['_id']?.toString()) ?? '';
      _loadKeywords();
    });
    debugPrint('${placeCategory['name']}, ${placeCategory['_id']}');
  }

  Widget _buildOptionButton(String label) {
    final bool isSelected = selectedKeyword == label;
    final bool isNoneOption = label == '상관없음';

    return SizedBox(
      height: isNoneOption ? 40 : 80,
      width: isNoneOption ? 300 : 140,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isNoneOption
              ? Colors.grey[300]
              : (isSelected ? AppColors.mainGreen : AppColors.lighterGreen),
          surfaceTintColor: AppColors.deepGrean,
          overlayColor: AppColors.deepGrean,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () async {
          final newValue = isSelected ? '' : label;
          setState(() {
            selectedKeyword = newValue;
          });
          final prefs = await SharedPreferences.getInstance();

          //하위 카테고리 Id 저장
          String? selectedId;
          if (newValue.isNotEmpty && !isNoneOption) {
            // keywords와 subcategories의 순서가 같다고 가정하지 않고, 이름으로 찾음
            final subKeywords = await keywordService.getSubKeywords(category);
            final matched = subKeywords.firstWhere(
              (item) => item['name'] == newValue,
              orElse: () => {},
            );
            if (matched['_id'] != null) {
              selectedId = matched['_id'].toString();
              await prefs.setString('selectedThemeKeywordId', selectedId);
              await prefs.setString('selectedThemeKeyword', newValue);
              debugPrint(
                  "✅ 저장된 subcategory id: $selectedId, keyword: ${prefs.getString('selectedThemeKeyword')}");
            }
          } else {
            await prefs.remove('selectedPlaceKeywordId');
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  const Setactivitypage(), // NextPage를 실제 이동할 페이지로 교체하세요.
            ),
          );
        },
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isNoneOption
                ? Colors.black87
                : (isSelected ? Colors.white : AppColors.deepGrean),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

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
        body: Column(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(40, 16, 40, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                          border:
                              Border.all(width: 1, color: AppColors.deepGrean),
                          borderRadius:
                              const BorderRadius.all(Radius.circular(10))),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '누구와 함께 가나요?',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (previousSelectedCompanion.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.mainGreen,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  previousSelectedCompanion,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '이번 여행의 테마는 어떻게 할까요?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (child, animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: SizedBox(
                  key: const ValueKey('select'),
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: AppColors.lightWhite,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: keywords.isEmpty
                        ? const Center(
                            child:
                                CircularProgressIndicator(color: Colors.grey))
                        : Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 10,
                            runSpacing: 15,
                            children: [
                              ...keywords.map(
                                  (keyword) => _buildOptionButton(keyword)),
                              _buildOptionButton('상관없음'),
                            ],
                          ),
                  ),
                )),
          ],
        ));
  }
}
