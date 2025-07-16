import 'package:flutter/material.dart';

class CustomBackButton extends StatelessWidget {
  final VoidCallback onPressed;
  final double topPadding; // 뒤로가기 버튼 위에 추가할 여백

  const CustomBackButton({
    Key? key,
    required this.onPressed,
    this.topPadding = 50.0, // 기본값을 50.0으로 설정해 조금 더 내려감
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: topPadding),
      child: Align(
        alignment: Alignment.centerLeft,
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: onPressed,
        ),
      ),
    );
  }
}
