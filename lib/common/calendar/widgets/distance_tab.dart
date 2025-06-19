import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import 'swim_record.dart';

class DistanceTab extends StatelessWidget {
  final List<SwimRecord> records;
  final DateTime month;
  final List<SwimRecord> allRecords;

  const DistanceTab({
    required this.records,
    required this.month,
    required this.allRecords,
  });

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    List<double> cumulative = List.filled(daysInMonth, 0);
    double sum = 0;
    for (var r in records) {
      sum += r.distance;
      cumulative[r.date.day - 1] = sum / 1000;
    }
    for (int i = 1; i < daysInMonth; i++) {
      if (cumulative[i] == 0) cumulative[i] = cumulative[i - 1];
    }
    final focusIndex = (DateTime.now().year == month.year &&
        DateTime.now().month == month.month)
        ? DateTime.now().day - 1
        : daysInMonth - 1;

    // 이전 달 누적
    final prevMonth = DateTime(month.year, month.month - 1);
    final prevRecs = allRecords
        .where((r) => r.date.year == prevMonth.year && r.date.month == prevMonth.month)
        .toList();
    final prevDays = DateUtils.getDaysInMonth(prevMonth.year, prevMonth.month);
    List<double> prevCum = List.filled(prevDays, 0);
    double prevSum = 0;
    for (var r in prevRecs) {
      prevSum += r.distance;
      prevCum[r.date.day - 1] = prevSum / 1000;
    }
    for (int i = 1; i < prevDays; i++) {
      if (prevCum[i] == 0) prevCum[i] = prevCum[i - 1];
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            children: [
              Expanded(
                child: CustomPaint(
                  painter: DistancePainter(
                    data: cumulative,
                    focusDay: focusIndex,
                  ),
                  child: Container(),
                ),
              ),
              const SizedBox(height: 16),
              _LegendTable(
                monthLabel: DateFormat('M월').format(month),
                totalDistance: cumulative.last,
                averageDistance:
                records.isNotEmpty ? cumulative.last / records.length : 0,
                prevDistance: prevCum.last,
                prevAverage:
                prevRecs.isNotEmpty ? prevCum.last / prevRecs.length : 0,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DistancePainter extends CustomPainter {
  final List<double> data;
  final int focusDay;

  DistancePainter({required this.data, required this.focusDay});

  @override
  void paint(Canvas canvas, Size size) {
    // 그리드
    final grid = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      double y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    // 라인
    final line = Paint()
      ..color = Colors.blueAccent
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final path = Path();
    double maxY = data.reduce((a, b) => a > b ? a : b);
    if (maxY == 0) maxY = 1;
    for (int i = 0; i < data.length; i++) {
      double x = size.width * i / (data.length - 1);
      double y = size.height - (data[i] / maxY) * size.height;
      if (i == 0) path.moveTo(x, y);
      else path.lineTo(x, y);
    }
    canvas.drawPath(path, line);
    // 포커스 점선 및 포인트
    final fx = size.width * focusDay / (data.length - 1);
    final dash = Paint()..color = Colors.grey..strokeWidth = 1;
    const dashLen = 4.0;
    double sy = 0;
    while (sy < size.height) {
      canvas.drawLine(Offset(fx, sy), Offset(fx, sy + dashLen), dash);
      sy += dashLen * 2;
    }
    final fy = size.height - (data[focusDay] / maxY) * size.height;
    canvas.drawCircle(Offset(fx, fy), 6, Paint()..color = Colors.redAccent);
    // 누적 라벨
    final tp = TextPainter(
      text: TextSpan(
          text: '총 ${data.last.toStringAsFixed(1)}km',
          style: const TextStyle(color: Colors.white, fontSize: 12)),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    final bw = tp.width + 12, bh = tp.height + 8;
    final rect =
    Rect.fromLTWH(fx - bw / 2, fy - bh - 12, bw, bh);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(6)),
      Paint()..color = Colors.blueAccent,
    );
    tp.paint(canvas, Offset(rect.left + 6, rect.top + 4));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _LegendTable extends StatelessWidget {
  final String monthLabel;
  final double totalDistance;
  final double averageDistance;
  final double prevDistance;
  final double prevAverage;

  const _LegendTable({
    required this.monthLabel,
    required this.totalDistance,
    required this.averageDistance,
    required this.prevDistance,
    required this.prevAverage,
  });

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {
        0: FractionColumnWidth(.3),
        1: FractionColumnWidth(.35),
        2: FractionColumnWidth(.35),
      },
      children: [
        TableRow(children: [
          Text('월', style: TextStyle(color: Colors.grey[600])),
          Text('1회 평균 거리', style: TextStyle(color: Colors.grey[600])),
          Text('누적 거리', style: TextStyle(color: Colors.grey[600])),
        ]),
        TableRow(children: [
          Text(monthLabel, style: const TextStyle(color: Colors.blueAccent)),
          Text('${(averageDistance * 1000).toInt()}m',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Text('${totalDistance.toStringAsFixed(1)}km',
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ]),
        TableRow(children: [
          Text('이전 달', style: TextStyle(color: Colors.grey)),
          Text('${(prevAverage * 1000).toInt()}m',
              style: TextStyle(color: Colors.grey)),
          Text('${prevDistance.toStringAsFixed(1)}km',
              style: TextStyle(color: Colors.grey)),
        ]),
      ],
    );
  }
}
