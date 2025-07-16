// lib/features/training_generation/screens/tg_generation_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swim/features/swimming/models/training_detail_data.dart';
import 'package:swim/features/training_generation/screens/tg_generation_detail_screen.dart';
import 'package:swim/features/training_generation/models/training_session.dart';
import 'package:swim/repositories/training_repository.dart';
import 'package:swim/features/training_generation/widgets/tg_fab_menu.dart';
import 'tg_beep_settings_screen.dart';
import 'tg_timer_screen.dart';

class TGGenerationScreen extends StatefulWidget {
  const TGGenerationScreen({super.key});

  @override
  State<TGGenerationScreen> createState() => _TGGenerationScreenState();
}

class _TGGenerationScreenState extends State<TGGenerationScreen> {
  final List<TrainingDetailData> _trainings = [];
  String _selectedSound = "Take your marks.mp3";
  int _numPeople = 1;
  int _totalDist = 0;
  int _totalTime = 0;
  final TrainingRepository _trainingRepository = TrainingRepository();
  bool _isLoading = false;

  // FAB 메뉴를 위한 추가 변수
  bool _isFabExpanded = false;

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

  void _onStart() async {
    if (_trainings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("훈련을 하나 이상 추가하세요.")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // BuildContext를 미리 저장
    if (!mounted) return; // mounted 체크 추가
    final currentContext = context;

    try {
      // 로딩 표시
      if (mounted) {
        showDialog(
          context: currentContext,
          barrierDismissible: false,
          builder: (dialogContext) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      // Firebase 사용자 확인
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('로그인이 필요합니다');
      }

      // 로컬 세션 생성
      final localSession = TrainingSession(
        id: '',
        userId: user.uid,
        trainings: _trainings,
        beepSound: _selectedSound,
        numPeople: _numPeople,
        createdAt: DateTime.now(),
        totalTime: _totalTime,
        totalDistance: _totalDist,
        title: '훈련 ${DateTime.now().toString().substring(0, 16)}',
      );

      // Firebase에 저장
      final sessionId = await _trainingRepository.saveTrainingSession(localSession);

      // 로딩 다이얼로그 닫기
      if (mounted) {
        Navigator.pop(currentContext);
      }

      // 타이머 화면으로 이동
      if (mounted) {
        Navigator.push(
          currentContext,
          MaterialPageRoute(
            builder: (_) => TGTimerScreen(
              sessionId: sessionId,
              fallbackData: localSession,
            ),
          ),
        );
      }
    } catch (e) {
      // 로딩 다이얼로그 닫기
      if (mounted) {
        Navigator.pop(currentContext);

        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(content: Text('저장 실패: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 커뮤니티 기능 (기존 함수 유지)
  void _showCommunityDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("커뮤니티 공유 기능 (개발 예정)")),
    );
  }

  // 새로 추가: FAB 액션 처리
  void _onFabAction(String action) {
    setState(() => _isFabExpanded = false);

    switch (action) {
      case "커뮤니티 공유":
        _showCommunityDialog();
        break;
      case "내 일정 저장":
        _saveToCalendar();
        break;
    }
  }

  // 새로 추가: 내 일정 저장 (캘린더에 저장)
  Future<void> _saveToCalendar() async {
    if (_trainings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장할 훈련이 없습니다')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('로그인이 필요합니다');
      }

      // 현재 날짜 설정
      final now = DateTime.now();
      final dateOnly = DateTime(now.year, now.month, now.day);

      // 훈련 데이터 변환
      final trainings = _trainings.map((training) => {
        'title': training.title,
        'distance': training.distance,
        'count': training.count,
        'cycle': training.cycle,
        'interval': training.interval,
        'restTime': training.restTime,
      }).toList();

      // 캘린더에 추가할 데이터
      final calendarEvent = {
        'userId': user.uid,
        'date': Timestamp.fromDate(dateOnly),
        'title': '훈련 계획 - ${_trainings.length}개',
        'totalDistance': _totalDist,
        'totalTime': _formatTime(_totalTime),
        'numPeople': _numPeople,
        'beepSound': _selectedSound.isNotEmpty,
        'trainings': trainings,
        'createdAt': FieldValue.serverTimestamp(),
        'type': 'planned', // 계획된 훈련임을 표시
      };

      // Firebase에 저장
      await FirebaseFirestore.instance
          .collection('calendar_events')
          .add(calendarEvent);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('내 일정에 저장되었습니다!'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('저장 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;

    if (hours > 0) {
      return "$hours:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}";
    } else {
      return "${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}";
    }
  }

  // 사이클 시간을 포맷하는 함수 (기존)
  String _formatCycle(int cycle) {
    if (cycle < 60) {
      return "$cycle초";
    } else if (cycle < 3600) {
      final minutes = cycle ~/ 60;
      final seconds = cycle % 60;
      if (seconds == 0) {
        return "$minutes분";
      } else {
        return "$minutes분 $seconds초";
      }
    } else {
      final hours = cycle ~/ 3600;
      final remainingMinutes = (cycle % 3600) ~/ 60;
      final remainingSeconds = cycle % 60;

      String result = "$hours시간";
      if (remainingMinutes > 0) {
        result += " $remainingMinutes분";
      }
      if (remainingSeconds > 0) {
        result += " $remainingSeconds초";
      }
      return result;
    }
  }

  // 정보 칩 위젯 (기존에서 약간 수정)
  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Text(
        "$label: $value",
        style: TextStyle(
          fontSize: 12,
          color: Colors.blue.shade700,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      // 상단바 - S.png 로고 + Training Generation
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
        actions: const [SizedBox(width: 48)], // 중앙 정렬을 위한 공간
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  // 훈련 목록 (기존 카드 방식 유지)
                  for (int i = 0; i < _trainings.length; i++)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // 기존 ListTile 기능 유지하면서 새로운 디자인 적용
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _goDetail(i), // 기존 기능 유지
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 훈련 제목
                                    Row(
                                      children: [
                                        Text(
                                          "${i + 1}. ${_trainings[i].title}",
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const Spacer(),
                                        // 거리/사이클 정보 (기존 trailing 정보)
                                        Text(
                                          "${_trainings[i].distance}m / ${_formatCycle(_trainings[i].cycle)}",
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 12),

                                    // 추가 정보 표시
                                    Wrap(
                                      spacing: 12,
                                      runSpacing: 8,
                                      children: [
                                        _buildInfoChip("개수", "${_trainings[i].count}개"),
                                        _buildInfoChip("간격", "${_trainings[i].interval}초"),
                                        if (i > 0) _buildInfoChip("쉬는시간", "${_trainings[i].restTime}초"),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // 삭제 버튼 (X 버튼) - 기존 기능 유지
                          if (_trainings.length > 1)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: InkWell(
                                onTap: () => _deleteTraining(i),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
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
                    ),

                  const SizedBox(height: 20),

                  // + 버튼 (훈련 추가) - 기존 기능 유지
                  GestureDetector(
                    onTap: _addTraining,
                    child: Container(
                      height: 60,
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.blue.shade300, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add,
                            color: Colors.blue,
                            size: 28,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "훈련 추가",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // 정보 표시 카드 (기존)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
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
                              "${_totalDist}m",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
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
                              "${_totalTime}초",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 음향 선택 (스피커 아이콘) - 기존 기능 유지
                  GestureDetector(
                    onTap: _onBeepSettings,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(16),
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
                        children: [
                          Icon(
                            Icons.volume_up,
                            size: 24,
                            color: Colors.blue.shade600,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "음향 설정",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "$_selectedSound, $_numPeople명",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // 시작 버튼들 (기존)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _onLayerPressed,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              "레이어",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _onStart,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text(
                              "Start",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),

      // 새로 추가: 오른쪽 아래 FAB 메뉴
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 20), // 하단 버튼 위에 위치
        child: TGFabMenu(
          isExpanded: _isFabExpanded,
          toggle: () => setState(() => _isFabExpanded = !_isFabExpanded),
          onAction: _onFabAction,
        ),
      ),
    );
  }
}