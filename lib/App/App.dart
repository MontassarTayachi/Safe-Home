import 'package:flutter/material.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:safehome/App/Screen/AddUser.dart';
import 'package:safehome/App/Screen/Home.dart';
import 'package:safehome/App/Screen/Settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SafeHome extends StatelessWidget {
  const SafeHome({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeHome',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF19717B),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF19717B),
          primary: const Color(0xFF19717B),
          secondary: const Color(0xFF37A8B9),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF19717B),
          elevation: 0,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF19717B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF19717B), width: 2),
          ),
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      routes: {
        'Home': (context) => Home(),
        'AddUser': (context) => AddUser(),
        'Settings': (context) => Settings(),
      },
      home: const Splashscreen(),
    );
  }
}

class Splashscreen extends StatefulWidget {
  const Splashscreen({super.key});

  @override
  State<Splashscreen> createState() => _SplashscreenState();
}

class _SplashscreenState extends State<Splashscreen> {
  Widget _nextScreen = AddUser(); // Valeur par défaut

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isConnected = prefs.getBool('isConnected') ?? false;

    setState(() {
      _nextScreen = isConnected ? Home() : AddUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSplashScreen(
      nextScreen: _nextScreen,
      splash: Column(
        children: [
          Image.asset(
            'images/logo.png',
            width: 200,
            height: 200,
          ),
        ],
      ),
      backgroundColor: const Color(0xFF19717B),
      duration: 4000,
      splashIconSize: 250,
      splashTransition: SplashTransition.slideTransition,
    );
  }
}
