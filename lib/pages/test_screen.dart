// ignore_for_file: must_be_immutable, depend_on_referenced_packages, prefer_const_constructors

import 'package:breathing_collection/breathing_collection.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:heart_rate_app/constants/constants.dart';
import 'package:heart_rate_app/pages/background.dart';
import 'package:camera/camera.dart';
import 'package:heart_rate_app/pages/main_screen.dart';

class TestScreen extends StatefulWidget {
  TestScreen({Key? key, required this.cameras}) : super(key: key);
  List<CameraDescription> cameras;

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldColor,
      body: CustomPaint(
        painter: BacgroundPaint(),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              BreathingGlowingButton(
                height: 100,
                width: 100,
                buttonBackgroundColor: heartColor,
                glowColor: waveColor,
                icon: FontAwesomeIcons.heartPulse,
                onTap: () {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) {
                    return MainScreen(
                      cameras: widget.cameras,
                    );
                  }));
                },
              ),
              const SizedBox(
                height: 30,
              ),
              Text(
                "Start test",
                style: appText(
                    isShadow: true,
                    color: Colors.white,
                    weight: FontWeight.w500,
                    size: 23),
              )
            ],
          ),
        ),
      ),
    );
  }
}
