import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:swim/features/training/models/training_detail_data.dart';
import 'tg_timer_controller.dart';
import 'package:flutter/foundation.dart';

class TGTimerScreen extends StatefulWidget {
  final List<TrainingDetailData> trainingList;
  final String beepSound;
  final int numPeople;

  // super.key 문법으로 변경 (첫 번째 경고 해결)
  const TGTimerScreen({
    super.key,
    required this.trainingList,
    required this.beepSound,
    required this.numPeople,
  });

  @override
  State<TGTimerScreen> createState() => _TGTimerScreenState();
}

// 클래스 이름을 State<TGTimerScreen>으로 명시적 타입 지정 (두 번째 경고 해결)
class _TGTimerScreenState extends State<TGTimerScreen> {
  late TGTimerController _timerController;
  late VideoPlayerController _videoController;
  Timer? _uiUpdateTimer;

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

    // 비디오 컨트롤러 초기화 및 에러 처리 강화
    _videoController = VideoPlayerController.asset('assets/videos/swim.mp4');
    _videoController.initialize().then((_) {
      _videoController.setLooping(true);
      if (mounted) setState(() {});
    }).catchError((error) {
      if (kDebugMode) {
        print("Video initialization error: $error");
      }
    });

    // UI 업데이트 타이머
    _uiUpdateTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted) setState(() {});
    });
  }

  // onEvent 콜백을 별도 메서드로 추출하여 비동기 컨텍스트 문제 해결 (세 번째 경고 해결)
  Future<void> _handleTimerEvent(String action) async {
    // BuildContext를 캡처하지 않기 위해 메서드 내에서 상태를 체크
    if (!mounted) return;

    if (!_videoController.value.isInitialized) return;

    try {
      if (action == "start") {
        // 시작은 _handleToggle에서 처리
      } else if (action == "pause") {
        await _videoController.pause();
      } else if (action == "resume") {
        if (!_timerController.isResting && !_timerController.isCompleted) {
          await _videoController.play();
        }
      } else if (action == "reset") {
        await _videoController.pause();
        await _videoController.seekTo(Duration.zero);
      } else if (action == "rest_start") {
        await _videoController.pause();
      } else if (action == "complete") {
        // 반드시 영상 멈추고 처음으로 되돌리기
        await _videoController.pause();
        await _videoController.seekTo(Duration.zero);

        // 완료 메시지 표시
        _showCompletionMessage();
      }
    } catch (e) {
      if (kDebugMode) {
        print("Video controller error: $e");
      }
    }
  }

  // 완료 메시지 표시를 위한 별도 메서드
  void _showCompletionMessage() {
    if (!mounted) return;

    // 훈련 완료 메시지 표시 (스낵바)
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

  // BuildContext를 비동기 갭에서 사용하지 않도록 수정
  Future<void> _handleToggle() async {
    if (!mounted) return;

    try {
      if (_timerController.isCompleted) {
        // 훈련이 이미 완료된 상태면 리셋부터 해야함
        _handleReset();
        return;
      }

      if (!_timerController.isRunning) {
        _timerController.startTraining();

        // 영상 재생 시작 (타이밍 이슈 해결)
        Future.delayed(const Duration(milliseconds: 2750), () async {
          if (!mounted) return;

          // 상태 다시 확인
          if (_timerController.isRunning &&
              !_timerController.isPaused &&
              !_timerController.isResting &&
              !_timerController.isCompleted) {
            try {
              await _videoController.play();
            } catch (e) {
              if (kDebugMode) {
                print("Video play error: $e");
              }
            }
          }
        });
      } else if (_timerController.isPaused) {
        _timerController.toggleTimer();

        // 일시정지 해제 시 영상 재생 (쉬는 시간이나 완료 상태가 아닐 때만)
        if (!_timerController.isResting && !_timerController.isCompleted) {
          try {
            await _videoController.play();
          } catch (e) {
            if (kDebugMode) {
              print("Video resume error: $e");
            }
          }
        }
      } else {
        _timerController.toggleTimer();
        try {
          await _videoController.pause();
        } catch (e) {
          if (kDebugMode) {
            print("Video pause error: $e");
          }
        }
      }

      if (mounted) setState(() {});
    } catch (e) {
      if (kDebugMode) {
        print("Toggle error: $e");
      }
    }
  }

  Future<void> _handleReset() async {
    if (!mounted) return;

    try {
      _timerController.resetTimer();
      await _videoController.pause();
      await _videoController.seekTo(Duration.zero);

      if (mounted) setState(() {});
    } catch (e) {
      if (kDebugMode) {
        print("Reset error: $e");
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
      body: Column(
        children: [
          if (_videoController.value.isInitialized)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: AspectRatio(
                aspectRatio: _videoController.value.aspectRatio,
                child: VideoPlayer(_videoController),
              ),
            ),

          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _timerController.displayTitle,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),

          const SizedBox(height: 10),

          if (_timerController.isResting && _timerController.restMessage.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _timerController.restMessage,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: _timerController.isResting
                  ? Text(
                "휴식",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.cyan),
              )
                  : Text(
                "${_timerController.currentCycleIndex + 1}/${_timerController.currentTrainingIndex < widget.trainingList.length ? widget.trainingList[_timerController.currentTrainingIndex].count : 0} ${_timerController.currentTrainingIndex < widget.trainingList.length ? widget.trainingList[_timerController.currentTrainingIndex].distance : 0}M",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.cyan),
              ),
            ),

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
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "${(_timerController.totalProgress * 100).toInt()}%",
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _timerController.totalProgress,
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
                      "현재 훈련 진행",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "${(_timerController.currentProgress * 100).toInt()}%",
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _timerController.currentProgress,
                    backgroundColor: Colors.grey[300],
                    color: Colors.cyan,
                    minHeight: 10,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

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
            style: const TextStyle(fontSize: 20, color: Colors.cyan),
          ),

          // 완료 메시지 (훈련 완료시)
          if (_timerController.isCompleted)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _handleToggle,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
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
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
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
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
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
    );
  }
}