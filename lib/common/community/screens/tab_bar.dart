import 'package:flutter/material.dart';

class CommunityTabBar extends StatelessWidget {
  final int selectedTab;
  final ValueChanged<int> onTabChanged;
  const CommunityTabBar({Key? key, required this.selectedTab, required this.onTabChanged}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => onTabChanged(0),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Text('게시글',
                    style: TextStyle(
                      fontFamily: 'MyCustomFont',
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: selectedTab == 0 ? Colors.black : Colors.black38,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 3,
                    color: selectedTab == 0 ? Color(0xFF0061A8) : Colors.transparent,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => onTabChanged(1),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Text('피드',
                    style: TextStyle(
                      fontFamily: 'MyCustomFont',
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: selectedTab == 1 ? Colors.black : Colors.black38,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 3,
                    color: selectedTab == 1 ? Color(0xFF0061A8) : Colors.transparent,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 