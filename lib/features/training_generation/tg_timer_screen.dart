import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import 'package:swim/features/training/models/training_detail_data.dart';
import 'tg_timer_controller.dart';

class TGTimerScreen extends StatefulWidget {
  final List<TrainingDetailData> trainingList;
  final String beepSound;
  final int numPeople;

  const TGTimerScreen({
    super.key,
    required this.trainingList,
    required this.beepSound,
    required this.numPeople,
  });

  @override
  State<TGTimerScreen> createState() => _TGTimerScreenState();
}

class _TGTimerScreenState extends State<TGTimerScreen> {
  late TGTimerController _timerController;
  late VideoPlayerController _videoController;
  Timer? _uiUpdateTimer;
  bool _videoInitialized = false;
  bool _isVideoError = false;

  @override
  void initState() {
    super.initState();

    // 타이머 컨트롤러 초기화
    _timerController = TGTimerController(
      trainingList: widget.trainingList,
      beepSound: widget.beepSound,
      numPeople: widget.numPeople,
      onUpdate: () {
        if (mounted) setState(() {});
      },
      onEvent: _handleTimerEvent,
    );

    // 비디오 컨트롤러 초기화
    _initVideoPlayer();

    // UI 업데이트 타이머
    _uiUpdateTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _initVideoPlayer() async {
    try {
      if (kDebugMode) {
        print("비디오 초기화 시작");
      }

      // 비디오 경로가 정확한지 확인
      const videoPath = 'assets/videos/swim.mp4'; // 이 경로가 정확한지 확인
      _videoController = VideoPlayerController.asset(videoPath);

      await _videoController.initialize().then((_) {
        if (kDebugMode) {
          print("비디오 초기화 성공");
        }

        _videoController.setLooping(true);
        // 볼륨 설정
        _videoController.setVolume(1.0);

        if (mounted) {
          setState(() {
            _videoInitialized = true;
          });
        }
      }).catchError((error) {
        if (kDebugMode) {
          print("비디오 초기화 실패: $error");
        }

        _isVideoError = true;
        if (mounted) setState(() {});
      });
    } catch (e) {
      _isVideoError = true;
      if (kDebugMode) {
        print("비디오 초기화 에러: $e");
      }
      if (mounted) setState(() {});
    }
  }

  // 타이머 이벤트 처리
  Future<void> _handleTimerEvent(String action) async {
    if (!mounted) return;

    try {
      switch (action) {
        case "start":
        // 훈련 시작 시 2.75초 후 비디오 재생
          Future.delayed(const Duration(milliseconds: 2750), () {
            if (mounted && !_timerController.isResting && _videoInitialized) {
              _videoController.play();
            }
          });
          break;

        case "rest_start":
        // 쉬는 시간 시작 시 비디오 일시정지
          if (_videoInitialized) _videoController.pause();
          break;

        case "complete":
        // 훈련 완료 시 비디오 초기화 및 정지
          if (_videoInitialized) {
            _videoController.pause();
            _videoController.seekTo(Duration.zero);
          }
          _showCompletionMessage();
          break;
      }
    } catch (e) {
      if (kDebugMode) {
        print("이벤트 처리 에러: $e");
      }
    }
  }

  // 완료 메시지 표시
  void _showCompletionMessage() {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "모든 훈련을 완료했습니다! 수고하셨습니다.",
          style: TextStyle(fontSize: 16),
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 5),
      ),
    );
  }

  @override
  void dispose() {
    _timerController.dispose();
    _videoController.dispose();
    _uiUpdateTimer?.cancel();
    super.dispose();
  }

  // 타이머 토글 (시작/일시정지/재개)
  Future<void> _handleToggle() async {
    if (!mounted || !_videoInitialized) return;

    try {
      if (_timerController.isCompleted) {
        _handleReset();
        return;
      }

      // 타이머가 시작되지 않은 상태에서 시작 버튼을 누른 경우
      if (!_timerController.isRunning) {
        _timerController.startTraining();
        // 비디오 재생은 이벤트 핸들러에서 처리 (쉬는 시간이 아닐 때만)
      }
      // 타이머가 일시정지된 상태에서 계속 버튼을 누른 경우
      else if (_timerController.isPaused) {
        _timerController.toggleTimer(); // 타이머 재개

        // 쉬는 시간이 아닐 때만 영상 재생
        if (!_timerController.isResting) {
          _videoController.play();
        }
      }
      // 타이머가 실행 중인 상태에서 정지 버튼을 누른 경우
      else {
        _timerController.toggleTimer(); // 타이머 일시정지
        _videoController.pause();
      }

      if (mounted) setState(() {});
    } catch (e) {
      if (kDebugMode) {
        print("토글 에러: $e");
      }
    }
  }

  // 타이머 리셋
  Future<void> _handleReset() async {
    if (!mounted || !_videoInitialized) return;

    try {
      _timerController.resetTimer();
      _videoController.pause();
      _videoController.seekTo(Duration.zero);

      if (mounted) setState(() {});
    } catch (e) {
      if (kDebugMode) {
        print("초기화 에러: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.description, color: Colors.pink, size: 24),
            SizedBox(width: 10),
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
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView( // ScrollView로 감싸서 오버플로우 방지
        child: Column(
          children: [
            // 쉬는 시간일 때는 비디오 대신 휴식 표시
            if (_timerController.isResting)
              Container(
                width: double.infinity,
                height: 220,
                color: Colors.cyan.shade100,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      size: 80,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "쉬는 시간",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "남은 시간: ${_timerController.restTimeRemaining}초",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    if (_timerController.restMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _timerController.restMessage,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrange,
                          ),
                        ),
                      ),
                  ],
                ),
              )
            else
              if (_videoInitialized && _videoController.value.isInitialized)
              // 비디오가 초기화되었고 준비된 경우
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: AspectRatio(
                    aspectRatio: _videoController.value.aspectRatio,
                    child: VideoPlayer(_videoController),
                  ),
                )
              else
                if (_isVideoError)
                // 비디오 오류 발생 시 대체 UI
                  Container(
                    width: double.infinity,
                    height: 220,
                    color: Colors.black,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                              Icons.error_outline, color: Colors.red, size: 40),
                          SizedBox(height: 8),
                          Text(
                            "비디오를 로드할 수 없습니다",
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                // 비디오 로딩 중 표시
                  Container(
                    width: double.infinity,
                    height: 220,
                    color: Colors.black,
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),

            const SizedBox(height: 20),

            // 타이틀 및 상태 표시
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _timerController.displayTitle,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _timerController.isResting ? Colors.cyan : Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: _timerController.isResting
                  ? Text(
                "휴식",
                style: const TextStyle(fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              )
                  : Text(
                "${_timerController.currentCycleIndex + 1}/${_timerController
                    .currentTrainingIndex < widget.trainingList.length
                    ? widget.trainingList[_timerController.currentTrainingIndex]
                    .count
                    : 0} ${_timerController.currentTrainingIndex <
                    widget.trainingList.length ? widget
                    .trainingList[_timerController.currentTrainingIndex]
                    .distance : 0}M",
                style: const TextStyle(fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.cyan),
              ),
            ),

            const SizedBox(height: 10),

            // 타이머 및 남은 시간 표시
            Text(
              _timerController.formattedElapsedTime,
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.red,
                fontFamily: 'YourCustomFont', // 실제 폰트 지정 필요
              ),
            ),

            // 남은 시간 표시
            Text(
              "남은 시간: ${_timerController.formattedRemainingTime}",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              _timerController.isResting
                  ? "휴식 시간"
                  : "싸이클: ${_timerController.currentCycleTime}초",
              style: TextStyle(
                fontSize: 20,
                color: _timerController.isResting ? Colors.blue : Colors.cyan,
              ),
            ),

            const SizedBox(height: 20),

            // 여기에 프로그레스 바 배치 (비디오 아래, 버튼 위)
            // 전체 진행 상황 프로그레스 바
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "전체 진행 상황",
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _timerController.isCompleted
                            ? "100%"
                            : "${(_timerController.totalProgress * 100)
                            .toInt()}%",
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _timerController.isCompleted
                          ? 1.0
                          : _timerController.totalProgress,
                      backgroundColor: Colors.grey[300],
                      color: Colors.pink,
                      minHeight: 10,
                    ),
                  ),
                ],
              ),
            ),

            // 현재 훈련 진행 상황 프로그레스 바
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "현재 진행",
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "${(_timerController.currentProgress * 100).toInt()}%",
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _timerController.currentProgress,
                      backgroundColor: Colors.grey[300],
                      color: _timerController.isResting ? Colors.blue : Colors
                          .cyan,
                      minHeight: 10,
                    ),
                  ),
                ],
              ),
            ),

            // 완료 메시지 (훈련 완료시)
            if (_timerController.isCompleted)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  "모든 훈련을 완료했습니다! 수고하셨습니다.",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // 버튼들
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _handleToggle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 14),
                  ),
                  child: Text(
                    _timerController.timerButtonText,
                    style: const TextStyle(color: Colors.pink, fontSize: 20),
                  ),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: _handleReset,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 14),
                  ),
                  child: const Text(
                    "초기화",
                    style: TextStyle(color: Colors.pink, fontSize: 20),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 40, vertical: 14),
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: Colors.black, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                "훈련 종료",
                style: TextStyle(color: Colors.black, fontSize: 20),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}