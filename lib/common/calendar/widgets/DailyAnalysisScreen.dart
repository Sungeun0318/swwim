import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'swim_record.dart';

class DailyAnalysisScreen extends StatelessWidget {
  final SwimRecord? record;
  const DailyAnalysisScreen({Key? key, required this.record}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (record == null) {
      // 데이터가 없을 때 기본 UI와 안내 메시지
      final now = DateTime.now();
      final dateLabel = DateFormat('yyyy년 M월 d일').format(now);
      return Scaffold(
        appBar: AppBar(
          title: Text(dateLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  Text('셀짱의 수영 아카이빙', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text('운동 기록이 없습니다', style: TextStyle(color: Colors.grey[600], fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            Container(
              height: 16,
              margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: [ Color(0xFF00C6FF), Color(0xFF0072FF) ],
                ),
              ),
            ),
            Expanded(
              child: Card(
                margin: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Spacer(),
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: () {},
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
    final dateLabel = DateFormat('yyyy년 M월 d일').format(record!.date);
    final timeRange = '${DateFormat('HH:mm').format(record!.date)} ~ '
        '${DateFormat('HH:mm').format(record!.date.add(record!.duration))}';

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
                Text('셀짱의 수영 아카이빙', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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

          // 주요 정보 카드 (거리, 시간, 칼로리, 심박수, 페이스)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('${DateFormat('yy.MM.dd').format(record!.date)}  ${DateFormat('a h:mm').format(record!.date)} ~ ${DateFormat('a h:mm').format(record!.date.add(record!.duration))}',
                      style: TextStyle(color: Colors.grey[600])),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('${record!.distance}m', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _InfoColumn(label: '시간', value: record!.duration.toString().split('.').first),
                    _InfoColumn(label: '평균 페이스', value: record!.avgPace != null ? '${record!.avgPace}/100m' : '-'),
                    _InfoColumn(label: '칼로리', value: record!.calories != null ? '${record!.calories} kcal' : '-'),
                    _InfoColumn(label: '평균 심박수', value: record!.avgHeartRate != null ? '${record!.avgHeartRate} bpm' : '-'),
                  ],
                ),
              ],
            ),
          ),

          // 그라데이션 배너(이미지 스타일)
          Container(
            height: 16,
            margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: [ Color(0xFF00C6FF), Color(0xFF0072FF) ],
              ),
            ),
          ),

          // 세부 정보 카드(수영일지 작성)
          Expanded(
            child: Card(
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
