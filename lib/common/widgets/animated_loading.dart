// lib/common/widgets/animated_loading.dart
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class AnimatedLoading extends StatelessWidget {
  final String? message;
  final double? width;
  final double? height;

  const AnimatedLoading({
    Key? key,
    this.message,
    this.width = 200,
    this.height = 200,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Lottie 애니메이션
          Lottie.asset(
            'assets/animations/swimming_starter.json',
            width: width,
            height: height,
            fit: BoxFit.contain,
            repeat: true, // 무한 반복
            animate: true, // 자동 재생
          ),
          if (message != null) ...[
            const SizedBox(height: 20),
            Text(
              message!,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.blue,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

// 풀스크린 로딩 오버레이
class FullScreenLoading extends StatelessWidget {
  final String? message;
  final Color backgroundColor;

  const FullScreenLoading({
    Key? key,
    this.message,
    this.backgroundColor = Colors.black54,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: AnimatedLoading(
            message: message ?? "로딩 중...",
            width: 150,
            height: 150,
          ),
        ),
      ),
    );
  }
}