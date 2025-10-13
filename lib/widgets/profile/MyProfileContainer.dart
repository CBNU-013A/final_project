import 'package:pik/styles/styles.dart';
import 'package:flutter/material.dart';

class MyProfileContainer extends StatefulWidget {
  final String infoTitle;
  const MyProfileContainer({super.key, required this.infoTitle});

  @override
  State<MyProfileContainer> createState() => _MyProfileContainerState();
}

class _MyProfileContainerState extends State<MyProfileContainer> {
  bool _showDetail = false;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.fromLTRB(2, 7, 20, 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _showDetail = !_showDetail;
                      });
                    },
                    icon: Icon(
                      _showDetail ? Icons.expand_more : Icons.chevron_right,
                      color: AppColors.marineBlue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${widget.infoTitle}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const Text('여기에 정보'),
            ],
          ),
          if (_showDetail)
            Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 48.0, top: 10),
              child: const Text(
                '토글된 상세 정보 예시입니다.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }
}
