import 'package:flutter/material.dart';
import 'package:swim/features/training/models/training_detail_data.dart';
import 'package:swim/features/training_generation/tg_generation_detail_screen.dart';
import 'tg_beep_settings_screen.dart';
import 'tg_timer_screen.dart';

class TGGenerationScreen extends StatefulWidget {
  const TGGenerationScreen({super.key});

  @override
  _TGGenerationScreenState createState() => _TGGenerationScreenState();
}

class _TGGenerationScreenState extends State<TGGenerationScreen> {
  final List<TrainingDetailData> _trainings = [];
  String _selectedSound = "Take your marks.mp3";
  int _numPeople = 1;
  int _totalDist = 0;
  int _totalTime = 0;

  @override
  void initState() {
    super.initState();
    // 기본 훈련(훈련 1) 추가
    final defaultTraining = TrainingDetailData(
      title: "훈련 1",
      distance: 10,
      cycle: 60,
      count: 1,
      restTime: 0,
    );
    _trainings.add(defaultTraining);
    _updateTotals();
  }

  void _goDetail(int index) async {
    final isFirst = (index == 0);
    final result = await Navigator.push<TrainingDetailData>(
      context,
      MaterialPageRoute(
        builder: (_) => TGGenerationDetailScreen(
          training: _trainings[index],
          isFirstTraining: isFirst,
          numPeople: _numPeople,
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _trainings[index] = result;
        _updateTotals();
      });
    }
  }

  void _addTraining() {
    if (_trainings.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("최대 10개의 훈련만 추가할 수 있습니다.")),
      );
      return;
    }
    final newIndex = _trainings.length + 1;
    final newTraining = TrainingDetailData(
      title: "훈련 $newIndex",
      distance: 10,
      cycle: 60,
      count: 1,
      restTime: 30,
    );
    _trainings.add(newTraining);
    _updateTotals();
    setState(() {});
  }

  void _deleteTraining(int index) {
    // 적어도 하나의 훈련은 남겨두어야 함
    if (_trainings.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("최소 하나의 훈련은 필요합니다.")),
      );
      return;
    }

    // 삭제 확인 다이얼로그 표시
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("훈련 삭제"),
        content: Text("'${_trainings[index].title}'을(를) 삭제하시겠습니까?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("취소"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                _trainings.removeAt(index);
                // 훈련 인덱스 업데이트
                for (int i = index; i < _trainings.length; i++) {
                  // 훈련 제목이 "훈련 X" 형식이면 인덱스 업데이트
                  final title = _trainings[i].title;
                  final regex = RegExp(r"훈련 (\d+)");
                  final match = regex.firstMatch(title);
                  if (match != null) {
                    _trainings[i].title = "훈련 ${i + 1}";
                  }
                }
                _updateTotals();
              });
            },
            child: const Text(
              "삭제",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _updateTotals() {
    int distSum = 0;
    int timeSum = 0;
    for (var t in _trainings) {
      distSum += t.totalDistance;
      timeSum += t.totalTime;
    }
    _totalDist = distSum;
    _totalTime = timeSum;
  }

  void _onBeepSettings() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => TGBeepSettingsDialog(
        selectedSound: _selectedSound,
        numPeople: _numPeople,
      ),
    );
    if (result != null) {
      setState(() {
        _selectedSound = result['sound'];
        _numPeople = result['people'];
      });
    }
  }

  void _onLayerPressed() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("레이어 버튼 (미구현)")),
    );
  }

  void _onStart() {
    if (_trainings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("훈련을 하나 이상 추가하세요.")),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TGTimerScreen(
          trainingList: _trainings,  // ✅ 훈련 목록 전달
          beepSound: _selectedSound, // ✅ 선택한 사운드 전달
          numPeople: _numPeople,     // ✅ 선택한 인원 전달
        ),
      ),
    );
  }


  String _formatCycle(int seconds) {
    if (seconds % 60 == 0) {
      return "${seconds ~/ 60}분";
    } else {
      return "${seconds}s";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 상단 검정색 바
          Container(
            color: Colors.black,
            height: 120,
            child: Stack(
              children: [
                // 뒤로가기 버튼
                Positioned(
                  top: 40,
                  left: 10,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                // 중앙에 이미지 + "Training Generation"
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // z_top_logo.png 이미지를 표시
                        Image.asset(
                          'assets/images/z_top_logo.png',  // 실제 경로에 맞게 수정
                          width: 120,                      // 원하는 크기
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.description, color: Colors.pink, size: 24),
                            SizedBox(width: 6),
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
                  // 훈련 목록
                  for (int i = 0; i < _trainings.length; i++)
                    _buildTrainingCard(i),
                  const SizedBox(height: 20),

                  // + 버튼
                  GestureDetector(
                    onTap: _addTraining,
                    child: Container(
                      height: 60,
                      alignment: Alignment.center,
                      child: const Text(
                        "+",
                        style: TextStyle(
                          fontSize: 50,
                          color: Colors.pink,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 총 시간 / 총 거리
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Container(
                        width: 120,
                        height: 60,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "총 시간:\n$_totalTime초",
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
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
                        child: Text(
                          "총 거리:\n${_totalDist}m",
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 음향 선택 (스피커 아이콘)
                  GestureDetector(
                    onTap: _onBeepSettings, // 누르면 팝업
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      color: Colors.black,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.volume_up, color: Colors.pink),
                          const SizedBox(width: 8),
                          Text(
                            "음향 선택 : $_selectedSound",
                            style: const TextStyle(color: Colors.pink, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 레이어 + Start
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: _onLayerPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                        ),
                        child: const Text(
                          "레이어",
                          style: TextStyle(color: Colors.pink, fontSize: 18),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _onStart,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                        ),
                        child: const Text(
                          "Start",
                          style: TextStyle(color: Colors.pink, fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrainingCard(int index) {
    final train = _trainings[index];
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Stack(
        children: [
          // 기존 ListTile
          ListTile(
            onTap: () => _goDetail(index),
            title: Text(
              "${index + 1}. ${train.title}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            trailing: Text(
              "${train.distance}m / ${_formatCycle(train.cycle)}",
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),

          // 삭제 버튼 (X 버튼)
          Positioned(
            top: 0,
            right: 0,
            child: InkWell(
              onTap: () => _deleteTraining(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                child: const Icon(
                  Icons.close,
                  size: 16,
                  color: Colors.red,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}