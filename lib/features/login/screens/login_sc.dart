import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/google_sign_sc.dart';
import 'package:lottie/lottie.dart';
import 'package:swim/common/widgets/animated_loading.dart';

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
  bool _autoLogin = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAutoLogin();
  }

  Future<void> _checkAutoLogin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? autoLoginPref = prefs.getBool('autoLogin');
    User? user = _auth.currentUser;

    if (user != null) {
      if (autoLoginPref == true) {
        Navigator.pushReplacementNamed(context, '/success');
      } else {
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
    setState(() => isLoading = true);
    try {
      await _auth.signInWithEmailAndPassword(
        email: _idController.text.trim(),
        password: _pwController.text.trim(),
      );
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('autoLogin', _autoLogin);
      Navigator.pushReplacementNamed(context, '/success');
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? '로그인 실패')),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('알 수 없는 오류 발생')),
      );
    }
    setState(() => isLoading = false);
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => isLoading = true);
    final provider = GoogleSignInProvider();
    UserCredential? userCredential = await provider.signInWithGoogle();
    if (userCredential != null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('autoLogin', _autoLogin);
      Navigator.pushReplacementNamed(context, '/success');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('구글 로그인 취소됨')),
      );
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: isLoading
            ? const AnimatedLoading()
            : SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
            child: Column(
              children: [
                Image.asset('assets/images/S.png', height: 80),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.shade100,
                        blurRadius: 10,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _idController,
                        decoration: InputDecoration(
                          hintText: '이메일',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _pwController,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: '비밀번호',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        ),
                      ),
                      Row(
                        children: [
                          Checkbox(
                            value: _autoLogin,
                            onChanged: (val) => setState(() => _autoLogin = val ?? false),
                          ),
                          const Text('자동 로그인')
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.blue.shade700,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: _login,
                          child: const Text('로그인', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.g_mobiledata),
                          label: const Text('구글 로그인'),
                          onPressed: _handleGoogleSignIn,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/signup'),
                  child: Text('회원가입', style: TextStyle(color: Colors.blue.shade600, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
