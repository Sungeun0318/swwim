import 'package:flutter/material.dart';

void showPreScheduleDialog(BuildContext context) {
  final controller = TextEditingController();

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text("스케줄 미리 작성"),
      content: TextField(
        controller: controller,
        decoration: InputDecoration(hintText: "예: 자유형 25m x 6"),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("취소"),
        ),
        TextButton(
          onPressed: () {
            if (controller.text.trim().isNotEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("작성된 스케줄: \${controller.text.trim()}"),
                ),
              );
            }
            Navigator.pop(context);
          },
          child: Text("저장"),
        ),
      ],
    ),
  );
}
