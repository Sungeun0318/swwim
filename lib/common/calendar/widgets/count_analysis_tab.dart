import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import 'swim_record.dart';

class CountAnalysisTab extends StatelessWidget {
  final List<SwimRecord> allRecords;
  final DateTime focusedMonth;

  const CountAnalysisTab({
    required this.allRecords,
    required this.focusedMonth,
  });

  @override
  Widget build(BuildContext context) {
    final months = List.generate(
      4,
          (i) => DateTime(
          focusedMonth.year, focusedMonth.month - (3 - i), 1),
    );
    final counts = months
        .map((m) => allRecords
        .where((r) => r.date.year == m.year && r.date.month == m.month)
        .length)
        .toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        child: Padding(
          padding:
          const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            children: [
              const Text('수영 횟수',
                  style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Expanded(
                child: CustomPaint(
                  painter: _CountBarPainter(
                      months: months, counts: counts),
                  child: Container(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountBarPainter extends CustomPainter {
  final List<DateTime> months;
  final List<int> counts;

  _CountBarPainter({required this.months, required this.counts});

  @override
  void paint(Canvas canvas, Size size) {
    // 축 그리기
    final axisPaint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 1;
    canvas.drawLine(
        Offset(0, size.height), Offset(size.width, size.height), axisPaint);

    final barPaint = Paint()..color = Colors.blueAccent;
    int n = counts.length;
    if (n == 0) return;
    double barW = size.width / (n * 2);
    double maxCount =
    counts.reduce((a, b) => a > b ? a : b).toDouble();
    if (maxCount == 0) maxCount = 1;

    for (int i = 0; i < n; i++) {
      final cx = (i * 2 + 1) * barW;
      final h = (counts[i] / maxCount) * (size.height - 20);
      final rect = Rect.fromLTWH(
          cx - barW / 2, size.height - h, barW, h);
      canvas.drawRect(rect, barPaint);

      // 월 라벨
      final label = DateFormat('M월').format(months[i]);
      final tp = TextPainter(
        text: TextSpan(
            text: label,
            style: const TextStyle(
                color: Colors.grey, fontSize: 12)),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(cx - tp.width / 2,
          size.height + 4));

      // 횟수 라벨
      final ct = TextPainter(
        text: TextSpan(
            text: '${counts[i]}',
            style: const TextStyle(
                color: Colors.pink, fontSize: 12)),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      ct.paint(canvas, Offset(cx - ct.width / 2,
          size.height - h - 16));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}
