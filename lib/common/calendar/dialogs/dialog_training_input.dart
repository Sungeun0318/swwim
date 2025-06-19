import 'package:flutter/material.dart';
import '../widgets/training_item.dart';

typedef OnAddTraining = void Function(TrainingItem training);

void showTrainingInputDialog(
    BuildContext context,
    DateTime selectedDay,
    OnAddTraining onAdd,
    ) {
  final nameController = TextEditingController();
  final distanceController = TextEditingController();
  final timeController = TextEditingController();

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text("훈련 내용 입력"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: "훈련명",
                hintText: "예: 자유형 느리게",
              ),
            ),
            TextField(
              controller: distanceController,
              decoration: InputDecoration(
                labelText: "거리",
                hintText: "예: 25m x 6",
              ),
            ),
            TextField(
              controller: timeController,
              decoration: InputDecoration(
                labelText: "시간",
                hintText: "예: 50초 x 6",
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("취소"),
        ),
        TextButton(
          onPressed: () {

            final name = nameController.text.trim();
            final distance = distanceController.text.trim();
            final time = timeController.text.trim();
            if (name.isNotEmpty && distance.isNotEmpty && time.isNotEmpty) {
              onAdd(TrainingItem(
                date: selectedDay ?? DateTime.now(),
                name: name,
                distance: distance,
                time: time,
              ));
            }
            Navigator.pop(context);
          },
          child: Text("추가"),
        ),
      ],
    ),
  );
}