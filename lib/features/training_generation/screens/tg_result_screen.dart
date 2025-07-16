// lib/features/training_generation/screens/tg_result_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/training_session.dart';
import '../../swimming/models/training_detail_data.dart';

class TGResultScreen extends StatefulWidget {
  final String sessionId;
  final TrainingSession session;
  final String totalElapsedTime;

  const TGResultScreen({
    Key? key,
    required this.sessionId,
    required this.session,
    required this.totalElapsedTime,
  }) : super(key: key);

  @override
  State<TGResultScreen> createState() => _TGResultScreenState();
}

class _TGResultScreenState extends State<TGResultScreen> {
  bool _isLoading = false;
  bool _addedToCalendar = false;

  @override
  void initState() {
    super.initState();
    _checkCalendarStatus();
  }

  Future<void> _checkCalendarStatus() async {
    try {
      // 이미 캘린더에 추가되었는지 확인하는 로직
      // training_sessions 문서에서 addedToCalendar 필드 확인
      setState(() => _addedToCalendar = false); // 기본값
    } catch (e) {
      if (kDebugMode) {
        print('캘린더 상태 확인 오류: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '훈련 완료',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 완료 아이콘 및 메시지
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      size: 48,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '훈련 완료!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '수고하셨습니다! 훈련이 성공적으로 완료되었습니다.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 전체 요약 카드
            _buildSummaryCard(),
            const SizedBox(height: 20),

            // 각 훈련 상세 기록
            const Text(
              '훈련 상세 기록',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...widget.session.trainings.map((training) {
              final index = widget.session.trainings.indexOf(training);
              return _buildTrainingDetailCard(training, index);
            }).toList(),

            const SizedBox(height: 30),

            // 캘린더 추가 버튼
            _buildCalendarButton(),

            const SizedBox(height: 16),

            // 완료 버튼
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '완료',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.pool,
                    color: Colors.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.session.title ?? '훈련 완료',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('yyyy년 MM월 dd일 HH:mm').format(DateTime.now()),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 통계 정보
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('총 거리', '${widget.session.totalDistance}m', Colors.blue),
                _buildStatItem('소요 시간', widget.totalElapsedTime, Colors.green),
                _buildStatItem('훈련 수', '${widget.session.trainings.length}개', Colors.orange),
              ],
            ),

            const SizedBox(height: 16),

            // 추가 정보
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildInfoItem('인원', '${widget.session.numPeople}명'),
                  _buildInfoItem('비프음', widget.session.beepSound.toString() == 'true' ? '켜짐' : '꺼짐'),
                  _buildInfoItem('계획 시간', '${widget.session.totalTime}초'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildTrainingDetailCard(TrainingDetailData training, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '훈련 ${index + 1}: ${training.title}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      SizedBox(width: 4),
                      Text(
                        '완료',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 훈련 세부 정보
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildDetailChip('거리', '${training.distance}m'),
                _buildDetailChip('개수', '${training.count}개'),
                _buildDetailChip('싸이클', '${training.cycle}초'),
                _buildDetailChip('간격', '${training.interval}초'),
                if (training.restTime > 0)
                  _buildDetailChip('휴식', '${training.restTime}초'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 12,
          color: Colors.blue.shade700,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildCalendarButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _addedToCalendar ? null : _addToCalendar,
        icon: Icon(
          _addedToCalendar ? Icons.check_circle : Icons.calendar_today,
          size: 20,
        ),
        label: Text(
          _addedToCalendar ? '캘린더에 추가됨' : '캘린더에 추가',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _addedToCalendar ? Colors.grey : Colors.pink,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Future<void> _addToCalendar() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      // Firebase Auth 체크
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('로그인이 필요합니다');
      }

      // 실제 소요 시간 파싱
      final elapsedParts = widget.totalElapsedTime.split(':');
      final actualDuration = '${elapsedParts[0]}:${elapsedParts[1]}:${elapsedParts[2].split('.')[0]}';

      // 현재 날짜 설정
      final now = DateTime.now();
      final dateOnly = DateTime(now.year, now.month, now.day);

      // 훈련 데이터 변환
      final trainings = widget.session.trainings.map((training) => {
        'title': training.title,
        'distance': training.distance,
        'count': training.count,
        'cycle': training.cycle,
        'interval': training.interval,
        'restTime': training.restTime,
      }).toList();

      // 캘린더에 추가할 데이터
      final calendarEvent = {
        'userId': user.uid,
        'sessionId': widget.sessionId,
        'date': Timestamp.fromDate(dateOnly),
        'title': widget.session.title ?? '훈련 완료',
        'totalDistance': widget.session.totalDistance,
        'totalTime': actualDuration,
        'plannedTime': '${widget.session.totalTime}초',
        'numPeople': widget.session.numPeople,
        'beepSound': widget.session.beepSound.toString(),
        'trainings': trainings,
        'completedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Firebase에 저장
      final docRef = await FirebaseFirestore.instance
          .collection('calendar_events')
          .add(calendarEvent);

      if (kDebugMode) {
        print('캘린더 이벤트 저장 완료: ${docRef.id}');
      }

      // training_sessions 문서 업데이트
      await FirebaseFirestore.instance
          .collection('training_sessions')
          .doc(widget.sessionId)
          .update({
        'addedToCalendar': true,
        'calendarAddedAt': FieldValue.serverTimestamp(),
      });

      setState(() => _addedToCalendar = true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('캘린더에 성공적으로 추가되었습니다!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('캘린더 추가 오류: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('캘린더 추가 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
}