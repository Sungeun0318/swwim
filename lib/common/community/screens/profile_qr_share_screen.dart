import 'package:flutter/material.dart';
// import 'package:qr_flutter/qr_flutter.dart'; // 실제 QR코드 사용시 주석 해제

class ProfileQrShareScreen extends StatelessWidget {
  const ProfileQrShareScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String profileId = '@SSSE._.RI'; // 실제 데이터로 교체
    final String qrData = 'https://instagram.com/ssse._.ri'; // 실제 데이터로 교체
    return Scaffold(
      backgroundColor: const Color(0xFF3A8DFF),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF3A8DFF), Color(0xFF7F5CFF)],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.close, color: Colors.white, size: 32),
                      ),
                      OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: const Text('색상', style: TextStyle(color: Colors.white)),
                      ),
                      Icon(Icons.qr_code_2, color: Colors.white, size: 32),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Column(
                    children: [
                      // 실제 QR코드 사용시 아래 주석 해제
                      // QrImage(data: qrData, size: 220, foregroundColor: Color(0xFF3A8DFF)),
                      Icon(Icons.qr_code_2, color: Color(0xFF3A8DFF), size: 220),
                      const SizedBox(height: 16),
                      Text(profileId, style: const TextStyle(fontFamily: 'MyCustomFont', fontSize: 28, color: Color(0xFF3A8DFF), fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _QrShareButton(icon: Icons.share, label: '프로필 공유', onTap: () {}),
                      _QrShareButton(icon: Icons.link, label: '링크 복사', onTap: () {}),
                      _QrShareButton(icon: Icons.download, label: '다운로드', onTap: () {}),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QrShareButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QrShareButton({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Color(0xFF3A8DFF), size: 32),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontFamily: 'MyCustomFont', fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black)),
            ],
          ),
        ),
      ),
    );
  }
} 