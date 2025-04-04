import 'package:flutter/material.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:safehome/App/Screen/AddUser.dart';
import 'package:safehome/App/Screen/Home.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SafeHome extends StatelessWidget {
  const SafeHome({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeHome',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      routes: {
        'Home': (context) => Home(),
        'AddUser': (context) => AddUser(),
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
