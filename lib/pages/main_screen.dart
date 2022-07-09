// ignore_for_file: prefer_const_constructors, import_of_legacy_library_into_null_safe, unused_import, depend_on_referenced_packages, must_be_immutable, avoid_print

import 'dart:convert';

import 'package:breathing_collection/breathing_collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sinusoidals/flutter_sinusoidals.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:heart_rate_app/constants/constants.dart';
import 'package:heart_rate_app/models/bpm.dart';
import 'package:heart_rate_app/networking/firebase_api.dart';
import 'package:heart_rate_app/networking/heart_rate_api.dart';
import 'package:heart_rate_app/pages/background.dart';
import 'package:camera/camera.dart';
import 'dart:io' as io;

class MainScreen extends StatefulWidget {
  MainScreen({Key? key, required this.cameras}) : super(key: key);
  List<CameraDescription> cameras;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  bool isprocessing = false;
  late CameraController cameraController;
  late Bpm bpm;
  XFile? videoFile;
  late final AnimationController _controller = AnimationController(
    duration: const Duration(seconds: 2),
    vsync: this,
  );
  late final Animation<double> _animation =
      Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
    parent: _controller,
    curve: Curves.easeIn,
  ));

  @override
  void initState() {
    cameraController =
        CameraController(widget.cameras[0], ResolutionPreset.high);
    cameraController.initialize().then((value) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
    startRecordingandParsing();
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    cameraController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void startRecordingandParsing() async {
    Future.delayed(Duration(seconds: 5)).then((value) async {
      await cameraController.startVideoRecording();
      cameraController.setFlashMode(FlashMode.torch);
      Future.delayed(Duration(seconds: 16)).then((x) async {
        videoFile = await cameraController.stopVideoRecording();
        print("stop");
        await cameraController.setFlashMode(FlashMode.off);
        final file = io.File(videoFile!.path);
        const String filename = "test.mp4";
        String dst = 'files/$filename';
        var task = FirebaseApi.uploadFile(dst, file);
        if (task == null) return;
        final snapShot = await task.whenComplete(() => {});
        final url = await snapShot.ref.getDownloadURL();
        print(url);
        var result = await HeartRateApi.getData(imageurl: "$url.mp4");
        Map<String,dynamic> valueMap = await jsonDecode(result);
        bpm = Bpm.fromJson(valueMap);
        print(bpm.avg_bpm);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    _controller.forward();

    return Scaffold(
      backgroundColor: scaffoldColor,
      bottomNavigationBar: FadeTransition(
        opacity: _animation,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.1,
          decoration: BoxDecoration(
              color: waveColor,
              gradient: LinearGradient(
                  end: Alignment.topCenter,
                  begin: Alignment.bottomCenter,
                  colors: [
                    scaffoldColor,
                    lightWaveColor.withOpacity(0.499),
                  ])),
          child: Theme(
            data: ThemeData(splashColor: Colors.transparent),
            child: BottomNavigationBar(
                backgroundColor: Colors.transparent,
                elevation: 0.0,
                iconSize: 26,
                fixedColor: heartColor,
                currentIndex: _selectedIndex,
                unselectedItemColor: Colors.black,
                onTap: _onItemTapped,
                items: const [
                  BottomNavigationBarItem(
                      icon: Icon(FontAwesomeIcons.heartPulse),
                      label: "Measure"),
                  BottomNavigationBarItem(
                      icon: Icon(Icons.bar_chart_outlined), label: "stats"),
                ]),
          ),
        ),
      ),
      body: CustomPaint(
        painter: BacgroundPaint(),
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return FadeTransition(
              opacity: _animation,
              child: Transform(
                transform: Matrix4.translationValues(
                    0.0, 10 * (1.0 - _animation.value), 0.0),
                child: Center(
                  child: Column(
                    children: [
                      Spacer(),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.1,
                          child: Stack(alignment: Alignment.center, children: [
                            DemoCircleWave(
                              count: 200,
                              isProcessing: false,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  "120",
                                  style: appText(
                                      color: Colors.white,
                                      isShadow: true,
                                      size: 40,
                                      weight: FontWeight.w600),
                                ),
                                Text(
                                  "BPM",
                                  style: appText(
                                      color: waveColor,
                                      isShadow: true,
                                      weight: FontWeight.w600),
                                )
                              ],
                            )
                          ])),
                      Spacer(),
                      SizedBox(
                        height: 70,
                        width: 60,
                        child: ClipOval(
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: CameraPreview(cameraController,
                                child: Center(
                                  child: Icon(
                                    Icons.fingerprint_outlined,
                                    color: heartColor,
                                    size: 60,
                                  ),
                                )),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: RotatedBox(
                          quarterTurns: 2,
                          child: CombinedWave(
                            reverse: true,
                            models: const [
                              SinusoidalModel(
                                formular: WaveFormular.standing,
                                amplitude: 25,
                                waves: 20,
                                translate: 2.5,
                                frequency: 0.5,
                              ),
                              SinusoidalModel(
                                amplitude: 20,
                                waves: 15,
                                translate: 7.5,
                                frequency: 1.5,
                              ),
                              SinusoidalModel(
                                formular: WaveFormular.standing,
                                amplitude: 25,
                                waves: 4,
                                translate: 7.5,
                                frequency: 1.5,
                              ),
                            ],
                            child: Center(
                              child: Container(
                                width: MediaQuery.of(context).size.width,
                                height:
                                    MediaQuery.of(context).size.height * 0.27,
                                decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                        end: Alignment.topCenter,
                                        begin: Alignment.bottomCenter,
                                        colors: [
                                      heartColor,
                                      lightWaveColor.withOpacity(0.5)
                                    ])),
                                child: Align(
                                  alignment: Alignment.topCenter,
                                  child: RotatedBox(
                                    quarterTurns: 2,
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 20),
                                      child: Text(
                                        instructions,
                                        style: appText(
                                            color: Colors.white,
                                            weight: FontWeight.w500,
                                            isShadow: true),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
