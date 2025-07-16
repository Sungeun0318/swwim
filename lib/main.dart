import 'package:flutter/material.dart';
import 'common/navigation/bottom_nav_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:swim/features/login/screens/login_sc.dart';
import 'package:swim/features/login/screens/signgup_sc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // 새로운 firebase_options.dart 사용
import 'package:swim/features/login/screens/profile_sc.dart';
import 'package:swim/features/login/widgets/search.dart';
import 'package:swim/common/community/screens/community_screen.dart';
import 'package:swim/features/home/screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화 - 플랫폼별 설정 사용
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('ko', '');

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Swim Training',
      debugShowCheckedModeBanner: false,
      locale: _locale,
      theme: ThemeData(
        fontFamily: 'MyCustomFont',
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 16),
          bodyMedium: TextStyle(fontSize: 14),
        ),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko', ''),
        Locale('en', ''),
        Locale('es', ''),
        Locale('zh', ''),
      ],

      // 로그인 → 메인(BottomNavScreen) 흐름을 named routes로만 관리
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/success': (context) => const BottomNavScreen(),
        '/home': (context) => const HomeScreen(),
        '/community': (context) => const CommunityScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/passwordReset': (context) => const PasswordResetScreen(),
      },
    );
  }
}
