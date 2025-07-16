// lib/common/widgets/custom_top_bar.dart
import 'package:flutter/material.dart';

class CustomTopBar extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;

  const CustomTopBar({
    Key? key,
    required this.title,
    this.onBack,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      // 원하는 배경색 (검정)
      color: Colors.black,
      // 뒤로가기 버튼 위치를 내리려면 top 값을 늘려주세요.
      padding: const EdgeInsets.only(top: 30, bottom: 10, left: 16, right: 16),
      child: Row(
        children: [
          // 뒤로가기 버튼 (onBack이 null이면 빈 공간으로 대체)
          if (onBack != null)
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: onBack,
            )
          else
            const SizedBox(width: 48), // 버튼 대신 공간

          // 중앙에 제목
          Expanded(
            child: Center(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.pink,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // 오른쪽에 공간 확보 (필요 시 다른 아이콘 배치 가능)
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}
