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

  // 새로운 스타일의 입력 필드
  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onTap ?? () {}, // null일 때 빈 함수 실행
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.grey.shade300, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: controller,
                keyboardType: keyboardType,
                readOnly: readOnly,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 15),
                ),
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 피커 버튼 스타일
  Widget _buildPickerField({
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onTap,
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.blue.shade300, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: onTap != null ? Colors.blue.shade600 : Colors.grey,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 정보 표시 카드
  Widget _buildInfoCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              const Text(
                "총 거리",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "$totalDistance m",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey.shade300,
          ),
          Column(
            children: [
              const Text(
                "총 시간",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "$totalTime 초",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isGapEnabled = widget.numPeople >= 2;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Center(
          child: Image.asset(
            'assets/images/S.png',
            width: 40,
            height: 40,
            fit: BoxFit.contain,
          ),
        ),
        centerTitle: true,
        actions: const [SizedBox(width: 48)],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // 훈련 내용
                  _buildInputField(
                    label: "훈련 내용",
                    controller: _titleCtrl,
                    keyboardType: TextInputType.text,
                  ),

                  // 쉬는 시간 (첫 번째 훈련이 아닐 때만)
                  if (!widget.isFirstTraining)
                    _buildPickerField(
                      label: "쉬는 시간",
                      value: "$_restTimeMin분 $_restTimeSec초",
                      onTap: _showRestTimePicker,
                    ),

                  // 거리
                  _buildInputField(
                    label: "거리 (m)",
                    controller: _distanceCtrl,
                    keyboardType: TextInputType.number,
                  ),

                  // 개수
                  _buildPickerField(
                    label: "개수",
                    value: "$_count개",
                    onTap: () => _showSingleNumberPicker(
                      title: "개수",
                      currentValue: _count,
                      minValue: 1,
                      maxValue: 100,
                      onSelected: (val) => setState(() => _count = val),
                    ),
                  ),

                  // 싸이클
                  _buildPickerField(
                    label: "싸이클",
                    value: "$_cycleHour시간 $_cycleMin분 $_cycleSec초",
                    onTap: _showCyclePicker,
                  ),

                  // 간격
                  _buildPickerField(
                    label: "간격 (초)",
                    value: isGapEnabled ? "$_gap초" : "비활성화 (1명)",
                    onTap: isGapEnabled
                        ? () => _showSingleNumberPicker(
                      title: "간격(초)",
                      currentValue: _gap,
                      minValue: 5,
                      maxValue: 60,
                      onSelected: (val) => setState(() => _gap = val),
                    )
                        : null,
                  ),

                  // 총 거리/시간 정보 카드
                  _buildInfoCard(),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // 완료 버튼
          Container(
            margin: const EdgeInsets.all(20),
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _onComplete,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                "완료",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
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
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: 300,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade600,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 60),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        "확인",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  scrollController: FixedExtentScrollController(
                      initialItem: initialIndex),
                  itemExtent: 40,
                  onSelectedItemChanged: (index) {
                    onSelected(range[index]);
                  },
                  children: range
                      .map((val) => Center(
                    child: Text(
                      "$val",
                      style: const TextStyle(fontSize: 18),
                    ),
                  ))
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
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: 350,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade600,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 60),
                    const Text(
                      "싸이클 (시/분/초)",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        "확인",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(
                            initialItem: tmpHour),
                        itemExtent: 40,
                        onSelectedItemChanged: (index) {
                          tmpHour = index;
                        },
                        children: List.generate(24, (i) =>
                            Center(child: Text("$i시", style: const TextStyle(fontSize: 16)))),
                      ),
                    ),
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(
                            initialItem: tmpMin),
                        itemExtent: 40,
                        onSelectedItemChanged: (index) {
                          tmpMin = index;
                        },
                        children: List.generate(60, (i) =>
                            Center(child: Text("$i분", style: const TextStyle(fontSize: 16)))),
                      ),
                    ),
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(
                            initialItem: tmpSec),
                        itemExtent: 40,
                        onSelectedItemChanged: (index) {
                          tmpSec = index;
                        },
                        children: List.generate(60, (i) =>
                            Center(child: Text("$i초", style: const TextStyle(fontSize: 16)))),
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
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: 350,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade600,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 60),
                    const Text(
                      "쉬는 시간 (분/초)",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        "확인",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(
                            initialItem: tmpMin),
                        itemExtent: 40,
                        onSelectedItemChanged: (index) {
                          tmpMin = index;
                        },
                        children: List.generate(60, (i) =>
                            Center(child: Text("$i분", style: const TextStyle(fontSize: 16)))),
                      ),
                    ),
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(
                            initialItem: tmpSec),
                        itemExtent: 40,
                        onSelectedItemChanged: (index) {
                          tmpSec = index;
                        },
                        children: List.generate(60, (i) =>
                            Center(child: Text("$i초", style: const TextStyle(fontSize: 16)))),
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
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange.shade600),
            const SizedBox(width: 8),
            const Text("설정 오류"),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              foregroundColor: Colors.blue.shade600,
            ),
            child: const Text(
              "확인",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
    );
  }
}