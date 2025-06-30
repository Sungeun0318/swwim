// lib/common/calendar/dialog_delete.dart

import 'package:flutter/material.dart';
import '../widgets/training_item.dart';

typedef OnDeleteTraining = void Function(List<TrainingItem> selectedItems);

void showDeleteDialog(
    BuildContext context,
    List<TrainingItem> events,
    OnDeleteTraining onDelete,
    ) {
  List<bool> selected = List.generate(events.length, (_) => false);

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text("삭제할 항목 선택"),
      content: SizedBox(
        width: double.maxFinite,
        child: events.isEmpty
            ? Text("삭제할 일정이 없습니다.")
            : ListView.builder(
          shrinkWrap: true,
          itemCount: events.length,
          itemBuilder: (context, index) => CheckboxListTile(
            title: Text(events[index].name),
            value: selected[index],
            onChanged: (val) {
              selected[index] = val!;
            },
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("취소"),
        ),
        TextButton(
          onPressed: () {
            List<TrainingItem> toDelete = [];
            for (int i = 0; i < events.length; i++) {
              if (selected[i]) {
                toDelete.add(events[i]);
              }
            }
            onDelete(toDelete);
            Navigator.pop(context);
          },
          child: Text("삭제", style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
}
