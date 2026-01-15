import 'package:flutter/material.dart';
import 'package:trippo_mobile_app/assistants/assistant_methods.dart';
import 'package:trippo_mobile_app/global/global.dart';
import 'package:trippo_mobile_app/screens/login_page.dart';
import 'dart:async';

import 'package:trippo_mobile_app/screens/main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  void startTimer(){
    Timer(const Duration(seconds:3), () {
      if(firebaseAuth.currentUser != null){
        firebaseAuth.currentUser != null ? AssistantMethods.readCurrentOnlineUserInfo(): null;
        Navigator.push(context,MaterialPageRoute(builder: (c) => MainScreen()),
    );
    } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (c) => LoginPage()),
        );
      }
    });
  }
  @override
  void initState(){
    super.initState();
    startTimer();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Trippo',style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 40,
        ),),
      ),
    );
  }
}
