import 'package:flutter/material.dart';

class CommunitySearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String searchQuery;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  const CommunitySearchBar({Key? key, required this.controller, required this.searchQuery, required this.onChanged, required this.onClear}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF0061A8), width: 2),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            Image.asset('assets/images/S.png', width: 28, height: 28),
            const SizedBox(width: 8),
            const Icon(Icons.search, color: Color(0xFF0061A8), size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                style: const TextStyle(fontFamily: 'MyCustomFont', fontSize: 16),
                decoration: const InputDecoration(
                  hintText: '검색',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Color(0xFF0061A8)),
                ),
                onChanged: onChanged,
              ),
            ),
            if (searchQuery.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.close, color: Color(0xFF0061A8)),
                splashRadius: 18,
                onPressed: onClear,
              ),
          ],
        ),
      ),
    );
  }
} 