// ignore_for_file: unused_local_variable, avoid_print, unused_element, unused_import, depend_on_referenced_packages, must_be_immutable, sized_box_for_whitespace
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:heart_rate_app/networking/firebase_api.dart';
import 'package:heart_rate_app/networking/heart_rate_api.dart';
import 'dart:io' as io;
import 'package:path_provider/path_provider.dart';
import 'package:camera/camera.dart';

class HomePage extends StatefulWidget {
  HomePage({Key? key, required this.cameras}) : super(key: key);
  List<CameraDescription> cameras;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<CameraDescription> cameras = [];
  late CameraController controller;

  Future<io.File> videoToFile({required String assetVideo}) async {
    var bytes = await rootBundle.load(assetVideo);
    String tempPath = (await getTemporaryDirectory()).path;
    io.File file = io.File('$tempPath/test.mp4');
    await file.writeAsBytes(
        bytes.buffer.asInt8List(bytes.offsetInBytes, bytes.lengthInBytes));
    return file;
  }

  Color widgetColor = Colors.black;
  XFile? videoFile;

  @override
  void initState() {
    super.initState();
    controller = CameraController(widget.cameras[0], ResolutionPreset.high);
    controller.initialize().then((value) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return Container();
    }
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: 70,
            width: 60,
            child: ClipOval(
              child: AspectRatio(
                aspectRatio: 1,
                child: CameraPreview(controller,
                    child: const Center(
                      child: Icon(
                        Icons.fingerprint_rounded,
                        color: Colors.white,
                        size: 60,
                      ),
                    )),
              ),
            ),
          ),
          ElevatedButton(
              onPressed: ()  async {
                await controller.startVideoRecording();
                controller.setFlashMode(FlashMode.torch);
              },
              child: const Text("Start Recording")),
          ElevatedButton(
              onPressed: () async {
                videoFile = await controller.stopVideoRecording();
                await controller.setFlashMode(FlashMode.off);
                final file = io.File(videoFile!.path);
                // var file = await videoToFile(assetVideo: "assets/ppgdata.mp4");
                const String filename = "test.mp4";
                String dst = 'files/$filename';
                var task = FirebaseApi.uploadFile(dst, file);
                if (task == null) return;
                final snapShot = await task.whenComplete(() => {});
                final url = await snapShot.ref.getDownloadURL();
                print(url);
                var result = await HeartRateApi.getData(imageurl: "$url.mp4");
                print(result);
              },
              child: const Text("Stop Recording")),
          
        ],
      ),
    );
  }
}
