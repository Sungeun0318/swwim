import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomLogo extends StatelessWidget {
  final double textSize; // 글씨 크기
  const CustomLogo({Key? key, this.textSize = 72}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return SizedBox(
      width: screenWidth, // 화면 가로 전체 사용
      height: textSize * 1.5, // 글씨 크기에 비례해서 높이 설정
      // clipBehavior: Clip.none → Stack의 자식이 영역 밖으로 나가도 잘리지 않음
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // 🔥 검정 원(오른쪽 일부에 겹치도록)
          Positioned(
            right: -textSize * 0.2, // 글씨 일부가 가려지도록 살짝 밖으로 배치
            child: Container(
              width: textSize * 1.2,  // 원의 크기
              height: textSize * 1.2,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black, // 검정 원
              ),
            ),
          ),

          // 🔥 "Z⋮TOP" 텍스트
          Text(
            "Z⋮TOP",
            style: GoogleFonts.bebasNeue(
              fontSize: textSize,        // 크게 표시
              fontWeight: FontWeight.bold,
              color: Colors.pink,        // 핑크색 글씨
              letterSpacing: 3.0,        // 글자 간격
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
