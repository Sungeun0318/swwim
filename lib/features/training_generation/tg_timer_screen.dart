import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:swim/features/training/models/training_detail_data.dart';
import 'tg_timer_controller.dart';

class TGTimerScreen extends StatefulWidget {
  final List<TrainingDetailData> trainingList;
  final String beepSound;
  final int numPeople;

  const TGTimerScreen({
    Key? key,
    required this.trainingList,
    required this.beepSound,
    required this.numPeople,
  }) : super(key: key);

  @override
  _TGTimerScreenState createState() => _TGTimerScreenState();
}

class _TGTimerScreenState extends State<TGTimerScreen> {
  late TGTimerController _timerController;
  late VideoPlayerController _videoController;
  Timer? _uiUpdateTimer;

  @override
  void initState() {
    super.initState();
    _timerController = TGTimerController(
      trainingList: widget.trainingList,
      beepSound: widget.beepSound,
      numPeople: widget.numPeople,
      onUpdate: () {
        setState(() {});
      },
    );

    _videoController = VideoPlayerController.asset('assets/videos/swim.mp4')
      ..initialize().then((_) {
        _videoController.setLooping(true);
        setState(() {});
      });

    _uiUpdateTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timerController.dispose();
    _videoController.dispose();
    _uiUpdateTimer?.cancel();
    super.dispose();
  }

  void _handleToggle() async {
    if (!_timerController.isRunning) {
      _timerController.startTraining();
      if (_videoController.value.isInitialized && !_videoController.value.isPlaying) {
        await _videoController.play();
      }
    } else if (_timerController.isPaused) {
      _timerController.toggleTimer();
      if (_videoController.value.isInitialized && !_videoController.value.isPlaying) {
        await _videoController.play();
      }
    } else {
      _timerController.toggleTimer();
      if (_videoController.value.isInitialized && _videoController.value.isPlaying) {
        await _videoController.pause();
      }
    }
    setState(() {});
  }

  void _handleReset() async {
    _timerController.resetTimer();
    if (_videoController.value.isInitialized) {
      await _videoController.pause();
      await _videoController.seekTo(Duration.zero);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final currentTraining = widget.trainingList[_timerController.currentTrainingIndex];

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
              currentTraining.title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),

          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "${_timerController.currentCycleIndex + 1}/${currentTraining.count} ${currentTraining.distance}M",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.cyan),
            ),
          ),

          const SizedBox(height: 20),

          Text(
            _timerController.formattedElapsedTime,
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.red,
              fontFamily: 'YourCustomFont', // 실제 폰트 지정 필요
            ),
          ),

          const SizedBox(height: 10),

          Text(
            "싸이클: ${_timerController.currentCycleTime}초",
            style: const TextStyle(fontSize: 20, color: Colors.cyan),
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
