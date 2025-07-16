import 'package:flutter/material.dart';

void showProfileShareSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const ProfileShareSheet(),
  );
}

class ProfileShareSheet extends StatelessWidget {
  const ProfileShareSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 24, left: 16, right: 16, bottom: 32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF3A8DFF), Color(0xFF6AC6FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 32),
              const Text('프로필 공유', style: TextStyle(fontFamily: 'MyCustomFont', fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // QR코드 (임시 placeholder)
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Icon(Icons.qr_code, size: 100, color: Color(0xFF3A8DFF)),
                  ),
                ),
                const SizedBox(height: 16),
                Text('@my_profile_id', style: TextStyle(fontFamily: 'MyCustomFont', fontSize: 20, color: Color(0xFF3A8DFF), fontWeight: FontWeight.bold, letterSpacing: 2)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ProfileShareAction(icon: Icons.ios_share, label: '프로필 공유', onTap: () {}),
              _ProfileShareAction(icon: Icons.link, label: '링크 복사', onTap: () {}),
              _ProfileShareAction(icon: Icons.download, label: '다운로드', onTap: () {}),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileShareAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ProfileShareAction({Key? key, required this.icon, required this.label, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: Icon(icon, color: Color(0xFF3A8DFF), size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontFamily: 'MyCustomFont', fontSize: 13, color: Colors.white)),
        ],
      ),
    );
  }
} 