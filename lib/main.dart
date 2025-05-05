import 'package:flutter/material.dart';
import 'common/navigation/bottom_nav_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:swim/login/login_sc.dart';
import 'package:swim/login/signgup_sc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'login/profile_sc.dart';
import 'login/search.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBxnDSHtvKVjoPpzeJJ8JfCVF_Ofy4CsPs",
      appId: "1:54469841565:android:6b8f5caf504693e0a6fa74",
      messagingSenderId: "54469841565",
      projectId: "swim-ddaad",
      storageBucket: "swim-ddaad.firebasestorage.app",
    ),
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
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/success': (context) => const BottomNavScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/search': (context) => const PasswordResetScreen(),
      },
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
      home: const BottomNavScreen(),
    );
  }
}
