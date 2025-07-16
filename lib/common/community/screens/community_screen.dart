import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/community_post.dart';
import 'profile_header.dart';
import 'search_bar.dart';
import 'tab_bar.dart';
import 'profile_share_sheet.dart';
import 'post_list.dart';
import 'profile_edit_screen.dart';
import 'new_post_screen.dart';
import 'messages_screen.dart';
import 'swim_mate_list_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({Key? key}) : super(key: key);
  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  int _selectedTab = 0; // 0: 게시글, 1: 피드

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      body: Column(
        children: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseAuth.instance.currentUser != null
                ? FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).snapshots()
                : null,
            builder: (context, snapshot) {
              final userData = snapshot.hasData && snapshot.data!.exists
                  ? snapshot.data!.data() as Map<String, dynamic>
                  : null;
              return ProfileHeader(
                userData: userData,
                onEdit: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileEditScreen())),
                onShare: () => showProfileShareSheet(context),
                onAddPost: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewPostScreen())),
                onDM: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MessagesScreen())),
                onSwimMateList: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SwimMateListScreen())),
              );
            },
          ),
          CommunitySearchBar(
            controller: _searchController,
            searchQuery: _searchQuery,
            onChanged: (v) => setState(() => _searchQuery = v.trim()),
            onClear: () => setState(() {
              _searchQuery = '';
              _searchController.clear();
            }),
          ),
          CommunityTabBar(
            selectedTab: _selectedTab,
            onTabChanged: (i) => setState(() => _selectedTab = i),
          ),
          Expanded(
            child: CommunityPostList(
              searchQuery: _searchQuery,
              onlyMine: _selectedTab == 0,
            ),
          ),
        ],
      ),
    );
  }
}
