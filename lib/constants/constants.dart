import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const scaffoldColor = Color(0xff00171D);
const waveColor = Color(0xff11BFEB);
const lightWaveColor = Color(0xff007797);
const heartColor = Color(0xffFF4B4B);
const greenHighlight = Color(0xff26DF29);

const instructions = "Place your index finger tightly on camera.";
const processText = "Analyzing...";
const warning = "Warning: finger not placed correctly";

TextStyle appText(
    {required Color color,
    double? size,
    required FontWeight weight,
    bool isShadow = false}) {
  return GoogleFonts.poppins(
    color: color,
    fontSize: size,
    fontWeight: weight,
    shadows: isShadow
        ? [
            BoxShadow(
                color: Colors.black.withOpacity(0.2),
                offset: const Offset(0.6, 4),
                spreadRadius: 1,
                blurRadius: 8)
          ]
        : [],
  );
}
