
String formatTime(int milliseconds) {
  final duration = Duration(milliseconds: milliseconds);
  final hours = duration.inHours.toString().padLeft(2, '0');
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  final hundredths = (duration.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(2, '0');
  return "$hours:$minutes:$seconds.$hundredths";
}
