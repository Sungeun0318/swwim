import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 추가: SharedPreferences 사용
import 'google_sign_sc.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with WidgetsBindingObserver {
  final _idController = TextEditingController();
  final _pwController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  bool isLoading = false;
  bool _autoLogin = false; // 자동 로그인 체크 여부

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAutoLogin();  // 앱 시작 시 로그인 상태와 자동 로그인 설정을 확인
  }

  // 로그인 상태 및 자동 로그인 설정 확인
  Future<void> _checkAutoLogin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? autoLoginPref = prefs.getBool('autoLogin');
    User? user = _auth.currentUser;

    if (user != null) {
      if (autoLoginPref == true) {
        // 사용자가 자동 로그인을 선택했으면 성공 화면으로 바로 이동
        Navigator.pushReplacementNamed(context, '/success');
      } else {
        // 자동 로그인을 선택하지 않은 경우에는 강제 로그아웃 처리
        await _auth.signOut();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _idController.dispose();
    _pwController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      isLoading = true;
    });
    try {
      // 이메일/비밀번호로 로그인
      await _auth.signInWithEmailAndPassword(
        email: _idController.text.trim(),
        password: _pwController.text.trim(),
      );
      // 사용자가 선택한 자동 로그인 옵션을 저장
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('autoLogin', _autoLogin);

      // 로그인 성공 시 성공 화면으로 이동
      Navigator.pushReplacementNamed(context, '/success');
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? '로그인 실패')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('알 수 없는 오류 발생')),
      );
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      isLoading = true;
    });
    final provider = GoogleSignInProvider();
    UserCredential? userCredential = await provider.signInWithGoogle();
    if (userCredential != null) {
      // 사용자가 선택한 자동 로그인 옵션을 저장
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('autoLogin', _autoLogin);

      Navigator.pushReplacementNamed(context, '/success');
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('구글 로그인 취소됨')));
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return WillPopScope(
      // 뒤로가기 버튼 누를 시 동작하지 않음
      onWillPop: () async => false,
      child: Scaffold(
        body: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 상단 타이틀
                  const Text(
                    'Zero on top',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // 원형 로고
                  SizedBox(
                    width: size.width * 0.7,
                    height: size.width * 0.7,
                    child: Image.asset(
                      'assets/images/111.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 슬로건 문구
                  Text(
                    '가장 빠르게 최고를 위해 나아가라',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  // 이메일 입력 필드
                  TextField(
                    controller: _idController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.email),
                      labelText: '이메일',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 비밀번호 입력 필드
                  TextField(
                    controller: _pwController,
                    obscureText: true,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock),
                      labelText: '비밀번호',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 자동 로그인 체크박스
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _autoLogin,
                        onChanged: (bool? value) {
                          setState(() {
                            _autoLogin = value ?? false;
                          });
                        },
                      ),
                      const Text("자동 로그인")
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 로그인 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pinkAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                        '로그인',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 비밀번호 찾기 및 회원가입 버튼
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/passwordReset');
                    },
                    child: const Text('비밀번호를 잊으셨나요?'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/signup');
                    },
                    child: const Text('회원가입'),
                  ),
                  const SizedBox(height: 16),
                  // 소셜 로그인 버튼들
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed:
                            isLoading ? null : _handleGoogleSignIn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: const BorderSide(color: Colors.grey),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/icons/google_logo2.png',
                                  width: 24,
                                  height: 24,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  '로그인',
                                  style: TextStyle(
                                      color: Colors.black87, fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            // 애플 로그인: 추후 구현(현재는 구글 로그인 함수 사용)
                            onPressed:
                            isLoading ? null : _handleGoogleSignIn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: const BorderSide(color: Colors.grey),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/icons/apple_logo2.png',
                                  width: 24,
                                  height: 24,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  '로그인',
                                  style: TextStyle(
                                      color: Colors.black87, fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
