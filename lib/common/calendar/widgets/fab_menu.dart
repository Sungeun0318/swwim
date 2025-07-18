// lib/common/calendar/widgets/fab_menu.dart
import 'package:flutter/material.dart';

typedef FabActionCallback = void Function(String action);

class FabMenu extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback toggle;
  final FabActionCallback onAction;

  const FabMenu({
    super.key,
    required this.isExpanded,
    required this.toggle,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 배경 오버레이 (확장시 뒤쪽 클릭 방지)
        if (isExpanded)
          GestureDetector(
            onTap: toggle,
            child: Container(
              width: double.infinity,
              height: 250,
              color: Colors.transparent,
            ),
          ),

        // FAB 메뉴들
        if (isExpanded) ...[
          // 일정 추가 버튼
          _buildActionButton(
            icon: Icons.event_note,
            label: "일정 추가",
            backgroundColor: Colors.green,
            onPressed: () => onAction("일정 추가"),
          ),
          const SizedBox(height: 12),

          // 커뮤니티 공유 버튼
          _buildActionButton(
            icon: Icons.share,
            label: "커뮤니티 공유",
            backgroundColor: Colors.orange,
            onPressed: () => onAction("커뮤니티 공유"),
          ),
          const SizedBox(height: 12),

          // 훈련 바로 시작 버튼
          _buildActionButton(
            icon: Icons.play_arrow,
            label: "훈련 바로 시작",
            backgroundColor: Colors.blue,
            onPressed: () => onAction("훈련 바로 시작"),
          ),
          const SizedBox(height: 12),
        ],

        // 메인 FAB 버튼
        FloatingActionButton(
          backgroundColor: Colors.blue,
          onPressed: toggle,
          child: AnimatedRotation(
            turns: isExpanded ? 0.125 : 0,
            duration: const Duration(milliseconds: 200),
            child: Icon(
              isExpanded ? Icons.close : Icons.add,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required VoidCallback onPressed,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // 라벨 배경
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),

        // 버튼
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: backgroundColor.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(24),
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }
}