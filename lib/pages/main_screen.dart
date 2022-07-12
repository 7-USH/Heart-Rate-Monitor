// ignore_for_file: prefer_const_constructors, import_of_legacy_library_into_null_safe, unused_import, depend_on_referenced_packages, must_be_immutable, avoid_print, unused_local_variable, unused_field, avoid_unnecessary_containers
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:breathing_collection/breathing_collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sinusoidals/flutter_sinusoidals.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:heart_rate_app/constants/constants.dart';
import 'package:heart_rate_app/models/bpm.dart';
import 'package:heart_rate_app/models/line_titles.dart';
import 'package:heart_rate_app/networking/firebase_api.dart';
import 'package:heart_rate_app/networking/heart_rate_api.dart';
import 'package:heart_rate_app/pages/background.dart';
import 'package:camera/camera.dart';
import 'package:heart_rate_app/pages/test_screen.dart';
import 'package:heart_rate_app/utils/color_detector.dart';
import 'dart:io' as io;
import 'package:lottie/lottie.dart';

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
  late Timer _timer;
  int _start = 5;
  bool timesUp = false;
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
  bool isProcessing = true;
  double sec = 0;
  List<FlSpot> spots = [];
  bool recordComplete = false;
  String maxBpm = "";
  String minBpm = "";
  final ValueNotifier<bool> isFinger = ValueNotifier(true);

  void updateBool(int number) {
    print(number);
    if (number > 200) {
      isFinger.value = false;
    } else {
      isFinger.value = true;
    }
  }

  @override
  void initState() {
    cameraController =
        CameraController(widget.cameras[0], ResolutionPreset.high);
    cameraController.initialize().then((value) async {
      if (!mounted) {
        return;
      }
      setState(() {
        // imageProcessing();
      });
    });
    startTimer();
    startRecordingandParsing();
    super.initState();
  }

  void imageProcessing() async {
    await cameraController.startImageStream((image) {
      updateBool(getColorFromCamera(cameraImage: image));
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    cameraController.dispose();
    isFinger.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void maxabout3(double a, double b, double c) {
    if (a >= b && a >= c) {
      maxBpm = a.toStringAsFixed(0);
    }
    if (b >= a && b >= c) {
      maxBpm = b.toStringAsFixed(0);
    }

    if (c >= a && c >= b) {
      maxBpm = c.toStringAsFixed(0);
    }
  }

  void minabout3(double a, double b, double c) {
    minBpm = min(min(a, b), c).toStringAsFixed(0);
  }

  void startRecordingandParsing() async {
    Future.delayed(Duration(seconds: 5)).then((value) async {
      await cameraController.startVideoRecording();
      await cameraController.setFlashMode(FlashMode.torch);
      // imageProcessing();
      Future.delayed(Duration(seconds: 16)).then((x) async {
        videoFile = await cameraController.stopVideoRecording();
        // await cameraController.stopImageStream();
        print("stop");
        await cameraController.setFlashMode(FlashMode.off);
        setState(() {
          recordComplete = true;
        });
        final file = io.File(videoFile!.path);
        const String filename = "test.mp4";
        String dst = 'files/$filename';
        var task = FirebaseApi.uploadFile(dst, file);
        if (task == null) return;
        final snapShot = await task.whenComplete(() => {});
        final url = await snapShot.ref.getDownloadURL();
        print(url);
        var result = await HeartRateApi.getData(imageurl: "$url.mp4");
        print(result.toString());
        Map<String, dynamic> valueMap = await jsonDecode(result.toString());
        bpm = Bpm.fromJson(valueMap);
        print(bpm.r_avg);
        setState(() {
          isProcessing = false;
          cameraController.dispose();
          for (int i = 1; i < bpm.r_avg.length; i++) {
            double value = (bpm.r_avg[i] + bpm.b_avg[i] + bpm.g_avg[i]) / 3;
            spots.add(FlSpot(sec, value));
            sec = sec + 0.03;
          }
          maxabout3(bpm.b_bpm, bpm.r_bpm, bpm.g_bpm);
          minabout3(bpm.b_bpm, bpm.r_bpm, bpm.g_bpm);
        });
      });
    });
  }

  void startTimer() {
    const oneSec = Duration(seconds: 1);
    _timer = Timer.periodic(
      oneSec,
      (Timer timer) {
        if (_start == 0) {
          setState(() {
            timer.cancel();
            timesUp = true;
            print(timesUp);
          });
        } else {
          setState(() {
            print(_start);
            _start--;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    _controller.forward();
    List<Widget> pages = [measurePage(), statsPage()];

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
                  child: pages[_selectedIndex]),
            );
          },
        ),
      ),
    );
  }

  Widget statsPage() {
    return !isProcessing
        ? Column(
            children: [
              Card(
                margin: EdgeInsets.only(top: 50, left: 10, right: 10),
                elevation: 4.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2),
                ),
                color: scaffoldColor,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: LineChart(LineChartData(
                        minX: 0,
                        maxX: 8,
                        minY: 0,
                        maxY: 6,
                        axisTitleData: FlAxisTitleData(
                            show: true,
                            rightTitle: AxisTitle(
                              showTitle: true,
                              reservedSize: 22,
                              titleText: "",
                              textStyle: appText(
                                  color: heartColor, weight: FontWeight.w500),
                            ),
                            bottomTitle: AxisTitle(
                              showTitle: true,
                              reservedSize: 8,
                              titleText: "Time",
                              textStyle: appText(
                                  color: heartColor, weight: FontWeight.w500),
                            ),
                            leftTitle: AxisTitle(
                              showTitle: true,
                              reservedSize: 8,
                              titleText: "BPM",
                              textStyle: appText(
                                  color: heartColor, weight: FontWeight.w500),
                            )),
                        titlesData: LineTitles.getTitleData(),
                        borderData: FlBorderData(
                            show: true,
                            border: Border.all(color: Colors.transparent)),
                        gridData: FlGridData(
                            show: true,
                            getDrawingHorizontalLine: ((value) {
                              return FlLine(
                                  color: Colors.transparent, strokeWidth: 1);
                            }),
                            drawHorizontalLine: true,
                            drawVerticalLine: true,
                            getDrawingVerticalLine: ((value) {
                              return FlLine(
                                  color: Colors.transparent, strokeWidth: 1);
                            })),
                        lineBarsData: [
                          LineChartBarData(
                              isCurved: true,
                              colors: [
                                heartColor,
                                heartColor.withOpacity(0.6),
                              ],
                              barWidth: 3,
                              dotData: FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                colors: [
                                  waveColor.withOpacity(1),
                                  waveColor.withOpacity(0.2),
                                ],
                              ),
                              spots: spots)
                        ])),
                  ),
                ),
              ),
              Expanded(
                  child: Card(
                      margin: EdgeInsets.only(
                          left: 10, right: 10, top: 25, bottom: 20),
                      elevation: 4.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(2),
                      ),
                      color: scaffoldColor,
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 30, vertical: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                          text: bpm.avg_bpm.toStringAsFixed(0),
                                          style: appText(
                                              size: 23,
                                              color: heartColor,
                                              weight: FontWeight.w500)),
                                      TextSpan(
                                        text: ' BPM',
                                        style: appText(
                                            color: waveColor,
                                            weight: FontWeight.w500),
                                      ),
                                      TextSpan(
                                          text: '\nAVERAGE',
                                          style: appText(
                                              size: 30,
                                              color: waveColor,
                                              weight: FontWeight.w500)),
                                    ],
                                  ),
                                  textAlign: TextAlign.start,
                                ),
                                Spacer(),
                                LottieBuilder.asset(
                                  "assets/heart_rate.json",
                                  height:
                                      MediaQuery.of(context).size.height * 0.15,
                                )
                              ],
                            ),
                          ),
                          Divider(
                            height: 1,
                            color: Colors.white.withOpacity(0.3),
                            endIndent: 20,
                            indent: 20,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 60,
                              right: 60,
                              top: 30,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                          text: maxBpm,
                                          style: appText(
                                              size: 23,
                                              color: heartColor,
                                              weight: FontWeight.w500)),
                                      TextSpan(
                                        text: ' BPM',
                                        style: appText(
                                            color: waveColor,
                                            weight: FontWeight.w500),
                                      ),
                                      TextSpan(
                                          text: '\nMAX',
                                          style: appText(
                                              size: 30,
                                              color: waveColor,
                                              weight: FontWeight.w500)),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                Spacer(),
                                Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                          text: minBpm,
                                          style: appText(
                                              size: 23,
                                              color: heartColor,
                                              weight: FontWeight.w500)),
                                      TextSpan(
                                        text: ' BPM',
                                        style: appText(
                                            color: waveColor,
                                            weight: FontWeight.w500),
                                      ),
                                      TextSpan(
                                          text: '\nMIN',
                                          style: appText(
                                              size: 30,
                                              color: waveColor,
                                              weight: FontWeight.w500)),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        ],
                      )))
            ],
          )
        : Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.only(left: 50.0, right: 50, bottom: 20),
                  child: LottieBuilder.asset("assets/nodata.json"),
                ),
                Text(
                  "There is no data to show you \nright now",
                  textAlign: TextAlign.center,
                  style: appText(
                      color: Colors.white,
                      isShadow: true,
                      weight: FontWeight.w600,
                      size: 20),
                ),
              ],
            ),
          );
  }

  Widget measurePage() {
    return Center(
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
                !isProcessing
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            bpm.avg_bpm.toStringAsFixed(0),
                            style: appText(
                                color: Colors.white,
                                isShadow: true,
                                size: isProcessing ? 20 : 40,
                                weight: FontWeight.w600),
                          ),
                          Text(
                            isProcessing ? "" : "BPM",
                            style: appText(
                                color: waveColor,
                                isShadow: true,
                                weight: FontWeight.w600),
                          )
                        ],
                      )
                    : Transform.rotate(
                        angle: -0.3,
                        child: LottieBuilder.asset(
                          "assets/heart_bubble.json",
                        )),
              ])),
          Spacer(),
          isProcessing
              ? SizedBox(
                  height: 70,
                  width: 60,
                  child: ClipOval(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: CameraPreview(cameraController,
                          child: Container(
                            color: recordComplete
                                ? Colors.white
                                : Colors.transparent,
                            child: Center(
                              child: Icon(
                                Icons.fingerprint_outlined,
                                color: heartColor,
                                size: 60,
                              ),
                            ),
                          )),
                    ),
                  ),
                )
              : TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(context,
                        MaterialPageRoute(builder: (_) {
                      return TestScreen(cameras: widget.cameras);
                    }));
                  },
                  child: Text(
                    "Take test again?",
                    style: appText(
                        color: Colors.white,
                        isShadow: true,
                        size: 20,
                        weight: FontWeight.w600),
                  )),
          SizedBox(
            height: 10,
          ),
          isProcessing
              ? Center(
                  child: Text(
                    timesUp ? processText : "Test starts in $_start",
                    style: appText(
                        color: Colors.white,
                        isShadow: true,
                        size: 14,
                        weight: FontWeight.w600),
                  ),
                )
              : Container(),
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: CombinedWave(
              reverse: false,
              models: const [
                SinusoidalModel(
                  formular: WaveFormular.travelling,
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
                  amplitude: 25,
                  waves: 4,
                  translate: 7.5,
                  frequency: 1.5,
                ),
              ],
              child: Center(
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height * 0.27,
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                        heartColor,
                        lightWaveColor.withOpacity(0.5)
                      ])),
                  child: isProcessing
                      ? Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: ValueListenableBuilder<bool>(
                                valueListenable: isFinger,
                                builder: ((context, value, child) => Text(
                                      value ? instructions : warning,
                                      style: appText(
                                          color: value
                                              ? Colors.white
                                              : Colors.yellowAccent,
                                          weight: value
                                              ? FontWeight.w500
                                              : FontWeight.w600,
                                          isShadow: true),
                                    ))),
                          ),
                        )
                      : Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                          text: maxBpm,
                                          style: appText(
                                              size: 23,
                                              color: heartColor,
                                              weight: FontWeight.w500)),
                                      TextSpan(
                                        text: ' BPM',
                                        style: appText(
                                            color: waveColor,
                                            weight: FontWeight.w500),
                                      ),
                                      TextSpan(
                                          text: '\nMAX',
                                          style: appText(
                                              color: Colors.white,
                                              weight: FontWeight.w500)),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                          text: minBpm,
                                          style: appText(
                                              size: 23,
                                              color: heartColor,
                                              weight: FontWeight.w500)),
                                      TextSpan(
                                        text: ' BPM',
                                        style: appText(
                                            color: waveColor,
                                            weight: FontWeight.w500),
                                      ),
                                      TextSpan(
                                          text: '\nMIN',
                                          style: appText(
                                              color: Colors.white,
                                              weight: FontWeight.w500)),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
