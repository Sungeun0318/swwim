import 'dart:ui' as ui;
import 'dart:math';
import 'package:flutter/material.dart';
import 'training_item.dart';

class ExerciseGraphWidget extends StatelessWidget {
  final DateTimeRange dateRange;
  final Map<DateTime, List<TrainingItem>> events;

  const ExerciseGraphWidget({super.key, required this.dateRange, required this.events});

  double parseDistance(String s) {
    try {
      List<String> parts = s.split('m');
      double value = double.parse(parts[0].trim());
      String multStr = parts[1].replaceAll(RegExp(r'[^0-9]'), '');
      double multiplier = double.parse(multStr);
      return value * multiplier;
    } catch (e) {
      return 0;
    }
  }

  List<_DayExercise> computeData() {
    List<_DayExercise> data = [];
    DateTime current = dateRange.start;
    while (!current.isAfter(dateRange.end)) {
      DateTime key = DateTime.utc(current.year, current.month, current.day);
      double total = 0;
      if (events.containsKey(key)) {
        for (var item in events[key]!) {
          total += parseDistance(item.distance);
        }
      }
      data.add(_DayExercise(date: current, totalDistance: total));
      current = current.add(Duration(days: 1));
    }
    return data;
  }

  @override
  Widget build(BuildContext context) {
    List<_DayExercise> data = computeData();
    double maxVal = data.fold(0, (prev, element) => max(prev, element.totalDistance));
    if (maxVal == 0) maxVal = 1;
    return SizedBox(
      width: double.maxFinite,
      height: 200,
      child: CustomPaint(
        painter: _LineGraphPainter(data: data, maxVal: maxVal),
      ),
    );
  }
}

class _LineGraphPainter extends CustomPainter {
  final List<_DayExercise> data;
  final double maxVal;

  _LineGraphPainter({required this.data, required this.maxVal});

  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = Colors.pinkAccent
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final paintPoint = Paint()
      ..color = Colors.pinkAccent
      ..style = PaintingStyle.fill;

    double spacing = data.length > 1 ? size.width / (data.length - 1) : size.width / 2;

    List<Offset> points = [];
    for (int i = 0; i < data.length; i++) {
      double x = i * spacing;
      double y = size.height - (data[i].totalDistance / maxVal) * size.height;
      points.add(Offset(x, y));
    }

    if (points.isNotEmpty) {
      Path path = Path();
      path.moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(path, paintLine);
    }

    for (Offset p in points) {
      canvas.drawCircle(p, 4, paintPoint);
    }

    for (int i = 0; i < points.length; i++) {
      final valueText = data[i].totalDistance.toStringAsFixed(0);
      final textSpan = TextSpan(
        text: valueText,
        style: TextStyle(color: Colors.black, fontSize: 10),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: ui.TextDirection.ltr,
      );
      textPainter.layout();
      Offset textOffset = Offset(
        points[i].dx - textPainter.width / 2,
        points[i].dy - textPainter.height - 4,
      );
      textPainter.paint(canvas, textOffset);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _DayExercise {
  final DateTime date;
  final double totalDistance;
  _DayExercise({required this.date, required this.totalDistance});
}
