import 'package:flutter/material.dart';
import 'package:swim/features/swimming/screens/swimming_main_screen.dart';

class TrainingScreen extends StatelessWidget {
  const TrainingScreen({Key? key}) : super(key: key);

  Widget _buildSwimmingButton(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SwimmingMainScreen()),
        );
      },
      child: Container(
        width: 280,
        height: 180,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(40),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pool, size: 70, color: Colors.blue[300]),
            const SizedBox(height: 12),
            const Text(
              "Swimming",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 배경 이미지는 추후 추가할 수 있도록 주석 처리
      /*
      // 배경 이미지를 위한 BoxDecoration 사용
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/background.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      */
      backgroundColor: Colors.white,
      // 가운데 정렬된 Z:TOP 로고
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        toolbarHeight: 80,
        title: Center(
          child: Image.asset(
            'assets/images/z_top_logo.png',
            height: 50,
            fit: BoxFit.contain,
          ),
        ),
        centerTitle: true,
        actions: [
          // 왕관 아이콘 없이 빈 공간만 유지하여 로고가 완전히 가운데 오도록 함
          const SizedBox(width: 48), // AppBar 양쪽의 여백을 동일하게 맞추기 위한 공간
        ],
        leadingWidth: 48, // 왼쪽 여백도 동일하게 설정
      ),
      body: Column(
        children: [
          // 상단 영역 (Swimming 버튼)
          Expanded(
            flex: 5,
            child: Center(
              child: _buildSwimmingButton(context),
            ),
          ),

          // 하단 영역 (진제우 특강 문구 등)
          Expanded(
            flex: 7,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 큰 문구 (진제우 특강)
                  const Text(
                    "진제로 특강!!",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 강사 정보
                  const Text(
                    "강사: 수원 올시즌 0000원",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                  const Text(
                    "문의처: 010-0000-0000",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 우리동네 수영장 섹션
                  const Text(
                    "우리동네 수영장",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 수영장 목록 (불릿 포인트)
                  _buildPoolListItem("자유수영"),
                  _buildPoolListItem("위치"),
                  _buildPoolListItem("강습"),
                  _buildPoolListItem("금액"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 불릿 포인트 아이템 생성 헬퍼 메서드
  Widget _buildPoolListItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}