import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'swim_record.dart';

class DailyAnalysisScreen extends StatelessWidget {
  final SwimRecord record;
  const DailyAnalysisScreen({Key? key, required this.record}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('yyyy년 M월 d일').format(record.date);
    final timeRange = '${DateFormat('HH:mm').format(record.date)} ~ '
        '${DateFormat('HH:mm').format(record.date.add(record.duration))}';

    return Scaffold(
      appBar: AppBar(
        title: Text(dateLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 타이틀 + 장소
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Text('${record.distance}m 아카이빙', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.place, size: 16, color: Colors.grey),
                    SizedBox(width: 4),
                    Text('오늘 다녀온 수영장', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),

          // 그라데이션 배너
          Container(
            height: 120,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: [ Color(0xFF00C6FF), Color(0xFF0072FF) ],
              ),
            ),
          ),

          // 세부 정보 카드
          Expanded(
            child: Card(
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${DateFormat('yy.MM.dd').format(record.date)}  ${DateFormat('a h:mm').format(record.date)} ~ ${DateFormat('a h:mm').format(record.date.add(record.duration))}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${record.distance}', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
                        const Text(' m', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _InfoColumn(label: '시간', value: record.duration.toString().split('.').first),
                        // _InfoColumn(label: '평균 페이스', value: record.avgPace != null ? '${record.avgPace}/100m' : '-'),
                        // _InfoColumn(label: '칼로리', value: record.calories != null ? '${record.calories} kcal' : '-'),
                        // _InfoColumn(label: '평균 심박수', value: record.avgHeartRate != null ? '${record.avgHeartRate} bpm' : '-'),
                      ],
                    ),
                    const Spacer(),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // 일지 작성 로직
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('수영일지 작성하기'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoColumn extends StatelessWidget {
  final String label;
  final String value;
  const _InfoColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
