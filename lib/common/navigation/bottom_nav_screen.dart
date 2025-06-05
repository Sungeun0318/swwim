import 'package:flutter/material.dart';
import '../../features/training/training_selection/training_screen.dart';
import '../calendar/calendar_screen.dart';
import '../notifications/notification_screen.dart';
import '../community/screens/community_screen.dart';
import '../more/more_screen.dart';

class BottomNavScreen extends StatefulWidget {
  const BottomNavScreen({Key? key}) : super(key: key);

  @override
  State<BottomNavScreen> createState() => _BottomNavScreenState();
}

class _BottomNavScreenState extends State<BottomNavScreen> {
  int _selectedIndex = 2; // 기본적으로 홈 화면(가운데)이 선택되도록 설정

  final List<Widget> _screens = [
    const CalendarScreen(),    // 캘린더
    const CommunityScreen(),   // 커뮤니티
    const TrainingScreen(),    // 홈 (트레이닝 화면)
    const NotificationScreen(), // 알림
    const MoreScreen(),        // 더보기
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 5,
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.black,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            selectedItemColor: Colors.pink,
            unselectedItemColor: Colors.grey,
            items: [
              // 캘린더
              BottomNavigationBarItem(
                icon: Icon(_selectedIndex == 0 ? Icons.calendar_month : Icons.calendar_month_outlined),
                label: "캘린더",
              ),
              // 커뮤니티
              BottomNavigationBarItem(
                icon: Icon(_selectedIndex == 1 ? Icons.people : Icons.people_outline),
                label: "커뮤니티",
              ),
              // 홈 (트레이닝)
              BottomNavigationBarItem(
                icon: Icon(_selectedIndex == 2 ? Icons.home : Icons.home_outlined),
                label: "홈",
              ),
              // 알림
              BottomNavigationBarItem(
                icon: Icon(_selectedIndex == 3 ? Icons.notifications : Icons.notifications_outlined),
                label: "알림",
              ),
              // 더보기
              BottomNavigationBarItem(
                icon: Icon(_selectedIndex == 4 ? Icons.more_horiz : Icons.more_horiz_outlined),
                label: "더보기",
              ),
            ],
          ),
        ),
      ),
    );
  }
}