// widgets/search_bar.dart
import 'package:flutter/material.dart';
import '../styles/search.dart';
import '../styles/styles.dart';
import 'package:pik/pages/location/DetailPage.dart';
import 'package:pik/pages/home/SearchPage.dart';

class SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final ValueChanged<String>? onSubmitted;

  const SearchBar({
    super.key,
    required this.controller,
    this.initialValue,
    this.onChanged,
    this.onClear,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    if (initialValue != null) {
      controller.text = initialValue!;
      controller.selection =
          TextSelection.collapsed(offset: controller.text.length);
    }

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGreen, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: AppColors.deepGrean, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
              ),
              decoration: const InputDecoration(
                hintText: '여행지를 검색하세요',
                hintStyle: TextStyle(
                  color: Colors.grey,
                  fontSize: 15,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: onClear,
              child: const Icon(
                Icons.close,
                color: Colors.grey,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }
}
