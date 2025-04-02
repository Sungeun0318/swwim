import 'package:flutter/material.dart';
import '../../features/training_selection/training_screen.dart';
import '../calendar/calendar_screen.dart';
import '../notifications/notification_screen.dart';
import '../community/community_screen.dart';
import '../help/help_screen.dart';
import '../more/more_screen.dart';

class BottomNavScreen extends StatefulWidget {
  const BottomNavScreen({Key? key}) : super(key: key);

  @override
  State<BottomNavScreen> createState() => _BottomNavScreenState();
}

class _BottomNavScreenState extends State<BottomNavScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const TrainingScreen(),  // 트레이닝 선택 화면 (기본 화면)
    const CalendarScreen(),  // 일정
    const NotificationScreen(), // 알림
    const CommunityScreen(), // 커뮤니티
    const HelpScreen(), // 도움말
    const MoreScreen(), // 더보기
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200], // 🔥 모든 화면의 배경을 회색으로 설정
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black, // 🔥 배경색 검정색 (#000000)
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.red, // 🔥 선택된 글씨색 빨간색 (#FF0000)
        unselectedItemColor: Colors.white, // 선택되지 않은 아이콘은 흰색
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.play_circle), label: "트레이닝"),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: "일정"),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: "알림"),
          BottomNavigationBarItem(icon: Icon(Icons.forum), label: "커뮤니티"),
          BottomNavigationBarItem(icon: Icon(Icons.help_outline), label: "도움말"),
        ],
      ),
    );
  }
}
