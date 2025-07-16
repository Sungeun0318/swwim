// lib/features/training_generation/widgets/tg_fab_menu.dart
import 'package:flutter/material.dart';

typedef TGFabActionCallback = void Function(String action);

class TGFabMenu extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback toggle;
  final TGFabActionCallback onAction;

  const TGFabMenu({
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
              height: 200,
              color: Colors.transparent,
            ),
          ),

        // FAB 메뉴들
        if (isExpanded) ...[
          // 커뮤니티 공유 버튼
          _buildActionButton(
            icon: Icons.share,
            label: "커뮤니티 공유",
            backgroundColor: Colors.green,
            onPressed: () => onAction("커뮤니티 공유"),
          ),
          const SizedBox(height: 12),

          // 내 일정 저장 버튼
          _buildActionButton(
            icon: Icons.calendar_today,
            label: "내 일정 저장",
            backgroundColor: Colors.blue,
            onPressed: () => onAction("내 일정 저장"),
          ),
          const SizedBox(height: 12),
        ],

        // 메인 FAB 버튼
        FloatingActionButton(
          backgroundColor: Colors.blue.shade600,
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