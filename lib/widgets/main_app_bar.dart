// widgets/main_app_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pik/styles/styles.dart';
import 'package:pik/styles/text_styles.dart';

class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget> actions;

  const MainAppBar({
    super.key,
    required this.title,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.lighterGreen,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: AppBar(
        backgroundColor: AppColors.lighterGreen,
        elevation: 0,
        scrolledUnderElevation: 0, // 스크롤 시에도 elevation 유지
        surfaceTintColor: Colors.transparent, // 스크롤 시 색상 변화 방지
        automaticallyImplyLeading: false,
        flexibleSpace: const DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.lighterGreen,
          ),
        ),
        title: Padding(
          padding: const EdgeInsets.fromLTRB(12.0, 12, 12, 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(title, style: AppTextStyles.appBarTitle),
          ),
        ),
        actions: actions,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
