import 'dart:async';
import 'package:flutter/material.dart';
import 'main.dart';
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // duração da splash
    Timer(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()), // agora funciona
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF3bb8de), // azul
              Color(0xFF9056de), // roxo
            ],
          ),
        ),
        child: Center(
          child: Image.asset(
            'assets/logo.png',
            width: 160,
          ),
        ),
      ),
    );
  }
}