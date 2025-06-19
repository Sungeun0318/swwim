import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:swim/features/swimming/models/training_detail_data.dart';

class TGGenerationDetailScreen extends StatefulWidget {
  final TrainingDetailData training;
  final bool isFirstTraining;
  final int numPeople;

  const TGGenerationDetailScreen({
    Key? key,
    required this.training,
    this.isFirstTraining = false,
    required this.numPeople,
  }) : super(key: key);

  @override
  _TGGenerationDetailScreenState createState() => _TGGenerationDetailScreenState();
}

class _TGGenerationDetailScreenState extends State<TGGenerationDetailScreen> {
  late TextEditingController _titleCtrl;
  late TextEditingController _distanceCtrl;
  late TextEditingController _countCtrl;
  late TextEditingController _cycleCtrl;
  late TextEditingController _gapCtrl;

  late int _restTimeMin;
  late int _restTimeSec;
  late int _restTime;
  late int _count;
  late int _cycleHour;
  late int _cycleMin;
  late int _cycleSec;
  late int _gap;

  @override
  void initState() {
    super.initState();
    final t = widget.training;
    _titleCtrl = TextEditingController(text: t.title);
    _distanceCtrl = TextEditingController(text: t.distance.toString());
    _countCtrl = TextEditingController(text: t.count.toString());
    _cycleCtrl = TextEditingController(text: t.cycle.toString());
    _gapCtrl = TextEditingController(text: t.interval.toString());

    _restTime = widget.isFirstTraining ? 0 : (t.restTime > 0 ? t.restTime : 30);
    _count = t.count;
    _cycleHour = (t.cycle ~/ 3600).clamp(0, 23);
    _cycleMin = ((t.cycle % 3600) ~/ 60).clamp(0, 59);
    _cycleSec = (t.cycle % 60).clamp(0, 59);
    _gap = t.interval;
    if (widget.isFirstTraining) {
      _restTimeMin = 0;
      _restTimeSec = 0;
    } else {
      _restTimeMin = _restTime ~/ 60;
      _restTimeSec = _restTime % 60;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _distanceCtrl.dispose();
    _countCtrl.dispose();
    _cycleCtrl.dispose();
    _gapCtrl.dispose();
    super.dispose();
  }

  int get totalDistance {
    final dist = int.tryParse(_distanceCtrl.text) ?? 0;
    return dist * _count;
  }

  int get totalTime {
    final cycleSec = (_cycleHour * 3600) + (_cycleMin * 60) + _cycleSec;
    final rest = widget.isFirstTraining ? 0 : _restTime;
    return (cycleSec * _count) + rest;
  }

  @override
  Widget build(BuildContext context) {
    final isGapEnabled = widget.numPeople >= 2;
    return Scaffold(
      body: Column(
        children: [
          Container(
            color: Colors.black,
            height: 120,
            child: Stack(
              children: [
                Positioned(
                  top: 40,
                  left: 10,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.description, color: Colors.pink, size: 40),
                        SizedBox(height: 4),
                        Text(
                          "Training Generation",
                          style: TextStyle(
                            color: Colors.pink,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildTextField(
                      "훈련 내용", _titleCtrl, keyboardType: TextInputType.text),
                  if (!widget.isFirstTraining) _buildRestTimeRow(),
                  _buildTextField("거리", _distanceCtrl),
                  _buildCountRow(),
                  _buildCycleRow(),
                  _buildGapRow(isGapEnabled),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Container(
                        width: 120,
                        height: 60,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("총 거리", style: TextStyle(fontSize: 14)),
                            Text("$totalDistance",
                                style: const TextStyle(fontSize: 16)),
                          ],
                        ),
                      ),
                      Container(
                        width: 120,
                        height: 60,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("총 시간", style: TextStyle(fontSize: 14)),
                            Text("$totalTime",
                                style: const TextStyle(fontSize: 16)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _onComplete,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 14),
                    ),
                    child: const Text(
                      "완료",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl,
      {TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: ctrl,
              keyboardType: keyboardType ?? TextInputType.number,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestTimeRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const SizedBox(
            width: 80,
            child: Text("쉬는 시간",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: _showRestTimePicker,
              child: Container(
                height: 48,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text("$_restTimeMin분 $_restTimeSec초"),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const SizedBox(
            width: 80,
            child: Text("개수",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () =>
                  _showSingleNumberPicker(
                    title: "개수",
                    currentValue: _count,
                    minValue: 1,
                    maxValue: 100,
                    onSelected: (val) => setState(() => _count = val),
                  ),
              child: Container(
                height: 48,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text("$_count"),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCycleRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const SizedBox(
            width: 80,
            child: Text("싸이클",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: _showCyclePicker,
              child: Container(
                height: 48,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text("$_cycleHour시간 $_cycleMin분 $_cycleSec초")
                ,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGapRow(bool enabled) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const SizedBox(
            width: 80,
            child: Text("간격",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: enabled
                  ? () =>
                  _showSingleNumberPicker(
                    title: "간격(초)",
                    currentValue: _gap,
                    minValue: 5,  // 최소값 5초로 변경
                    maxValue: 60,
                    onSelected: (val) => setState(() => _gap = val),
                  )
                  : null,
              child: Container(
                height: 48,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: enabled ? Colors.white : Colors.grey[300],
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  "$_gap",
                  style: TextStyle(color: enabled ? Colors.black : Colors.grey),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showSingleNumberPicker({
    required String title,
    required int currentValue,
    required int minValue,
    required int maxValue,
    required ValueChanged<int> onSelected,
  }) async {
    final range = List<int>.generate(
        maxValue - minValue + 1, (i) => i + minValue);
    int initialIndex = range.indexOf(currentValue);
    if (initialIndex < 0) initialIndex = 0;
    await showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Container(
          height: 250,
          color: Colors.white,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 16),
                  Text(title, style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("확인"),
                  ),
                ],
              ),
              Expanded(
                child: CupertinoPicker(
                  scrollController: FixedExtentScrollController(
                      initialItem: initialIndex),
                  itemExtent: 36,
                  onSelectedItemChanged: (index) {
                    onSelected(range[index]);
                  },
                  children: range
                      .map((val) => Center(child: Text("$val")))
                      .toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showCyclePicker() async {
    int tmpHour = _cycleHour;
    int tmpMin = _cycleMin;
    int tmpSec = _cycleSec;
    await showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Container(
          height: 300,
          color: Colors.white,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 16),
                  const Text("싸이클 (시/분/초)", style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("확인"),
                  ),
                ],
              ),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(
                            initialItem: tmpHour),
                        itemExtent: 36,
                        onSelectedItemChanged: (index) {
                          tmpHour = index;
                        },
                        children: List.generate(24, (i) =>
                            Center(child: Text("$i시"))),
                      ),
                    ),
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(
                            initialItem: tmpMin),
                        itemExtent: 36,
                        onSelectedItemChanged: (index) {
                          tmpMin = index;
                        },
                        children: List.generate(60, (i) =>
                            Center(child: Text("$i분"))),
                      ),
                    ),
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(
                            initialItem: tmpSec),
                        itemExtent: 36,
                        onSelectedItemChanged: (index) {
                          tmpSec = index;
                        },
                        children: List.generate(60, (i) =>
                            Center(child: Text("$i초"))),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
    setState(() {
      _cycleHour = tmpHour;
      _cycleMin = tmpMin;
      _cycleSec = tmpSec;
    });
  }

  Future<void> _showRestTimePicker() async {
    int tmpMin = _restTimeMin;
    int tmpSec = _restTimeSec;
    await showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Container(
          height: 300,
          color: Colors.white,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 16),
                  const Text("쉬는 시간 (분/초)", style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("확인"),
                  ),
                ],
              ),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(
                            initialItem: tmpMin),
                        itemExtent: 36,
                        onSelectedItemChanged: (index) {
                          tmpMin = index;
                        },
                        children: List.generate(60, (i) =>
                            Center(child: Text("$i분"))),
                      ),
                    ),
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(
                            initialItem: tmpSec),
                        itemExtent: 36,
                        onSelectedItemChanged: (index) {
                          tmpSec = index;
                        },
                        children: List.generate(60, (i) =>
                            Center(child: Text("$i초"))),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
    setState(() {
      _restTimeMin = tmpMin;
      _restTimeSec = tmpSec;
      _restTime = (_restTimeMin * 60) + _restTimeSec;
    });
  }

  void _onComplete() {
    final cycleSec = (_cycleHour * 3600) + (_cycleMin * 60) + _cycleSec;
    final totalGapTime = _gap * widget.numPeople;

    // 🔴 싸이클 시간 최소 10초
    if (cycleSec < 10) {
      _showAlert("싸이클 시간은 최소 10초 이상이어야 합니다.");
      return;
    }

    // 🔴 인원 2명 이상일 때 간격 최소 5초로 변경
    if (widget.numPeople > 1 && _gap < 5) {
      _showAlert("인원이 2명 이상일 경우 간격은 최소 5초 이상이어야 합니다.");
      return;
    }

    // 🔴 인원 수 × 간격 > 싸이클 시간 방지
    if (widget.numPeople >= 2 && totalGapTime >= cycleSec) {
      _showAlert("간격 × 인원 수가 싸이클 시간보다 크거나 같을 수 없습니다.");
      return;
    }

    final updated = widget.training
      ..title = _titleCtrl.text
      ..distance = int.tryParse(_distanceCtrl.text) ?? 0
      ..count = _count
      ..cycle = cycleSec
      ..interval = _gap;

    updated.restTime = widget.isFirstTraining ? 0 : _restTime;

    Navigator.pop(context, updated);
  }

  void _showAlert(String message) {
    showDialog(
      context: context,
      builder: (ctx) =>
          AlertDialog(
            title: const Text("설정 오류"),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("확인"),
              )
            ],
          ),
    );
  }
}
