import 'package:flutter/material.dart';
import 'package:swim/features/swimming/screens/swimming_quickstart_level_selection_screen.dart';
import 'package:swim/features/training_generation/screens/tg_generation_screen.dart';

class SwimmingMainScreen extends StatelessWidget {
  const SwimmingMainScreen({Key? key}) : super(key: key);

  Widget _buildBigButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        height: 100,
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 40),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.pink, size: 40),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.pink,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 30),
                Center(
                  child: Image.asset(
                    'assets/images/z_top_logo.png',
                    width: 150,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 30),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Training Generation 버튼: TGGenerationScreen으로 이동
                        _buildBigButton(
                          context: context,
                          icon: Icons.description,
                          label: "Training Generation",
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const TGGenerationScreen()),
                            );
                          },
                        ),
                        // Quick Start 버튼
                        _buildBigButton(
                          context: context,
                          icon: Icons.pool,
                          label: "Quick Start",
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                  const SwimmingQuickStartLevelSelectionScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: screenWidth * 0.9,
                  height: 60,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    "광고 배너",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            Positioned(
              top: 10,
              left: 10,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.grey, size: 30),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
