// pages/recommend/setWithPage.dart
import 'package:final_project/pages/home/HomePage.dart';
import 'package:final_project/pages/recommend/setThemePage.dart';
import 'package:final_project/services/keyword_service.dart';
import 'package:final_project/styles/styles.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Setwithpage extends StatefulWidget {
  const Setwithpage({super.key});

  @override
  State<Setwithpage> createState() => _SetwithpageState();
}

class _SetwithpageState extends State<Setwithpage> {
  String category = '';
  List<String> keywords = [];
  String selectedKeyword = '';

  final keywordService = KeywordService();

  @override
  void initState() {
    super.initState();
    _loadCategory();
  }

  void _loadKeywords() async {
    final keywords = await keywordService.getAllKeywords();

    final filtered = keywords
        .where((item) => item['category']?.toString() == category)
        .map((item) => item['name'].toString())
        .toList();

    // debugPrint('✅ 필터링된 키워드: $filtered');

    setState(() {
      this.keywords = filtered;
    });
  }

  void _loadCategory() async {
    final categoryList = await keywordService.getCategory();
    final placeCategory = categoryList.firstWhere(
      (item) => item['name'] == '방문 대상',
      orElse: () => {},
    );
    setState(() {
      category = (placeCategory['_id']?.toString()) ?? '';
      _loadKeywords();
    });
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

          // 하위카테고리 id 저장
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
              await prefs.setString('selectedWithKeywordId', selectedId);
              await prefs.setString('selectedWithKeyword', newValue);
              debugPrint(
                  "✅ 저장된 subcategory id: $selectedId, keyword: ${prefs.getString('selectedWithKeyword')}");
            }
          } else {
            await prefs.remove('selectedWithKeywordId');
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const Setthempage(),
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
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  '누구와 함께 가나요?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: AppColors.lightWhite,
                      //border: Border.all(color: AppColors.deepGrean, width: 1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: keywords.isEmpty
                        ? const Center(
                            child:
                                CircularProgressIndicator(color: Colors.grey))
                        : Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 16,
                            runSpacing: 15,
                            children: [
                              ...keywords.map(
                                  (keyword) => _buildOptionButton(keyword)),
                              _buildOptionButton('상관없음'),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}
