// lib/features/training_generation/tg_result_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swim/features/training_generation/models/training_session.dart';
import 'package:swim/repositories/training_repository.dart';
import 'package:swim/features/swimming/models/training_detail_data.dart';
import 'package:intl/intl.dart';

class TGResultScreen extends StatefulWidget {
  final String sessionId;
  final TrainingSession session;
  final String totalElapsedTime;

  const TGResultScreen({
    super.key, // Key? key 대신 super.key 사용
    required this.sessionId,
    required this.session,
    required this.totalElapsedTime,
  });

  @override
  State<TGResultScreen> createState() => _TGResultScreenState();
}

class _TGResultScreenState extends State<TGResultScreen> {
  final TrainingRepository _repository = TrainingRepository();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  bool _addedToCalendar = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          '오늘 나의 훈련 프로그램',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 전체 요약
            _buildSummaryCard(),
            const SizedBox(height: 20),

            // 각 훈련 상세 기록
            const Text(
              '훈련 상세 기록',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...widget.session.trainings.map((training) {
              final index = widget.session.trainings.indexOf(training);
              return _buildTrainingDetailCard(training, index);
            }).toList(),

            const SizedBox(height: 30),

            // 캘린더 추가 버튼
            _buildCalendarButton(),

            const SizedBox(height: 20),

            // 완료 버튼
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                '완료',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '훈련 요약',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '완료',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            _buildSummaryRow('총 시간', widget.totalElapsedTime),
            _buildSummaryRow('총 거리', '${widget.session.totalDistance}m'),
            _buildSummaryRow('훈련 수', '${widget.session.trainings.length}개'),
            _buildSummaryRow('인원', '${widget.session.numPeople}명'),
            _buildSummaryRow('완료 시간', _formatDateTime(DateTime.now())),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTrainingDetailCard(TrainingDetailData training, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '훈련 ${index + 1}: ${training.title}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Icon(Icons.check_circle, color: Colors.green),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDetailItem('거리', '${training.distance}m'),
                _buildDetailItem('개수', '${training.count}개'),
                _buildDetailItem('싸이클', '${training.cycle}초'),
                _buildDetailItem('간격', '${training.interval}초'),
              ],
            ),
            if (training.restTime > 0) ...[
              const SizedBox(height: 8),
              Text(
                '휴식: ${training.restTime}초',
                style: TextStyle(color: Colors.blue.shade700),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildCalendarButton() {
    return ElevatedButton.icon(
      onPressed: _addedToCalendar ? null : _addToCalendar,
      icon: Icon(_addedToCalendar ? Icons.check : Icons.calendar_today),
      label: Text(_addedToCalendar ? '캘린더에 추가됨' : '캘린더에 추가'),
      style: ElevatedButton.styleFrom(
        backgroundColor: _addedToCalendar ? Colors.grey : Colors.pink,
        minimumSize: const Size(double.infinity, 45),
      ),
    );
  }

  Future<void> _addToCalendar() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('로그인이 필요합니다');

      // 현재 날짜를 제대로 설정
      final now = DateTime.now();
      final dateOnly = DateTime(now.year, now.month, now.day);

      // 총 실제 소요 시간 계산 (formattedElapsedTime 파싱)
      final elapsedParts = widget.totalElapsedTime.split(':');
      final actualDuration = '${elapsedParts[0]}:${elapsedParts[1]}:${elapsedParts[2].split('.')[0]}';

      // 캘린더에 추가할 데이터
      final calendarEvent = {
        'userId': user.uid,
        'sessionId': widget.sessionId,
        'date': Timestamp.fromDate(dateOnly), // 날짜만 저장
        'title': widget.session.title ?? '훈련 완료',
        'totalDistance': widget.session.totalDistance,
        'totalTime': actualDuration, // 실제 소요 시간
        'plannedTime': widget.session.totalTime, // 계획된 시간 (초)
        'numPeople': widget.session.numPeople,
        'beepSound': widget.session.beepSound,
        'trainings': widget.session.trainings.map((t) => {
          'title': t.title,
          'distance': t.distance,
          'count': t.count,
          'cycle': t.cycle,
          'interval': t.interval,
          'restTime': t.restTime,
        }).toList(),
        'completedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (kDebugMode) {
        print('캘린더 이벤트 데이터: $calendarEvent'); // 디버깅용
      }

      // Firebase에 저장
      final docRef = await _firestore.collection('calendar_events').add(calendarEvent);
      if (kDebugMode) {
        print('캘린더 이벤트 저장 완료: ${docRef.id}'); // 디버깅용
      }

      // training_sessions 문서 업데이트
      await _firestore
          .collection('training_sessions')
          .doc(widget.sessionId)
          .update({
        'addedToCalendar': true,
        'calendarAddedAt': FieldValue.serverTimestamp(),
      });

      setState(() => _addedToCalendar = true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('캘린더에 추가되었습니다')),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('캘린더 추가 오류: $e'); // 디버깅용
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('캘린더 추가 실패: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy.MM.dd HH:mm').format(dateTime);
  }
}