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
        if (isExpanded) ...[
          _buildMiniFab(context, Icons.edit, "훈련 추가"),
          _buildMiniFab(context, Icons.share, "캘린더 공유"),
          _buildMiniFab(context, Icons.delete, "리스트 삭제"),
          SizedBox(height: 10),
        ],
        FloatingActionButton(
          backgroundColor: Colors.pinkAccent,
          onPressed: toggle,
          child: Icon(isExpanded ? Icons.close : Icons.add),
        ),
      ],
    );
  }

  Widget _buildMiniFab(BuildContext context, IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: FloatingActionButton(
        heroTag: label,
        mini: true,
        backgroundColor: Colors.pinkAccent,
        onPressed: () => onAction(label),
        child: Icon(icon, size: 20),
      ),
    );
  }
}
