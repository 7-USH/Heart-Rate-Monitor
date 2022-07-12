// ignore_for_file: unnecessary_null_comparison, depend_on_referenced_packages
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as imglib;

// customer function to get color from live camera feed

 int getColorFromCamera({required CameraImage cameraImage}) {
  int width = cameraImage.width ~/ 2;
  int height = cameraImage.height ~/ 2;
  imglib.Image img;
  Color selectedColor = Colors.green;

  switch (cameraImage.format.group) {
    case ImageFormatGroup.unknown:
      img = _extractYUVColor(cameraImage);
      break;
    case ImageFormatGroup.yuv420:
      img = _extractYUVColor(cameraImage);
      break;
    case ImageFormatGroup.bgra8888:
      img = _extractBRRAColor(cameraImage);
      break;
    case ImageFormatGroup.jpeg:
      img = _extractBRRAColor(cameraImage);
      break;
  }

  if (img != null) {
    imglib.Image cropImage = imglib.copyCrop(img, width, height, 2, 2);
    img = imglib.bakeOrientation(cropImage);
    int coloredPixel = img.getPixelSafe(0, 0);
    int hex = _abgrToArgb(coloredPixel);
    selectedColor = Color(hex);
  } else {
    selectedColor = Colors.green;
  }

  return imglib.getRed(selectedColor.value);
}

int _abgrToArgb(int argbColor) {
  int r = (argbColor >> 16) & 0xFF;
  int b = argbColor & 0xFF;
  return (argbColor & 0xFF00FF00) | (b << 16) | r;
}

imglib.Image _extractYUVColor(CameraImage image) {
  int width = image.width;
  int height = image.height;
  var img = imglib.Image(width, height);
  const int hexFF = 0xFF000000;
  final int uvyButtonStride = image.planes[1].bytesPerRow;
  final int? uvPixelStride = image.planes[1].bytesPerPixel;
  for (int x = 0; x < width; x++) {
    for (int y = 0; y < height; y++) {
      final int uvIndex =
          uvPixelStride! * (x / 2).floor() + uvyButtonStride * (y / 2).floor();
      final int index = y * width + x;
      final yp = image.planes[0].bytes[index];
      final up = image.planes[1].bytes[uvIndex];
      final vp = image.planes[2].bytes[uvIndex];

      int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
      int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91)
          .round()
          .clamp(0, 255);
      int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);
      img.data[index] = hexFF | (b << 16) | (g << 8) | r;
    }
  }

  return img;
}

imglib.Image _extractBRRAColor(CameraImage cameraImage) {
  return imglib.Image.fromBytes(
    cameraImage.width,
    cameraImage.height,
    cameraImage.planes[0].bytes,
    format: imglib.Format.bgra,
  );
}
