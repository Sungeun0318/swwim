// lib/training_generation/tg_timer_display.dart
import 'package:flutter/material.dart';
import 'tg_format_time.dart';

class TGTimerDisplay extends StatelessWidget {
  final int elapsedMs;

  const TGTimerDisplay({Key? key, required this.elapsedMs}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      formatTime(elapsedMs),
      style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.red),
    );
  }
}
