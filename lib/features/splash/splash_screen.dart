// lib/features/splash/splash_screen.dart (즉시 표시 버전)
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';
import '../login/screens/login_sc.dart';
import '../../common/navigation/bottom_nav_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  bool _hasLottieError = false;

  @override
  void initState() {
    super.initState();

    // 페이드 인 애니메이션 (빠르게)
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800), // 빠르게 나타남
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    // 즉시 애니메이션 시작
    _fadeController.forward();

    // 자동 로그인 체크 및 화면 전환
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // 최소 3초는 스플래시 화면 보여주기
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool? autoLoginPref = prefs.getBool('autoLogin');
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null && autoLoginPref == true) {
        _navigateToMain();
      } else {
        if (user != null && autoLoginPref != true) {
          await FirebaseAuth.instance.signOut();
        }
        _navigateToLogin();
      }
    } catch (e) {
      print('인증 확인 중 오류: $e');
      _navigateToLogin();
    }
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _navigateToMain() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const BottomNavScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  // Lottie 대신 사용할 대체 위젯
  Widget _buildFallbackAnimation() {
    return AnimatedBuilder(
      animation: _fadeController,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.8 + (_fadeController.value * 0.2),
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade400,
                  Colors.cyan.shade300,
                  Colors.blue.shade600,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.4),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLottieWidget() {
    return Lottie.asset(
      'assets/animations/swimming_starter.json',
      fit: BoxFit.contain,
      repeat: true,
      animate: true,
      width: 280,
      height: 280,
      errorBuilder: (context, error, stackTrace) {
        print('Lottie 에러: $error');
        setState(() {
          _hasLottieError = true;
        });
        return _buildFallbackAnimation();
      },
      onLoaded: (composition) {
        print('Lottie 로드 성공! Duration: ${composition.duration}');
      },
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          // 심플한 그라데이션 배경
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade50,
              Colors.white,
              Colors.blue.shade50,
            ],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 상단 여백
              const Spacer(flex: 2),

              // 메인 애니메이션 (즉시 표시)
              Container(
                width: 280,
                height: 280,
                child: _hasLottieError
                    ? _buildFallbackAnimation()
                    : _buildLottieWidget(),
              ),
              // 로딩 인디케이터
              Column(
                children: [

                  const SizedBox(height: 16),
                  Text(
                    '앱을 시작하는 중...',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue.shade400,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              const Spacer(flex: 1),

              // 브랜딩
              Padding(
                padding: const EdgeInsets.only(bottom: 60),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.2),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/S.png',
                        width: 24,
                        height: 24,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),

                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'swimming starter',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.blue.shade600,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}