import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DistancePicker extends StatefulWidget {
  final int initialDistance;   // 초기 거리 값
  final int minDistance;       // 최소 거리
  final int maxDistance;       // 최대 거리
  final int step;              // 거리 간격 (예: 5m)
  final ValueChanged<int> onChanged; // 변경 시 호출되는 콜백

  const DistancePicker({
    Key? key,
    required this.initialDistance,
    this.minDistance = 10,
    this.maxDistance = 100,
    this.step = 5,
    required this.onChanged,
  }) : super(key: key);

  @override
  _DistancePickerState createState() => _DistancePickerState();
}

class _DistancePickerState extends State<DistancePicker> {
  late int selectedDistance;
  late List<int> distances;

  @override
  void initState() {
    super.initState();
    selectedDistance = widget.initialDistance;
    distances = [
      for (int d = widget.minDistance; d <= widget.maxDistance; d += widget.step)
        d
    ];

    // initialDistance가 범위 밖이면 보정
    if (selectedDistance < widget.minDistance) {
      selectedDistance = widget.minDistance;
    } else if (selectedDistance > widget.maxDistance) {
      selectedDistance = widget.maxDistance;
    }
  }

  /// 직접 입력 다이얼로그
  void _showDirectInputDialog() {
    final controller = TextEditingController(text: selectedDistance.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("직접 입력"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "거리 (m)"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("취소"),
          ),
          TextButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              if (value != null &&
                  value >= widget.minDistance &&
                  value <= widget.maxDistance) {
                setState(() {
                  selectedDistance = value;
                  widget.onChanged(selectedDistance);
                });
              }
              Navigator.pop(context);
            },
            child: const Text("확인"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showDirectInputDialog,
      child: SizedBox(
        height: 150,
        child: CupertinoPicker(
          backgroundColor: Colors.transparent,
          scrollController: FixedExtentScrollController(
            initialItem: distances.indexOf(selectedDistance),
          ),
          itemExtent: 40,
          onSelectedItemChanged: (index) {
            setState(() {
              selectedDistance = distances[index];
              widget.onChanged(selectedDistance);
            });
          },
          children: distances
              .map((d) => Center(
            child: Text(
              "$d m",
              style: const TextStyle(fontSize: 20),
            ),
          ))
              .toList(),
        ),
      ),
    );
  }
}
