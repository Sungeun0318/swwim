import 'package:flutter/material.dart';
import 'swimming_quickstart_screen.dart';

class SwimmingQuickStartLevelSelectionScreen extends StatelessWidget {
  const SwimmingQuickStartLevelSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // 상단 검정색 영역
          Container(
            color: Colors.black,
            height: 160, // 높이를 늘려서 로고와 텍스트를 좀 더 아래로 배치
            child: Stack(
              children: [
                // 1) 로고 + "Quick Start" 텍스트를 중앙에 표시
                //   mainAxisSize: MainAxisSize.min 사용으로, Column 높이를 내용만큼만 사용
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/z_top_logo.png',
                        width: 120,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.pool, color: Colors.pink, size: 28),
                          SizedBox(width: 8),
                          Text(
                            "Quick Start",
                            style: TextStyle(
                              color: Colors.pink,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 2) 뒤로가기 버튼: top=40, 왼쪽=8
                Positioned(
                  top: 40,
                  left: 8,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ),
          // 하단 영역
          Expanded(
            child: Center(
              child: ListView(
                shrinkWrap: true,
                children: [
                  _buildLevelButton(context, "초급"),
                  _buildLevelButton(context, "중급"),
                  _buildLevelButton(context, "상급"),
                  _buildLevelButton(context, "마스터"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelButton(BuildContext context, String label) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 40),
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SwimmingQuickStartScreen(level: label),
            ),
          );
        },
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.pink,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
