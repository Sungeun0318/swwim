// lib/common/calendar/calendar_screen.dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'widgets/add_event_dialog.dart';

import 'widgets/fab_menu.dart';
import '../../features/training_generation/screens/tg_generation_screen.dart';

class TrainingItem {
  final String id;
  final String name;
  final String distance;
  final String time;
  final DateTime date;
  final String? sessionId;
  final Map<String, dynamic>? trainingData;

  TrainingItem({
    required this.id,
    required this.name,
    required this.distance,
    required this.time,
    required this.date,
    this.sessionId,
    this.trainingData,
  });
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<TrainingItem> _selectedEvents = [];
  Map<DateTime, List<TrainingItem>> _events = {};
  bool _isLoading = false;
  bool _isFabExpanded = false;

  // 통계 데이터
  int _totalSessions = 0;
  double _totalDistanceKm = 0.0;
  Duration _totalDuration = Duration.zero;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadCalendarData();
  }

  Future<void> _loadCalendarData() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('calendar_events')
          .where('userId', isEqualTo: user.uid)
          .orderBy('date', descending: true)
          .get();

      final Map<DateTime, List<TrainingItem>> events = {};
      int totalSessions = 0;
      double totalDistanceKm = 0.0;
      Duration totalDuration = Duration.zero;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final date = (data['date'] as Timestamp).toDate();
        final key = DateTime(date.year, date.month, date.day);

        // 통계 계산
        totalSessions++;
        totalDistanceKm += (data['totalDistance'] ?? 0) / 1000.0;

        // 시간 파싱 개선
        final timeStr = data['totalTime'] ?? '00:00:00';
        final duration = _parseDuration(timeStr);
        totalDuration += duration;

        // 이벤트 아이템 생성 - 개별 훈련이 아닌 전체 세션으로 표시
        final item = TrainingItem(
          id: doc.id,
          name: data['title'] ?? '훈련',
          distance: '${data['totalDistance'] ?? 0}m',
          time: timeStr,
          date: date,
          sessionId: data['sessionId'],
          trainingData: data,
        );

        events[key] = events[key] ?? [];
        events[key]!.add(item);

        if (kDebugMode) {
          print('로드된 이벤트: ${data['title']} - ${date.toString()}');
        }
      }

      setState(() {
        _events.clear();
        _events.addAll(events);
        _totalSessions = totalSessions;
        _totalDistanceKm = totalDistanceKm;
        _totalDuration = totalDuration;
        _isLoading = false;
      });

      if (kDebugMode) {
        print('총 ${events.length}개 날짜에 ${totalSessions}개 이벤트 로드 완료');
      }
    } catch (e) {
      if (kDebugMode) {
        print('캘린더 데이터 로드 오류: $e');
      }
      setState(() => _isLoading = false);
    }
  }

  Duration _parseDuration(String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length >= 3) {
        final hours = int.parse(parts[0]);
        final minutes = int.parse(parts[1]);
        final seconds = int.parse(parts[2].split('.')[0]);
        return Duration(hours: hours, minutes: minutes, seconds: seconds);
      }
    } catch (e) {
      if (kDebugMode) {
        print('시간 파싱 오류: $e');
      }
    }
    return Duration.zero;
  }

  void _addTraining(TrainingItem item) {
    final key = DateTime.utc(item.date.year, item.date.month, item.date.day);
    setState(() {
      _events[key] = _events[key] ?? [];
      _events[key]!.add(item);
    });
  }

  List<TrainingItem> _getEvents(DateTime day) {
    final key = DateTime.utc(day.year, day.month, day.day);
    return _events[key] ?? [];
  }

  void _onFabAction(String action) {
    setState(() => _isFabExpanded = false);

    switch (action) {
      case "일정 추가":
        _showAddEventDialog();
        break;
      case "커뮤니티 공유":
        _showCommunityShareDialog();
        break;
      case "훈련 바로 시작":
        _goToTrainingGeneration();
        break;
    }
  }

  // 1. 일정 추가 다이얼로그
  void _showAddEventDialog() {
    final selectedDate = _selectedDay ?? DateTime.now();

    showDialog(
      context: context,
      builder: (context) => AddEventDialog(
        selectedDate: selectedDate,
        onEventAdded: () {
          _loadCalendarData(); // 데이터 새로고침
        },
      ),
    );
  }

  // 2. 커뮤니티 공유 (임시)
  void _showCommunityShareDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('커뮤니티 공유 기능 (개발 예정)')),
    );
  }

  // 3. 훈련 바로 시작
  void _goToTrainingGeneration() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TGGenerationScreen(),
      ),
    ).then((_) {
      // 훈련 후 돌아왔을 때 데이터 새로고침
      _loadCalendarData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final monthLabel = DateFormat('yyyy.MM').format(_focusedDay);
    final today = DateTime.now();

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // S 로고만 표시
            Image.asset(
              'assets/images/S.png',
              width: 32,
              height: 32,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── 상단 통계 카드 ──
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.bar_chart, size: 24, color: Colors.blue),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('총 거리', '${(_totalDistanceKm * 1000).toStringAsFixed(0)}m', Icons.straighten, Colors.blue),
                    _buildStatItem('총 칼로리', '${_stats['totalCalories'] ?? 0}kcal', Icons.local_fire_department, Colors.redAccent),
                    _buildStatItem('총 횟수', '${_totalSessions}회', Icons.pool, Colors.green),
                    _buildStatItem('총 시간', '${_totalDuration.inHours}h ${_totalDuration.inMinutes % 60}m', Icons.access_time, Colors.deepPurple),
                  ],
                ),
              ],
            ),
          ),

          // ── 월 네비게이션 ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1);
                    });
                  },
                ),
                Text(
                  monthLabel,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() {
                      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1);
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () {
                    // 메뉴 기능 구현
                  },
                ),
              ],
            ),
          ),

          // ── 캘린더 ──
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TableCalendar(
                headerVisible: false,
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
                calendarFormat: CalendarFormat.month,
                eventLoader: _getEvents,
                daysOfWeekStyle: const DaysOfWeekStyle(
                  weekendStyle: TextStyle(color: Colors.red),
                  weekdayStyle: TextStyle(color: Colors.black),
                ),
                calendarStyle: const CalendarStyle(
                  outsideDaysVisible: false,
                  markersMaxCount: 3,
                  markerSize: 6.0,
                  markerMargin: EdgeInsets.symmetric(horizontal: 1.0),
                  todayDecoration: BoxDecoration(
                    color: Colors.lightBlue,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: BoxDecoration(
                    color: Colors.pink,
                    shape: BoxShape.circle,
                  ),
                ),
                availableGestures: AvailableGestures.horizontalSwipe,
                onPageChanged: (focused) => setState(() => _focusedDay = focused),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                    _selectedEvents = _getEvents(selectedDay);
                  });
                },
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (ctx, day, _) => _buildDayCell(day),
                  todayBuilder: (ctx, day, _) => _buildDayCell(day, isToday: true),
                  selectedBuilder: (ctx, day, _) => _buildDayCell(day, isSelected: true),
                ),
              ),
            ),
          ),

          // ── 일별 기록 리스트 ──
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: _selectedDay == null
                  ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_today, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      '날짜를 선택해 주세요',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              )
                  : _selectedEvents.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.pool, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('yyyy년 MM월 dd일').format(_selectedDay!),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '운동 기록이 없습니다',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              )
                  : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      DateFormat('yyyy년 MM월 dd일').format(_selectedDay!),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _selectedEvents.length,
                      itemBuilder: (_, idx) {
                        final item = _selectedEvents[idx];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          elevation: 2,
                          child: ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.pool,
                                color: Colors.blue.shade600,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              item.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Text(
                              '거리: ${item.distance} • 시간: ${item.time}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.info, color: Colors.blue),
                                  onPressed: () => _showTrainingDetail(item),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteTraining(item),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 80),
        child: FabMenu(
          isExpanded: _isFabExpanded,
          toggle: () => setState(() => _isFabExpanded = !_isFabExpanded),
          onAction: _onFabAction,
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Flexible(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 9),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCell(DateTime day, {bool isToday = false, bool isSelected = false}) {
    final events = _getEvents(day);
    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isSelected
            ? Colors.blue
            : isToday
            ? Colors.lightBlue.shade100
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              '${day.day}',
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          if (events.isNotEmpty)
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Colors.pink,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 훈련 상세 정보 표시
  void _showTrainingDetail(TrainingItem item) {
    if (item.trainingData == null) return;

    final data = item.trainingData!;
    final trainings = data['trainings'] as List? ?? [];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('📅 날짜: ${DateFormat('yyyy년 MM월 dd일').format(item.date)}'),
              const SizedBox(height: 8),
              Text('🏊‍♂️ 총 거리: ${item.distance}'),
              Text('⏱️ 총 시간: ${item.time}'),
              Text('👥 인원: ${data['numPeople'] ?? 1}명'),
              const Divider(),
              const Text('세부 훈련:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...trainings.map((training) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• ${training['title'] ?? '훈련'}: ${training['distance']}m × ${training['count']}회',
                  style: const TextStyle(fontSize: 14),
                ),
              )).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTraining(TrainingItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('훈련 기록 삭제'),
        content: Text('${item.name}을(를) 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('calendar_events')
            .doc(item.id)
            .delete();

        await _loadCalendarData(); // 데이터 새로고침

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('훈련 기록이 삭제되었습니다')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('삭제 실패: $e')),
          );
        }
      }
    }
  }
}